#!/bin/bash

# This script will create a clean datastructure for the QGEP project based on
# the SIA 405 datamodel.
# It will create a new schema qgep in a postgres database.
#
# Environment variables:
#
#  * PGSERVICE
#      Specifies the postgres database to be used
#        Defaults to pg_qgep
#
#      Examples:
#        export PGSERVICE=pg_qgep
#        ./db_setup.sh

# Exit on error
set -e

SRID=2056

DIR=$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )/..

if [[ -z ${PGSERVICE} ]]; then
  PGSERVICE=pg_siro
fi


while getopts ":drfs:p:" opt; do
  case $opt in
    f)
      force=True
      ;;
    r)
      roles=True
      ;;
    d)
      demo_data=True
      ;;
    s)
      SRID=$OPTARG
      echo "-s was triggered, SRID: $SRID" >&2
      ;;
    p)
      PGSERVICE=$OPTARG
      echo "-p was triggered, PGSERVICE: $PGSERVICE" >&2
      ;;
    \?)
      echo "Invalid option: -$OPTARG" >&2
      ;;
    :)
      echo "Option -$OPTARG requires an argument." >&2
      exit 1
      ;;
  esac
done


if [[ $force == True ]]; then
  psql "service=${PGSERVICE}" -v ON_ERROR_STOP=1 -c "DROP SCHEMA IF EXISTS siro_od CASCADE";
  psql "service=${PGSERVICE}" -v ON_ERROR_STOP=1 -c "DROP SCHEMA IF EXISTS siro_vl CASCADE";
  psql "service=${PGSERVICE}" -v ON_ERROR_STOP=1 -c "DROP SCHEMA IF EXISTS siro_sys CASCADE";
fi
psql "service=${PGSERVICE}" -v ON_ERROR_STOP=1 -f ${DIR}/data_model/schema.sql

psql "service=${PGSERVICE}" -v ON_ERROR_STOP=1 -f ${DIR}/data_model/value_lists/durability.sql
psql "service=${PGSERVICE}" -v ON_ERROR_STOP=1 -f ${DIR}/data_model/value_lists/sign_type.sql
psql "service=${PGSERVICE}" -v ON_ERROR_STOP=1 -f ${DIR}/data_model/value_lists/frame_type.sql
psql "service=${PGSERVICE}" -v ON_ERROR_STOP=1 -f ${DIR}/data_model/value_lists/frame_fixing_type.sql
psql "service=${PGSERVICE}" -v ON_ERROR_STOP=1 -f ${DIR}/data_model/value_lists/support_type.sql
psql "service=${PGSERVICE}" -v ON_ERROR_STOP=1 -f ${DIR}/data_model/value_lists/support_base_type.sql
psql "service=${PGSERVICE}" -v ON_ERROR_STOP=1 -f ${DIR}/data_model/value_lists/status.sql
psql "service=${PGSERVICE}" -v ON_ERROR_STOP=1 -f ${DIR}/data_model/value_lists/lighting.sql
psql "service=${PGSERVICE}" -v ON_ERROR_STOP=1 -f ${DIR}/data_model/value_lists/coating.sql
psql "service=${PGSERVICE}" -v ON_ERROR_STOP=1 -f ${DIR}/data_model/value_lists/official_sign.sql

psql "service=${PGSERVICE}" -v ON_ERROR_STOP=1 -f ${DIR}/data_model/ordinary_data/owner.sql
psql "service=${PGSERVICE}" -v ON_ERROR_STOP=1 -f ${DIR}/data_model/ordinary_data/support.sql
psql "service=${PGSERVICE}" -v ON_ERROR_STOP=1 -f ${DIR}/data_model/ordinary_data/sign.sql
psql "service=${PGSERVICE}" -v ON_ERROR_STOP=1 -f ${DIR}/data_model/ordinary_data/frame.sql

if [[ $demo_data == True ]]; then
  echo "*** inserting demo_data"
  psql "service=${PGSERVICE}" -v ON_ERROR_STOP=1 -f ${DIR}/data_model/demo_data/demo_data.sql
fi
