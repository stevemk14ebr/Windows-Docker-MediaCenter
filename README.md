# Windows-Docker-MediaCenter
Linux based docker containers to provide remote access and serve media. With windows workarounds (will work on linux) (maybe on mac too but untested)

# TLDR;
If this is you then keep reading:

"I want to go to the public library and stream movies from my own server that is behind a super restrictive nat and also i want to be able to remote into it incase anything breaks. Oh also i dont like searching for media on sketchy sites so it should just find the best release to download for me, which must download over vpn of course. And i also can't run any of this on linux so it has to run on windows. And also the library computer doesn't let me install anything so it all has to just give me a web portal to the things. And if i want to give my friends access it'd be cool if they had a user portal to request new media."


# Containers
- Transmission: torrent downloads
- Sonarr: automated tv show acquisition
- Radarr: automated movie acquisition
- Jackett: torrent tracker -> rss feed indexer for radarr and sonarr to search
- openvpn: route all the above over your vpn of choice
- ombi: portal for users to request tv and movie shows
- heimdall: dev portal to keep track of ip:port services in a nice web ui
- apache guacamole: to provide remote access to the entire system

# Host applications
- plex: serves media acquired from containers
- ngrok: public routing to docker containers
- tiger vnc: gucamole vnc endpoint
- ngrok_router: a custom webserver i wrote to bypass ngrok restrictions
- sickbear_mp4_converter: convert acquired media to streamable mp4 (plex has encoding issues sometimes, runs manually for now)

# Architectural Overview
Docker on windows runs all containers inside of hyper-v container. This makes routing to services kind of weird, and a little hard. The typical way of accessing a docker container by using the ip you get from docker inspect doesn't work. Instead you must user the ip address of the hyper-v bridge adapter

![hyper-v](https://i.imgur.com/udHzIfm.png)

If the container is in HOST 'network_mode' use ip 10.0.75.2 to get acess TO a docker container, to get access to the host FROM a container use 10.0.75.1. If the container is in BRIDGE 'network_mode' access TO the container is through localhost, and access to the host FROM the container is through ip 10.0.75.1 OR localhost (depends on which interface host tool listens on). 

The openvpn container is setup in HOST 'network_mode' meaning it binds directly to the hyper-v network stack and listens to 10.0.75.2. All containers routed through the vpn connect via docker's ability to share container network stacks with 'network_mode: container:openvpn', when this happens the container essentially inherits the HOST network binding that the openvpn container setup and can talk to each other through the vm's localhost. Heimdall and guacamole are the only two containers not routed this way, and instead those two use BRIDGE networking just because they dont need to go over the vpn.

Since all the containers run inside the vpn container and are accessible via 10.0.75.2 exposing them to the public outside of the dev machine is hard. If we were an external client trying to connect to the host's ip nothing would resolve, since the connection would be to the wan interface rather than the hyper-v interface. To fix this i've used NGROK which acts a a middle man in the cloud that forwards packets/requests from the some local interface (10.0.75.2) to whoever is connecting. However ngrok limits the number of domains you have on the lowest paid tier so i wrote ngrok_router as a work around. This lets give me a mapping from docker container service -> randomly assigned ngrok domain.

And finally guacamole is used to give remote access to this whole system. Leaving you with a system that can automatically acquire new media over vpn, stream it publicly via plex, provide access to services via domain names, provide client portal for requests, and allow remote access to the entire machine. All of it works behind the most restrictive nat and everything is clientless running completely through the browser. 

# Setup
Clone all the docker-compose files. Each service is in its own folder with its own docker-compose.yml. Run the container with `docker-compose up serviceName` or `docker-compose up -d serviceName` to run without console output (use powershell). Go install plex, install tiger vnc, get my ngrok_router from my other repo, and buy the cheapest ngrok tier $5 and reserve two domain names. I also provided a root level docker-compose.yml that can be used to start all services from one config, and an associated start.sh, this configuration is intended to be used on linux while the service per folder is for windows.

## VPN
I use private internet access, their default configs are trash. Instead use mine which fixes frequent disconnects and auto-reconnects on wifi shutdown. I've based this on the TCP-Strong config provided here: https://www.privateinternetaccess.com/pages/client-support/ under "advanced openvpn ssl restrictive configurations". Fill in your information where appropriate, you will need to modify the vpn.cert_auth file to have your login on line 1 and password on line 2. Also provide your crl.pem. Start this container and make sure it can connect properly. If you are on a restrictive network and dns resolution is failing in the container check that your dns is set to what your host machine uses, some networks prevent using common 'alternative' dns servers like googles popular 8.8.8.8. 

## Sonarr
Launch the container. Go to the portal on 10.0.75.2:8989. Start configuring sonarr by going to the connect tab and adding plex. ![sonarr plex](https://i.imgur.com/dZjHsAR.png). Goto download client and add transmission ![sonarr transmission](https://i.imgur.com/oYsZC4L.png). Go to indexers and add some indexers from jackett, use the torznab type for jackett here is just one example: ![sonarr indexer](https://i.imgur.com/h6BD9YP.png).

## Radarr
Same as sonarr basically

## Jackett
Just launch it and add some indexers. Use 'copy torznab feed' to get sonarr and radarr links

## Heimdall
Add all the ip:port pairings from the docker-compose files. Access heimdall through localhost ![heimdall](https://i.imgur.com/lZWzNKD.jpg).

## Ombi
add plex media server using ip 10.0.75.1:32400. Google how to get your plex auth-token and machine identifier. Add sonarr under tv and radarr under movies with ip's 10.0.75.2. Configure user accounts as you like.

## Sickbeard_mp4_converter: https://github.com/mdhiggins/sickbeard_mp4_automator
Once you have enough media manually run the following:
```
Automated Directory (The script will attempt to figure out appropriate tagging based on file name)
manual.py -i directory_path -a
Example: manual.py -i C:\Movies -a
```

## Ngrok
Set one of your ngrok domains to plex and the other to my ngrok_router. Now launch ngrok_router and the ngrok.exe. Go to the domain name of my ngrok router to see the public facing domain names for all the containers and enjoy ![heimdall](https://i.imgur.com/W23WG8v.png). 

## Guacamole
Ctrl+alt+shift brings up menu if you can't see it at any point. login using default credentials. Add a new vnc connection to tiger vnc use 10.0.75.1 under hostname and port 5900 by default.
