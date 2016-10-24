# Using Docker
## Step by step

On Ubuntu, with Git installed and no Docker installed:
```bash
# clone DryFHIR repository
git clone https://github.com/DryFHIR/dryfhir.git
cd dryfhir

# Docker setup - add Dockers key
sudo apt-key adv --keyserver hkp://p80.pool.sks-keyservers.net:80 --recv-keys 58118E89F3A912897C070ADBF76221572C52609D

# add Docker Ubuntu repository
sudo sh -c "echo deb https://apt.dockerproject.org/repo ubuntu-xenial main > /etc/apt/sources.list.d/docker.list"
sudo apt-get update

sudo apt-get install docker-engine linux-image-extra-$(uname -r) linux-image-extra-virtual

# add your user to the Docker group, so you don't need sudo to run docker commands
sudo service docker start
sudo groupadd docker
sudo usermod -aG docker $USER

# log out and log back in, to ensure your user account has new permissions
cd dryfhir

# wait for this to complete as it does the database setup and all
docker-compose up

# CTRL+C after the first-time setup completes

# now run it for real
docker-compose up
```

## Docker setup explanation
For development, the `docker-compose up` command starts the database server and the web server within the same network and linked, so that they can access each other. The `docker-compose.yml` and `docker-compose.orverride.yml` are used automatically. The web server will be reachable at `localhost:8080` and it will have the current directory mounted `/opt/dryfhir`, overriding the original content (the stable, released version). That way, code changes are immediately reflected on the server.

For production, you can use docker-compose as well with `docker-compose -f docker-compose.yml -f docker-compose.prod.yml up`. This will ignore the override file and use the production file instead, where `/opt/dryfhir` is not overwritten and the published port is 80 (which you may change editing the prod file).

The last interesting bit is, that docker-compose can be used to create a definition of a release of multiple connected docker-images. By using `docker.compose -f docker-compose.yml -f docker-compose.prod.yml bundle`, a json file is generated, which contains the exact versions of both images at the time (you want to use docker-compose pull first). With that file, you can use `docker deploy` and be up and running without installing docker.compose on the prod machine.

The Dockerfile builds an image with all dependencies and the dryFHIR code at /opt/dryfhir and is set to start the lapis server with the `dockerdev` environment by default. You can use other environments (like `dockerprod`) with `docker run <options> server <environment>`.

For the ease of starting the docker machines in a usual state, there are two docker-compose setups available, one for development (the default) and one for production.


# Natively
Use the following instructions to get DryFHIR setup and running natively on your Linux machine (these instructions have been tested on 16.04 LTS).

```bash
# install postgresql and the plv8 extension
sudo apt-get install postgresql-9.5-plv8

# edit according to https://github.com/leafo/pgmoon/issues/19
sudo nano /etc/postgresql/9.5/main/pg_hba.conf

# enable plv8, see https://github.com/fhirbase/fhirbase-plv8
echo "plv8.start_proc='plv8_init'" | sudo tee --append /etc/postgresql/9.5/main/postgresql.conf

# apply changes
sudo service postgresql restart

# create a default user and database for the user
sudo -u postgres createuser -s $(whoami); createdb $(whoami)

# create a database named fhirbase (for normal use) and fhirbase-test (for running busted tests)
createdb fhirbase && createdb fhirbase-test

# load up the fhirbase data into a database named fhirbase
# check if 1.4.0 is still latest fhirbase release before running this
wget https://github.com/fhirbase/fhirbase-plv8/releases/download/v1.4.0.0/fhirbase-1.4.0.0.sql.zip
unzip fhirbase-1.4.0.0.sql.zip
cat fhirbase-1.4.0.0.sql | psql fhirbase
cat fhirbase-1.4.0.0.sql | psql fhirbase-test
```
