#!/bin/bash

## Coastline CYBR 260 Docker Host Build Script
## This installs and (mostly) configures the services hosted on this box for the student environment
## Note that due to an unfixed bug, the MISP instance needs a new user manually created
## Ports are re-mapped to ensure that all services co-exist nicely on this system. All containers will come up after reboot of the host

## Downloading required packages
sudo apt update
sudo apt upgrade -y
sudo apt install -y ca-certificates curl git gnupg
sudo apt install -y docker docker-compose

## Setting up Build Folders
mkdir /CYBR260_Docker
cd /CYBR260_Docker

## Setting up Docker for MISP
git clone https://github.com/MISP/misp-docker
cd /CYBR260_Docker/misp-docker
cp /CYBR260_Docker/misp-docker/template.env /CYBR260_Docker/misp-docker/.env
sed -i 's/localhost/10.0.0.90/' /CYBR260_Docker/misp-docker/.env
sed -i 's/admin@admin.test/student@coastline.labs/' /CYBR260_Docker/misp-docker/.env
sed -i 's/MISP_ADMIN_PASSPHRASE=admin/MISP_ADMIN_PASSPHRASE=CYBR260/' /CYBR260_Docker/misp-docker/.env
## adding in sed for the compose file as for some reason, it does not read the .env for some items
sed -i 's/MISP_ADMIN_EMAIL=${MISP_ADMIN_EMAIL:-admin@admin.test}/MISP_ADMIN_EMAIL=${MISP_ADMIN_EMAIL:-student@coastline.labs}/' /CYBR260_Docker/misp-docker/docker-compose.yml
sed -i 's/MISP_ADMIN_PASSPHRASE=${MISP_ADMIN_PASSPHRASE:-admin}/MISP_ADMIN_PASSPHRASE=${MISP_ADMIN_PASSPHRASE:-CYBR260}/' /CYBR260_Docker/misp-docker/docker-compose.yml
sed -i 's/localhost/10.0.0.90/' /CYBR260_Docker/misp-docker/docker-compose.yml
sed -i 's/unless-stopped/always/' /CYBR260_Docker/misp-docker/docker-compose.yml
## For anyone reading this, the docker-compose ignores both the .env and itself when making the initial user.. As such, you still have to manually make a user
## There was a fix for this but it does not seem very fixed to me- I am leaving these here for posterity's sake in case it is fixed in the future
docker-compose build
docker-compose up -d

## Setting up Docker for DFIR-IRIS
cd /CYBR260_Docker
git clone https://github.com/dfir-iris/iris-web.git
cd /CYBR260_Docker/iris-web
git checkout v2.0.2
cp .env.model .env
sed -i 's/#IRIS_ADM_PASSWORD=MySuperAdminPassword!/IRIS_ADM_PASSWORD=CYBR260/' /CYBR260_Docker/iris-web/.env
sed -i 's/443/8443/' /CYBR260_Docker/iris-web/.env
sed '/^image: rabbitmq.*/a restart:always' /CYBR260_Docker/iris-web/docker-compose.yml
sed -i 's/on-failure:5/always/' /CYBR260_Docker/iris-web/docker-compose.yml
docker-compose build
docker-compose up -d

## Setting up Docker for Wazuh
cd /CYBR260_Docker
git clone https://github.com/wazuh/wazuh-docker.git -b v4.4.1
cd /CYBR260_Docker/wazuh-docker/single-node
sed -i 's/443:5601/5601:5601/' /CYBR260_Docker/wazuh-docker/single-node/docker-compose.yml
sed -i 's/SecretPassword/nat9ydc4mfh4HGR!dbu/' /CYBR260_Docker/wazuh-docker/single-node/docker-compose.yml
docker-compose -f generate-indexer-certs.yml run --rm generator
docker-compose up -d
