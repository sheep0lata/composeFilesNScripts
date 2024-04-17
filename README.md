# composeFilesNScripts
A repo to stock my compose files and scripts I made during my free time. Those compose files worked for me and are fairly inspired by those you can already find online. However I had to change some volumes, networks or environment variables to make them work on my infrastructure.
I also created a lil bash script that asks the user what to install and then creates and executes the compose files in serparate directories. This script is just a temporary solution as I plan on creating an Ansible playbook to do these tasks instead.

Each compose has it's own directory in which you can find the README.md file that details the entirety of the file. If some informations are missing or are incorrect please contact me using the informations from the "Authors and contributors" section.

## What did I wanted to achieve with those compose files
I didn't really have any precise idea of what to do when I started this project, I just wanted to strengthen my skills with Docker containers. I then bought a domain name along with a tiny server to practice and deploy services that I could test using a classic Internet connection. The first few things that came to mind were Wordpress and Nextcloud, so I deployed both using a reverse proxy (nginx) and a Letsencrypt container for the certificates.

Now the compose files uploaded are used by me to test new tools or functionalities.

## Infrasructure
Basically this infrastructure is just some services behind a reverse proxy. There is'nt mush to say about it but I did a litle diagram explaing everything :

![diagram of the reverse proxy](./infra.png "reverse proxy diagram")

*Note that every app is a Docker container, even the Nginx reverse proxy and the lets encrypt companion. As explained above everything will be detailed in the README.md of the specified service.*

## Services
I'll put a bit more details on the diffrent apps I deployed along with their state and the linkks to the developer's website.

### Reverse proxy
The reverse proxy that is set-up there is an automated proxy that will modify it's own configuration depending on some environment variables put in some containers. You can pull this image directly from the Dockerhub at [this URL](https://hub.docker.com/r/jwilder/nginx-proxy). The official repo is available [there](https://github.com/nginx-proxy/nginx-proxy).

I also use a let's encrypt companion that will generate certificates and pass them to the reverse proxy. This allows my services to be accessible via https requests, being a bit more secured (even if let's encrypt certs aren't the best in terms of security). The link to the image is [this one](https://hub.docker.com/r/jrcs/letsencrypt-nginx-proxy-companion), even tho I just realized it is deprecated. A new images that does exactly the same job is available there [New image](https://hub.docker.com/r/nginxproxy/acme-companion) so I might do the update soon.
