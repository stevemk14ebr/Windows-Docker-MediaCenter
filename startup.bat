cd openvpn
docker-compose up -d vpn
timeout /t 10 /nobreak > nul

cd ../jackett
docker-compose up -d jackett 

cd ../transmission
docker-compose up -d transmission
timeout /t 10 /nobreak > nul

cd ../sonarr
docker-compose up -d sonarr
cd ../radarr
docker-compose up -d radarr

cd ../heimdall
docker-compose up -d heimdall

cd ../ombi
docker-compose up -d ombi

cd ../guacamole
docker-compose up -d guacamole

cd /D PATH TO NGROK
start /B ngrok.exe start -config=PATH TO NGROK CONFIG --all

cd /D PATH TO NGROK_ROUTER
start /B npm run serve