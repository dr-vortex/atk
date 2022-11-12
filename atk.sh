#!/bin/bash

version="0.1"

set_env_var(){
	var_name=$1
	var_value=$2
	var_display=${3:-$1}
	if [ $var_name = "ATK_ROOT" ]; then ATK_ROOT=$var_value; fi
	sed -i "s/^export $var_name=.*/export $var_name=$var_value/" "$HOME/.bashrc"
	grep -q "export $var_name=" "$HOME/.bashrc" || echo "export $var_name=$var_value" >> "$HOME/.bashrc"
	
	sed -i "s/^Define $var_name .*/Define $var_name $var_value/" "$ATK_ROOT/.atk.conf"
	grep -q "Define $var_name " "$ATK_ROOT/.atk.conf" || echo "Define $var_name $var_value" >> "$ATK_ROOT/.atk.conf"
	export ${var_name}=$var_value
	echo "Set $var_display to $var_value"
}

_help(){
	echo -e "Usage:

	atk install
		Installs various utilities	
		-d: Do a dry run of the command
		-g <value>: Sets the package manager
		-a: Installs apache
		-c: Installs certbot (regular)
		-C <dns provider>: Installs certbot (wildcard) using the given dns provider
		-m: Installs mariadb
		
	atk setup
		Set up installed utilities
		-h <host>: Sets the host (domain) of ATK
		-r <root>: Sets the root directory of ATK
		-d: Do a dry run
		-a: Set up apache
		-c: Set up certbot (wildcard)
		-m: Set up mariadb
	
	atk sub
		Manage subdomains
	
			atk sub add <name>
				Adds a subdomain
				If certbot is set up, it will automatically add SSL

			atk sub remove <name>
				Remove a subdomain
"
}

_install(){
	
	local pkgmgr="yum"
	local dry=false
	
	install_certbot(){
		sudo $pkgmgr install epel-release
		sudo $pkgmgr install snapd
		sudo $pkgmgr install snapd
		sudo systemctl enable --now snapd.socket
		sudo ln -s /var/lib/snapd/snap /snap
		sudo snap install core
		sudo snap refresh core
		sudo snap install --classic certbot
		sudo ln -s /snap/bin/certbot /usr/bin/certbot
	}
	
	install(){
		if [ $dry = true]
		then
			echo "Would install '$1':"
			if [ $pkgmgr = "apt" ] || [ $pkgmgr = "apt-get" ]
			then
				apt-cache show $1	
			else
				sudo $pkgmgr -q list $1 | tail -1
			fi
	
		else
			sudo $pkgmgr install $1
		fi
	}
	echo "Installing..."
	while getopts ":dg:acC:m" argname; do
		arg=${OPTARG}
		case $argname in
			d)
				echo "Treating as dry run"
				dry=true
			;;
			g)
				pkgmgr=$arg
				echo "Using package manager: $pkgmgr"
			;;
			a)
				echo "Installing apache"
				pkg="httpd"
				if [ $pkgmgr = "apt" ] || [ $pkgmgr = "apt-get" ]
 				then
					pkg="apache2"
				fi
				install $pkg
			;;
			c)
				echo "Installing certbot"
				if [ $dry = true ]
				then
					echo "Nothing installed (dry run)"
				else
					install_certbot
				fi
			;;
			C)
				echo "Installing certbot (wildcard)"
				if [ $dry = true ]
				then
					echo "Would install certbot with dns provider '$arg'"
				else
					install_certbot
					sudo snap set certbot trust-plugin-with-root=ok
					sudo snap install certbot-dns-$arg
				fi
			;;
			m)
				echo "Installing MariaDB"
				install mariadb
			;;
			
		esac
	done
}

_setup(){

	echo "Setting up..."
	local dry=false
	local norewrite=false

	while getopts ":damch:r:" argname; do
		arg=${OPTARG}
		case $argname in
			d)
				echo "Treating as dry run"
				dry=true
			;;
			h)
				set_env_var "ATK_HOST" "$arg" "host"
			;;
			r)
				local root="$(realpath $arg)"
				set_env_var "ATK_ROOT" "$root" "root"
			;;
			n)
				nowrite=true
			;;
			a)
				local webroot=${ATK_ROOT:-$HOME}

				echo "Setting up Apache$(if [ $dry = true ]; then  echo " (dry run)"; fi)"	

				conffile="httpd.conf"
				tmpconf="atk_tmp_httpd_conf.conf"

				if ![ $ATK_ROOT ]; then
					echo "ATK root is not set!"
					read -p "Web root? ($HOME): " webroot
					webroot=$(realpath ${webroot:-$HOME})
					set_env_var "ATK_ROOT" "$webroot" "root"
				fi
				mkdir -p "$webroot"
				mkdir -p "$webroot/www"
				touch "$webroot/.atk.conf"
				echo -e "Define ATK_ROOT $webroot\nDefine ATK_HOST localhost\n<VirtualHost *:443 *:80>\nServerName \${ATK_HOST}\nServerAlias *.\${ATK_HOST}\nVirtualDocumentRoot \${ATK_ROOT}/%1\n\nRewriteEngine on\nRewriteCond %{HTTP_HOST} ^\${ATK_HOST}\nRewriteRule ^(.*) https://www.\${ATK_HOST}/%{REQUEST_URI} [P]\nSSLProxyEngine on\nProxyPassReverse / https://\${ATK_HOST}/\n</VirtualHost>" > "$webroot/.atk.conf"
				echo "Created webroot at $webroot"
				if [ $norewrite = false]; then sed "/^[ ]*#/d" "$conffile" | sed "/^$/d" | sed "/^DocumentRoot/d" > "$tmpconf"; fi
				echo "Include \${ATK_ROOT}/.atk.conf" >> "$tmpconf"
				if [ $dry = true ]
					then mv "$tmpconf" "$webroot/httpd.conf"; echo "Would have modified httpd.conf ($(if [ $norewrite = true]; then echo "Appended"; else echo "Rewrote"; fi)) (saved to $webroot/httpd.conf)"
					else mv "$tmpconf" "$conffile"; echo  "Modified httpd.conf ($(if [ $norewrite = true ]; then echo "Appended"; else echo "Rewrote"; fi))"
 				fi
			;;
			c)
				if ![ $ATK_ROOT ]; then echo "Can't set up certbot: Apache is not set up. (use -a)";
				elif ![ $ATK_HOST ]; then echo "Can't set up certbot: No host set (use -h <host>)";
				else
 					echo "Settings up certbot (wildcard)$(if [ $dry = true ]; then echo " (dry run)"; fi)"
					certbot certonly $(if [ $dry = true ]; then echo "--dry-run"; fi) --preferred-challenges=dns --email "admin@$ATK_HOST" --server https://acme-v02.api.letsencrypt.org/directory --agree-tos -d "*.$ATK_HOST" -d "$ATK_HOST" --manual
					certbot certonly $(if [ $dry = true ]; then echo "--dry-run"; fi) --preferred-challenges=dns --email "admin@$ATK_HOST" --server https://acme-v02.api.letsencrypt.org/directory --agree-tos -d "*.$ATK_HOST" -d "$ATK_HOST"
					touch "$ATK_ROOT/.atk.conf"
					echo -e "<IfModule mod_ssl.c>\nInclude /etc/letsencrypt/options-ssl-apache.conf\nSSLCertificateFile /etc/letsencrypt/live/$ATK_HOST/cert.pem\nSSLCertificateKeyFile /etc/letsencrypt/live/$ATK_HOST/privkey.pem\nSSLCertificateChainFile /etc/letsencrypt/live/$ATK_HOST/chain.pem\n</IfModule>" >> "$ATK_ROOT/.atk.conf"
					set_env_var "ATK_CERTBOT_SETUP" true "certbot setup"
				fi
			;;
			m)
				echo "Setting up mariadb"
				if [ $dry = true ]
				then
					echo "Nothing done (dry run)"	
				else
					mysql_secure_installation
				fi	
			;;
			
		esac
	done
}

_sub(){

	_add(){
		echo "Adding subdomain $1"
		mkdir "$ATK_ROOT/$1"
	}

	_remove(){
		echo "Removing subdomain $1"
		rm -rf "$ATK_ROOT/$1"
	}

	_list(){
		echo "Subdomains: "
		ls -d "$ATK_ROOT"
	}

	subcommand=$1
	case $subcommand in
		"" | "-h" | "--help")
			_help
			;;
		*)
			if ![ $ATK_ROOT && $ATK_HOST ]; then echo "Can't manage subdomains before settings up Apache and settings a host."; else
			shift
			_${subcommand} $@
			if [ $? = 127 ]; then
				echo "Error: $subcommand: Does not exist:" >&2
				exit 1
			fi fi
			;;
	esac
}
  
#
  
subcommand=$1
case $subcommand in
	"" | "-h" | "--help")
		_help
		;;
	"-v" | "--version")
		echo "ATK v$version"
		;;
	*)
		shift
		_${subcommand} $@
		if [ $? = 127 ]; then
			echo "Error: $subcommand: Does not exist:" >&2
			exit 1
		fi
		;;
esac
