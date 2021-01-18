# homelab-scripts

This repo contains the initial bootstrap script that i'm executing whenever my homelab server is installed from scratch.
It will detect the Operating System and install relying package that i'm considering as belonging to my survival kit 

Moreover, it will retreive if some followed github repo and some owned repo.

This script could run more than once on my installed server named 'orion'. after the execution of this script,
i will be able to switch to my [base ansible installation](https://github.com/G-Freart/homelab-server)


### Nota bene 

On my homelab server, i have a dedicated partition which is mounted under my home directory i.e. /home/gilfre/wksp
and which contains the part of my environment i wanna keep whenever i'm doing a full installation
