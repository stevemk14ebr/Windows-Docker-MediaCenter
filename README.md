# Windows-Docker-MediaCenter
Linux based docker containers to provide remote access and serve media. With windows workarounds.

# TLDR;
I want to go to the public library and stream movies from my own server that is behind a super restrictive nat and also i want to be able to remote into it incase anything breaks. Oh also i dont like searching for media on sketchy sites so it should just find the best release to download for me, which must download over vpn of course. And i also can't run any of this on linux so it has to run on windows. And also the library computer doesn't let me install anything so it all has to just give me a web portal to the things. And if i want to give my friends access it'd be cool if they had a user portal to request new media.

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

The openvpn container is setup in HOST 'network_mode' meaning it binds directly to the hyper-v network stack and listens to 10.0.75.2. All containers routed through the vpn connect via docker's ability to share container network stacks with 'network_mode: container:openvpn', when this happens the container essentially inherits the HOST network binding that the openvpn container setup. Heimdall and guacamole are the only two containers not routed this way, and instead those two use BRIDGE networking just because they dont need to go over the vpn.

Since all the containers run inside the vpn container and are accessible via 10.0.75.2 exposing them to the public outside of the dev machine is hard. If we were an external client trying to connect to the host's ip nothing would resolve, since the connection would be to the wan interface rather than the hyper-v interface. To fix this i've used NGROK which acts a a middle man in the cloud that forwards packets/requests from the some local interface (10.0.75.2) to whoever is connecting. However ngrok limits the number of domains you have on the lowest paid tier so i wrote ngrok_router as a work around. This lets give me a mapping from docker container service -> randomly assigned ngrok domain.

And finally guacamole is used to give remote access to this whole system. Leaving you with a system that can automatically acquire new media over vpn, stream it publicly via plex, provide access to services via domain names, provide client portal for requests, and allow remote access to the entire machine. All of it works behind the most restrictive nat and everything is clientless running completely through the browser. 
