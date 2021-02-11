

## Environment setup

### Initial setup

1. Install Docker (for [Windows](https://docs.docker.com/docker-for-windows/install/))
2. Open the terminal (`cmd.exe`or powershell)
3. Run the container: `docker run -d -p 5432:5432 --name siro opengisch/siro:unstable`
4. The former command will run an empty model. You can install the demo data by running: `docker exec siro init_db.sh build -d`
5. You need to setup the Postgres service ([documentation](https://qgep.github.io/docs/en/installation-guide/workstation.html#windows-pg-service)) to connect to the database: 
```
[pg_siro]
dbname=siro
user=postgres
password=postgres
host=localhost
```
6. [Download the sources of the project](https://github.com/opengisch/signalisation_verticale/archive/master.zip)
7. Open the QGIS project (located in the sources, under project)

### Already using Postgres in your environment

If you already use an instance of Postgres, instead of `3.` of initial setup process, do the following. Otherwise, skip this chapter.

1. Choose any new port number (`xxxx`) instead of `5432`
2. Adapt pg_service.conf and pgpass files with new port number
3. Create a .pgconf folder containing pg_service.conf and pgpass files
4. Define a system environment variable with .pgconf folder path as the value. eg: PGSYSCONFDIR =  C:\apps\_dev\SIRO\.pgconf
5. Run the container using the new port number: `docker run -d -p xxxx:5432 --name siro opengisch/siro:unstable`

### Update datamodel

After any upstream change in the datamodel, run `docker pull opengisch/siro:unstable`.
If you have a running container, you can stop and remove it by doing `docker rm -f siro` (this would delete any data you had entered in QGIS).
You can start the container again with the run command above.

### Update project

After any upstream change in the QGIS project file, you need to redownload the project.

### Automatic start

To start SIRO virtual environement automatically with Docker, use: `docker update --restart always siro`
