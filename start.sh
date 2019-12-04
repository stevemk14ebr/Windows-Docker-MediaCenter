#!/bin/bash

./ngrok http -subdomain=remoteblah -inspect=false -bind-tls=true localendpoint > /dev/null &
docker-compose build
docker-compose up -d sonarr
docker-compose up -d radarr
