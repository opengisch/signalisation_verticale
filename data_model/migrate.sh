#!/bin/sh

# This initializes the migrations table (if needed), then compiles
# all deltas that need to be run in one big transaction, wrapping
# them all in the same transaction, so that all changes are rolled
# back in case of error.
# 
# It ensures that all migrations are run only once by creating an
# entry in the migration tables, which has the migration id as primary
# key.
#
# It also substitutes env vars in the script, allowing user
# customizations.

set -e

DELTASDIR="/datamodel/deltas/";
ENVSUBST_VARS=$(cat /datamodel/envsubst_variables)
export PGOPTIONS='--client-min-messages=warning'

function show {
  # Shows the current state of the migrations
  
  echo "---------------------";
  echo " $1";
  echo "---------------------";
  psql "$POSTGRES_URI" -c "SELECT migration, applied FROM migrations;"
}

function execute {
  # Wraps contents of file in a transaction block,
  # optionnaly add an entry in the migrations tables,
  # replaces the variables, then executes the file.

  # Determining the migrations ID
  id=${1#*$DELTASDIR}

  printf "> Processing $id... "
  
  # If this is a managed delta, we ensure it wasn't run already
  if [[ "$2" == 'yes' ]]
  then
    if [ $(psql "$POSTGRES_URI" -t -c "SELECT COUNT(*) FROM migrations WHERE migration = '$id'") = "1" ]; then
      echo 'skipping (already applied)'
      return 
    fi
  fi


  # Starting the transaction block
  echo "START TRANSACTION;" > /tmp/prepare.sql;

  # Adding the contents of the file
  cat $1 >> /tmp/prepare.sql;

  # If this is a managed delta, we store the id in the migration table
  if [[ "$2" == 'yes' ]]
  then
    echo "INSERT INTO migrations(\"migration\") VALUES ('$id');" >> /tmp/prepare.sql;
  fi

  # Closing the transaction block
  echo "COMMIT;" >> /tmp/prepare.sql;

  # Replacing the variables

  envsubst $ENVSUBST_VARS < /tmp/prepare.sql > /tmp/exec.sql;

  # Execute the query
  psql "$POSTGRES_URI" -v "ON_ERROR_STOP=1" -f /tmp/exec.sql 1> /dev/null;

  echo 'applied !'

}

execute '/infrastructure.sql';

show "INITIAL STATE";

execute /datamodel/pre_all.sql

for path in $(find $DELTASDIR -name '*.sql')
do
  execute $path 'yes'
done

execute /datamodel/post_all.sql

show "FINAL STATE";

pg_dump --schema-only "$POSTGRES_URI" > /datamodel/_dump.sql
