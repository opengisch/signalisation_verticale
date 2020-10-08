# Datamodel

This service holds the datamodel as a sequence of SQL migration
scripts and a very lightweight script to run the migrations.

## Usage

To evolve the datamodel/api, create new *.sql scripts representing
the changes. The ordering is important.

The 0000 migration is used to setup tables that keep track of already
applied migrations. Do not alter or remove it.

To apply the migrations, run the migration.sh script. It will take care
to only apply migrations that have not already been applied. It will
run every transaction in a transaction and stop on error.

Environment variables can be substituted and can be used in migrations
scripts using the `${variable}` syntax. To do so, you need to explicitely
list the variables to be substitued in the `datamodel/envsubst_variables` file. 

Important : Make sure to **NEVER** edit/rename a previously released
migration file, as it will very likely mess up the datamodel on each
deployement.


## Docker

The docker-compose setup takes care of everything, and runs the migrations on
startup against an included postgis server.

To configure the build, edit the `.env` file.

To run migrations :
```
# start
docker-compose up --build -d
# inspect
docker-compose logs -f datamodel
```

To start over (WILL DELETE ALL DATA !):
```
docker-compose down --volumes
```
