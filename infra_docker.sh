#!/bin/bash

echo "installation des dépendances :"

`sudo apt-get -y  install jq`

# définition du nom de domaine à utiliser pour la mise en place
yes_no=no

while [[ "$yes_no" != y  &&  "$yes_no" != yes ]]
do
	echo Entrez un nom de domaine à utiliser pour le déploiement
	read ndd
	echo -e "Souhaitez-vous bien utiliser \e[1;35m$ndd\e[0m comme nom de domaine ? (y(es)/n(o))"
	read yes_no
done

echo

echo Nom de domaine utilisé : $ndd


# définition de la fonction fcd pour cd dans les dossiers d'installation
function fcd () {
	cd $1
}


# définition ou création du dossier racine de l'installation
echo "Veuillez entrer le dossier racine de l'installation (chemin absolu)(merci de ne pas mettre de / à la fin du chemin)"
read path

if [ -d $path ]
then 
	fcd $path
	echo -e "Début de l'installation dans le dossier \e[1;35m$path\e[0m"
else
	`mkdir $path`
	fcd $path
	echo -e "Création du dossier \e[1;35m$path\e[0m et début de l'installation dans ce dossier"
fi


# création des réseaux docker pour accueillir les conteneurs :
#`docker network create net`  # à décommenter pour les vrais tests
#`docker network create common`  # à décommenter pour les vrais tests

`docker network create net2`

# début de l'installation du reverse Nginx :
echo -e "\e[1;45mInstallation du reverse proxy Nginx ...\e[0m "

`mkdir reverse_proxy`  # création de l'arborescence, positionement au bon endroit et création des fichiers de conf des dockers
fcd reverse_proxy
`touch docker-compose.yaml`
`touch .env`

echo -e "Veuillez indiquer une \e[1;35madresse mail\e[0m pour le compagnon letsencrypt"
read mail

echo -e '---\n\nversion: "3"\n\nservices:\n  reverse_proxy:\n    image: "jwilder/nginx-proxy:latest"\n    container_name: "reverse_proxy"\n    volumes:\n      - "./html:/usr/share/nginx/html"\n      - "./dhparam:/etc/nginx/dhparam"\n      - "./vhost:/etc/nginx/vhost.d"\n      - "./certs:/etc/nginx/certs:ro"\n      - "/run/docker.sock:/tmp/docker.sock:ro"\n      - "./conf_files:/etc/nginx/conf.d/"\n    restart: "always"\n    networks:\n      - net2\n    ports:\n      - "80:80"\n      - "443:443"\n\n  letsencrypt:\n    image: "jrcs/letsencrypt-nginx-proxy-companion:latest"\n    container_name: "letsencrypt_helper"\n    depends_on:\n      - reverse_proxy\n    volumes:\n      - "./html:/usr/share/nginx/html"\n      - "./dhparam:/etc/nginx/dhparam"\n      - "./vhost:/etc/nginx/vhost.d"\n      - "./certs:/etc/nginx/certs"\n      - "/run/docker.sock:/var/run/docker.sock:ro"\n    environment:\n      - NGINX_PROXY_CONTAINER\n      - DEFAULT_EMAIL\n    restart: "always"\n    networks:\n      - net2\n\nnetworks:\n  net2:\n    external: true'  >> docker-compose.yaml  # remplissage du fichier docker-compose pour le reverse-proxy nginx

echo -e "NGINX_PROXY_CONTAINER=reverse_proxy\nDEFAULT_EMAIL=$mail" >> .env  # remplissage du fichier .env du reverse proxy

`docker-compose up -d`  # commentée pour le moment, à décommenter pour les vrais tests.
echo -e "\e[1;32mNginx a bien été installé.\e[0m"
#`docker ps`  # à décommenter pour les vrais tests

fcd $path


# début de l'instation du WordPress
echo -e "Souhaitez vous \e[1;35minstaller WordPress\e[0m ? (y(es)/n(o))"
read yes_no

if [[ $yes_no == y || $yes_no == yes ]]
then
	echo -e "\e[1;45mInstallation de WordPress ...\e[0m"

	`mkdir wordpress`
	fcd wordpress
	`touch docker-compose.yaml`
	`touch .env`

	echo -e "Veuillez indiquer le \e[1;35mpréfixe\e[0m qui correspond au \e[1;35msous-domaine utilisé pour le wordpress\e[0m (que le préfixe sans le nom de domaine après) :"  #récupération du sous-domaine utilisé pour la configuration de notre VHOST
	read prefix_wp
	sub_wp="$prefix_wp.$ndd"
	echo "sous-domaine utilisé pour le wordpress : $sub_wp" 
	
	echo -e '---\n\nversion: "3"\n\nservices:\n  wp_db:\n    image: "mysql:5.7"\n    container_name: "wp_db"\n    environment:\n      - MYSQL_ROOT_PASSWORD\n      - MYSQL_DATABASE\n      - MYSQL_USER\n      - MYSQL_PASSWORD\n    restart: "always"\n    networks:\n      - common2\n\n  wordpress:\n    image: "wordpress:latest"\n    container_name: "wordpress"\n    depends_on:\n      - wp_db\n    volumes:\n      - "./conf_files/:/var/www/html"\n    environment:\n      - WORDPRESS_DB_HOST\n      - WORDPRESS_DB_USER\n      - WORDPRESS_DB_PASSWORD\n      - WORDPRESS_DB_NAME\n      - VIRTUAL_HOST\n      - LETSENCRYPT_HOST\n    restart: "always"\n    networks:\n      - net2\n      - common2\n\nnetworks:\n  net2:\n    external: true\n  common2:\n    internal: true' >> docker-compose.yaml

	echo -e "MYSQL_ROOT_PASSWORD=somewordpress\nMYSQL_DATABASE=wordpress\nMYSQL_USER=wordpress\nMYSQL_PASSWORD=wordpress\n\nWORDPRESS_DB_HOST=wp_db:3306\nWORDPRESS_DB_USER=wordpress\nWORDPRESS_DB_PASSWORD=wordpress\nWORDPRESS_DB_NAME=wordpress\nVIRTUAL_HOST=$sub_wp\nLETSENCRYPT_HOST=$sub_wp" >> .env

	`docker-compose up -d`  # à décommenter lors des vrais tests
	echo -e "\e[1;32mWordpress a bien été installé.\e[0m"
	fcd $path
fi


# début de l'installation du Nextcloud
echo -e "Souhaitez-vous \e[1;35minstaller Nextcloud\e[0m ? (y(es)/n(o))"
read yes_no

if [[ $yes_no == y || $yes_no == yes ]]
then
	echo -e "\e[1;45mInstallation de Nextcloud ...\e[0m"
	
	`mkdir nextcloud`
	fcd nextcloud
	`touch docker-compose.yaml`
	`touch .env`

	echo -e "Veuillez indiquer le \e[1;35mpréfixe\e[0m qui correspond au \e[1;35msous-domaine utilisé pour le nextcloud\e[0m (que le préfixe sans le nom de domaine après) :"  #récupération du sous-domaine utilisé pour la configuration de notre VHOST
	read prefix_nc
	sub_nc="$prefix_nc.$ndd"
	echo "sous-domaine utilisé pour le wordpress : $sub_nc"

	echo -e "Veuillez indiquer le \e[1;35mnom de l'utilisateur administrateur de votre Nextcloud\e[0m :"
	read root_usr_nc

	echo -e "Veuillez indiquer le \e[1;35mmot de passe de l'administrateur de votre Nextcloud\e[0m :"
	read root_passwd_nc

	trusted_proxies_nc=`docker inspect -f '{{ json .IPAM.Config }}' net | jq -r .[].Subnet`

	echo -e '---\n\nversion: "3"\n\nservices:\n  nc_db:\n    image: "mariadb:10.5.9"\n    container_name: "nc_db"\n    volumes:\n      - "./NCMariaDB:/var/lib/mysql"\n    environment:\n      - MYSQL_ROOT_PASSWORD\n      - MYSQL_RANDOW_ROOT_PASSWORD\n      - MYSQL_DATABASE\n      - MYSQL_USER\n      - MYSQL_PASSWORD\n    restart: "always"\n    networks:\n      - common2\n\n  nc:\n    image: "nextcloud:27.1.3"\n    container_name: "nextcloud"\n    depends_on:\n      - nc_db\n    volumes:\n      - "./NCData:/var/www/html"\n    environment:\n      - LETSENCRYPT_HOST\n      - VIRTUAL_HOST\n      - TRUSTED_PROXIES\n      - OVERWRITEPROTOCOL\n      - MYSQL_DATABASE\n      - MYSQL_USER\n      - MYSQL_PASSWORD\n      - MYSQL_HOST\n      - SMTP_HOST\n      - SMTP_PORT\n      - SMTP_NAME\n      - SMTP_PASSWORD\n      - MAIL_FROM_ADDRESS\n      - NEXTCLOUD_TRUSTED_DOMAINS\n      - NEXTCLOUD_ADMIN_USER\n      - NEXTCLOUD_ADMIN_PASSWORD\n    restart: "always"\n    networks:\n      - net2\n      - common2\n\nnetworks:\n  net2:\n    external: true\n  common2:\n    internal: true' >> docker-compose.yaml

	echo -e "MYSQL_ROOT_PASSWORD=somenextcloudpassword\nMYSQL_DATABASE=NC\nMYSQL_USER=nextcloud\nMYSQL_PASSWORD=somenextcloudpassword\nMYSQL_HOST=nc_db\n\nLETSENCRYPT_HOST=$sub_nc\nVIRTUAL_HOST=$sub_nc\nTRUSTED_PROXIES=$trusted_proxies_nc\nOVERWRITEPROTOCOL=https\nNEXTCLOUD_TRUSTED_DOMAINS=$sub_nc\nNEXTCLOUD_ADMIN_USER=$root_usr_nc\nNEXTCLOUD_ADMIN_PASSWORD=$root_passwd_nc" >> .env

	`docker-compose up -d`  #à décommenter pour les vrais tests
	echo -e "\e[1;32mNextcloud a bien été installé.\e[0m"
	fcd $path
fi


# début de l'installation du Hedgedoc
echo -e "Souhaitez-vous \e[1;35minstaller Hedgedoc\e[0m ? (y(es)/n(o))"
read yes_no

if [[ $yes_no == y || $yes_no == yes ]]
then
	echo -e "\e[1;45mInstallation de Hedgedoc ...\e[0m"
	
	`mkdir hedgedoc`
	fcd hedgedoc
	`touch docker-compose.yaml`
	`touch .env`

	echo -e "Veuillez indiquer le \e[1;35mpréfixe\e[0m qui correspond au \e[1;35msous-domaine utilisé pour le hedgedoc\e[0m (que le préfixe sans le nom de domaine après) :"  #récupération du sous-domaine utilisé pour la configuration de notre VHOST
	read prefix_hd
	sub_hd="$prefix_hd.$ndd"
	echo "sous-domaine utilisé pour le hedgedoc : $sub_hd"

	echo -e '---\n\nversion: "3"\n\nservices:\n  hd_db:\n    image: "postgres:13.4-alpine"\n    container_name: "hd_db"\n    volumes:\n      - database:/var/lib/postgresql/data\n    environment:\n      - POSTGRES_USER\n      - POSTGRES_PASSWORD\n      - POSTGRES_DB\n    restart: "always"\n    networks:\n      - common2\n\n  hedgedoc:\n    image: "quay.io/hedgedoc/hedgedoc:1.9.9"\n    container_name: "hedgedoc"\n    depends_on:\n      - hd_db\n    volumes:\n      - uploads:/hedgedoc/public/uploads\n    environment:\n      - CMD_DB_URL\n      - CMD_DOMAIN\n      - CMD_URL_ADDPORT\n      - VIRTUAL_HOST\n      - LETSENCRYPT_HOST\n      - CMD_PROTOCOL_USESSL\n    restart: "always"\n    networks:\n      - net2\n      - common2\n    ports:\n      - "3000:3000"\n\nvolumes:\n  database:\n  uploads:\nnetworks:\n  net2:\n    external: true\n  common2:\n    internal: true' >> docker-compose.yaml
	
	echo -e "POSTGRES_USER=hedgedoc\nPOSTGRES_PASSWORD=password\nPOSTGRES_DB=hedgedoc\n\nCMD_DB_URL=postgres://hedgedoc:password@hd_db:5432/hedgedoc\nCMD_DOMAIN=$sub_hd\nCMD_URL_ADDPORT=false\nVIRTUAL_HOST=$sub_hd\nLETSENCRYPT_HOST=$sub_hd\nCMD_PROTOCOL_USESSL=true" >>.env

	`docker-compose up -d`  #à décommenter pour les vrais tests
	echo -e "\e[1;32mHedgedoc a bien été installé.\e[0m"
	fcd $path
fi
