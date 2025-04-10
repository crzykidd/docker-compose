# docker-compose

This is my docker compose library.   I use [Komodo](https://github.com/moghtech/komodo) to manage everything.  

Each server has a unique machinename-utils docker compose.   This is all the base things for this machine and includes things like:

* traefik

Each other docker compose file is for certain stacks.  This should be set to so each stack can run on any docker host and everything should use unique domain names and if things move hosts a simple cname update is all you need to fix any api ties.
