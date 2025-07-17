#!/bin/bash

###
### 

### wget -O PensandoELKaddons.sh  https://raw.githubusercontent.com/tdmakepeace/Pensando_ELK_addons/refs/heads/main/PensandoELKaddons.sh && chmod +x PensandoELKaddons.sh  &&  ./PensandoELKaddons.sh


###	

elkaddonlocation="https://github.com/tdmakepeace/Pensando_ELK_addons.git"
elkbasefolder="pensando-elk"
rootfolder="pensandotools"
elkaddonfolder="Pensando_ELK_addons"

###  main code area should not be modified.
	
rebootserver()
{
		echo -e "\e[0;31mRebooting the system...\n\e[0m"
		
		sleep 5
		sudo reboot
		sleep 10
		break
}

updates()
{
		
		sudo apt-get update 
		sudo NEEDRESTART_SUSPEND=1 apt-get dist-upgrade --yes 

		sleep 10
}

updatesred()
{
		subscription-manager attach --auto
		subscription-manager repos
		sudo yum update -y -q 

		sleep 10
}

updateos()
{
	real_user=$(whoami)


	os=`more /etc/os-release |grep PRETTY_NAME | cut -d  \" -f2 | cut -d " " -f1`
	if [ "$os" == "Ubuntu" ]; then 
			updates
			
	elif [ "$os" == "Red" ]; then
			updatesred
	
	fi 
			
	
	}
create_rootfolder()
{
	real_user=$(whoami)
	cd /
	sudo mkdir $rootfolder
	sudo chown $real_user:$real_user $rootfolder
	sudo chmod 777 $rootfolder
	mkdir -p /$rootfolder/
	mkdir -p /$rootfolder/scripts
}

create_addonfolder()
{
	cd /
	cd $rootfolder
	git clone $elkaddonlocation
}

check_rootfolder_permissions()
{
	# Get the current user
	real_user=$(whoami)

	# Check if the rootfolder exists
	echo "Checking if $rootfoler exists"
    if [ -d "/$rootfolder" ]; then
        # Check if the directory is writable by the current user
        if [ -w "/$rootfolder" ]; then
            echo "/$rootfolder exists and is writable by $real_user"
        else
            echo "/$rootfolder exists but is not writable by $real_user, changing ownership"
            sudo chown $real_user:$real_user "/$rootfolder"
            # Verify the change was successful
            if [ -w "/$rootfolder" ]; then
                echo "Successfully changed ownership of /$rootfolder to $real_user"
            else
                echo "Failed to make /$rootfolder writable by $real_user"
                return 1
            fi
        fi
    else
        echo "/$rootfolder does not exist, creating it"
        create_rootfolder
    fi
}

check_addon_permissions()
{
	# Get the current user
    real_user=$(whoami)

	# Check if the rootfolder exists
	echo "Checking if $rootfoler exists"
    if [ -d "/$rootfolder/$elkaddonfolder" ]; then
        # Check if the directory is writable by the current user
        if [ -w "/$rootfolder/$elkaddonfolder" ]; then
            echo "/$rootfolder/$elkaddonfolder exists and is writable by $real_user"
        else
            echo "/$rootfolder/$elkaddonfolder exists but is not writable by $real_user, changing ownership"
            sudo chown $real_user:$real_user "/$rootfolder/$elkaddonfolder"
            # Verify the change was successful
            if [ -w "/$rootfolder" ]; then
                echo "Successfully changed ownership of /$rootfolder/$elkaddonfolder to $real_user"
            else
                echo "Failed to make /$rootfolder/$elkaddonfolder writable by $real_user"
                return 1
            fi
        fi
    else
        echo "/$rootfolder/$elkaddonfolder does not exist, creating it"
        create_addonfolder
    fi
}

elksecurefile()
{
	
	cd /$rootfolder/$elkbasefolder/

	if grep -q "xpack.security.enabled=false" "docker-compose.yml"; then
		cp docker-compose.yml docker-compose.yml.presec	

		sed -i '/- cluster.initial_master_nodes=es01/d' docker-compose.yml
		sed -i '/- node.name=es01/d' docker-compose.yml
		sed -i.bak "s/- xpack.security.enabled=false/- discovery.type=single-node\n      - xpack.security.enabled=true\n      - ELASTIC_PASSWORD=changeme/" docker-compose.yml
		sed -i.bak "s/pensando-kibana/pensando-kibana\n    environment:\n      - ELASTICSEARCH_HOSTS=http:\/\/elasticsearch:9200\n      - ELASTICSEARCH_USERNAME=kibana_system\n      - ELASTICSEARCH_PASSWORD=kibana_system_pass\n      - xpack.security.enabled=true/" docker-compose.yml
	else
	echo -e "\e[0;31mdocker compose with xpack already set up\e[0m\n check the config files"
	fi


	
}

elksecureup()
{
	export elkpass=$(< /dev/urandom tr -dc 'A-Za-z0-9' | head -c11)
	export kibpass=$(< /dev/urandom tr -dc 'A-Za-z0-9' | head -c11)
	cd logstash
	cp dss_syslog.conf dss_syslog.conf.orig
	sed -i.bak 's/hosts[[:space:]]*=>[[:space:]]*\[ '\''elasticsearch'\'' \]/hosts    => [ '\''elasticsearch'\'' ]\n    user => '\"'elastic'\"' \n    password => '\"$elkpass\"' /' dss_syslog.conf

	cd ..
	sed -i.bak 's/changeme/'$elkpass'/' docker-compose.yml
	sed -i.bak 's/kibana_system_pass/'$kibpass'/' docker-compose.yml
	sleep 2
	docker compose up --detach --build
	echo -e "Waiting 100 seconds for services to start before configuration password...\n" | fold -w 80 -s
	sleep 20
	echo -e "80 seconds remaining...\n"
	sleep 20
	echo -e "60 seconds remaining...\n"
	sleep 20
	echo -e "40 seconds remaining...\n"
	sleep 20
	echo -e "20 seconds remaining...\n"
	sleep 15
	echo -e "5 seconds remaining...\n"
	sleep 1
	echo -e "4 seconds remaining...\n"
	sleep 1
	echo -e "3 seconds remaining...\n"
	sleep 1
	echo -e "2 seconds remaining...\n"
	sleep 1
	echo -e "1 second remaining...\n"
	sleep 1
	clear
	echo -e "Enter the following password into the password reset for Kibana_system :\e[0;31m $kibpass\e[0m"
	docker exec -it pensando-elasticsearch /usr/share/elasticsearch/bin/elasticsearch-reset-password -i -u kibana_system 
	curl -u elastic:$elkpass -X POST "http://localhost:9200/_security/user/admin?pretty" -H 'Content-Type: application/json' -d'{  "password" : "Pensando0$",  "roles" : [ "superuser" ],  "full_name" : "ELK Admin",  "email" : "admin@example.com"}'
	clear
	echo -e " Default username and password setup is: \n\e[0;31madmin - \"Pensando0$\"\n\e[0m"

}

secureelk()
{
	clear
	localip=`hostname -I | cut -d " " -f1`
	echo "Do you wish to enable ELK stack security for Kibana.
This is done as http only - if you wish to use https - refer to the ELK documentation"
	
	echo ""
	echo -e " This will take about 5 minutes"
	echo ""
	
		read -p "[Y]es or [N}o " p

		p=${p,,}

  	if  [[ "$p" == "y" ]]; then
  		cd /$rootfolder/$elkbasefolder/
			if grep -q "xpack.security.enabled=true" "docker-compose.yml"; then
				if grep -q "ELASTIC_PASSWORD=changeme" "docker-compose.yml"; then
    			docker compose down
					elksecureup
				else 
					echo -e "\e[0;31mdocker compose with xpack already configured \n\e[0m"

				fi 
			else
				elkdockerdown
				elksecurefile
				elksecureup
			fi
 
			elkdockerupnote

 		elif  [ "$p" == "n" ]; then
 			clear
 			elkdockerupnote
		fi
		 
}

elkdockerdown()
{
			cd /$rootfolder/$elkbasefolder/
			docker compose down
			
}


refreshAddOn()
{
	check_addon_permissions
	cd /$rootfolder/$elkaddonfolder
	sleep 2
	git pull $elkaddon
	
}


enableapp()
{
	cd /$rootfolder/$elkbasefolder/
	cp docker-compose.yml docker-compose.yml.preapp

  sed -z -i.bak "s/\(pensando-logstash\n[[:space:]]*environment:\)/\1\n      - DICT_FILE=\/usr\/share\/logstash\/config\/prot_port_to_app_mapping.yml/" docker-compose.yml
  sed -z -i.bak "s|\${PWD}/logstash/psm_event.conf:/usr/share/logstash/pipeline/psm_event.conf|&\n      - \${PWD}/logstash/prot_port_to_app_mapping.yml:/usr/share/logstash/config/prot_port_to_app_mapping.yml|" docker-compose.yml

	cd logstash
	cp /$rootfolder/$elkaddonfolder/APPID_addon/prot_port_to_app_mapping.yml prot_port_to_app_mapping.yml
	cp dss_syslog.conf dss_syslog.conf.preapp

	cp /$rootfolder/$elkaddonfolder/APPID_addon/APPID_addon.conf ./
	
	SOURCE_FILE="APPID_addon.conf"
	TARGET_FILE="dss_syslog.conf.preapp"
	POST_FILE="dss_syslog.conf"
	MARKER="## Begining of add-in options ##"
	TEMP_FILE=$(mktemp)
	# Read through the target file and insert source content after the marker
	while IFS= read -r line; 
		do
			echo "$line" >> "$TEMP_FILE"
			if [[ "$line" == *"$MARKER"* ]]; then
				cat "$SOURCE_FILE" >> "$TEMP_FILE"
			fi
	done < "$TARGET_FILE"
	#
	# Replace the original target file with the updated one
	mv "$TEMP_FILE" "$POST_FILE"             
		
}


psmbuddy()
{
	cd /$rootfolder/$elkbasefolder/	
	mkdir -p psmbuddy
	mkdir -p psmbuddy/app-instance
	mkdir -p psmbuddy/snapshot
	mkdir -p psmbuddy/backups
	chmod -R 777 psmbuddy
	
	cp docker-compose.yml docker-compose.yml.prepsmbuddy
	cp /$rootfolder/$elkaddonfolder/psmbuddy/psmbuddy.yml ./
	SOURCE_FILE="psmbuddy.yml"
	TARGET_FILE="docker-compose.yml.prepsmbuddy"
	POST_FILE="docker-compose.yml"
	MARKER="  # ElastiFlow Unified Collector"
	TEMP_FILE=$(mktemp)
	# Read through the target file and insert source content after the marker
	while IFS= read -r line; 
		do
			if [[ "$line" == *"$MARKER"* ]]; then
				cat "$SOURCE_FILE" >> "$TEMP_FILE"
			fi
			echo "$line" >> "$TEMP_FILE"
	done < "$TARGET_FILE"
	#
	# Replace the original target file with the updated one
	mv "$TEMP_FILE" "$POST_FILE"
	
	
}

enabledns()
{
	cd /$rootfolder/$elkbasefolder/
	cp /$rootfolder/$elkaddonfolder/DNS_addon/refresh_logstash.sh ./
	chmod +x *.sh
	cd logstash
	cp dss_syslog.conf dss_syslog.conf.predns
	cp /$rootfolder/$elkaddonfolder/DNS_addon/DNS_addon.conf ./
	
	SOURCE_FILE="DNS_addon.conf"
	TARGET_FILE="dss_syslog.conf.predns"
	POST_FILE="dss_syslog.conf"
	MARKER="## Begining of add-in options ##"
	TEMP_FILE=$(mktemp)
	# Read through the target file and insert source content after the marker
	while IFS= read -r line; 
		do
			echo "$line" >> "$TEMP_FILE"
			if [[ "$line" == *"$MARKER"* ]]; then
				cat "$SOURCE_FILE" >> "$TEMP_FILE"
			fi
	done < "$TARGET_FILE"
	#
	# Replace the original target file with the updated one
	mv "$TEMP_FILE" "$POST_FILE"
}

setdns()
{
		cd /$rootfolder/$elkbasefolder/logstash
		echo -e "\e[0;31mNumber of DNS Servers. \n\e[0m"
		read -p "Recommend 2: " x
		
	if [  "$x" ==  "1" ]; then
		read -p "Enter the first IP: " dns1
		sed -i.bak -r "s/\"8.8.8.8\"/\"$dns1\"/" dss_syslog.conf

							
	elif [  "$x" ==  "2" ]; then
		read -p "Enter the first IP: " dns1
		read -p "Enter the second IP: " dns2
		sed -i.bak -r "s/\"8.8.8.8\"/\"$dns1\" , \"$dns2\"/" dss_syslog.conf
				  

	elif [ "$x" ==  "3" ]; then
		read -p "Enter the first IP: " dns1
		read -p "Enter the second IP: " dns2
		read -p "Enter the third IP: " dns3
		sed -i.bak -r "s/\"8.8.8.8\"/\"$dns1\" , \"$dns2\", \"$dns3\"/" dss_syslog.conf


	else
		echo -e "\nSupport options are 1 to 3.\n"
	fi
		

}

restartlogstash()
{
	cd /$rootfolder/$elkbasefolder/
	./refresh_logstash.sh
}


testcode()
{
	cd /$rootfolder/$elkbasefolder/
	cp docker-compose.yml docker-compose.yml.preapp
	TARGET_FILE="docker-compose.yml.preapp"
	POST_FILE="docker-compose.yml"
	MARKER1="  logstash:"
	MARKER2="      - \${PWD}/logstash/psm_event.conf:/usr/share/logstash/pipeline/psm_event.conf"
	TEMP_FILE=$(mktemp)
	# Read through the target file and insert source content after the marker
	while IFS= read -r line; 
		do
			echo "$line" >> "$TEMP_FILE"
			if [[ "$line" == *"$MARKER1"* ]]; then
				echo "    environment:
    - DICT_FILE=/usr/share/logstash/config/prot_port_to_app_mapping.yml" >> "$TEMP_FILE"
			fi 
			if [[ "$line" == *"$MARKER2"* ]]; then
				echo "test"
				sleep 5
				echo "      - \${PWD}/logstash/prot_port_to_app_mapping.yml:/usr/share/logstash/config/prot_port_to_app_mapping.yml" >> "$TEMP_FILE"


			fi
	done < "$TARGET_FILE"
	#
	# Replace the original target file with the updated one
	mv "$TEMP_FILE" "$POST_FILE"     
		
}

while true ;
do
	echo -e "\e[0;31mPress Ctrl+C to exit at any time. \n\e[0m"

  echo -e "\n\e[1;33mThis following script will setup a number of addons to the Pensando ELK Stack \n\e[0m

Workflows provided by this script will: 


- Update OS patches
- Enable Security login to ELK (HTTP only)
- Enable DNS
- Enable APPID
- Enable PSM Buddy
\n" | fold -w 120 -s
	
read -p " [U]pdate OS, Enable [S]ecurity, Enable [D]ns lookup, Enable [A]PPID mapping , Enable [P]smBuddy or e[X]it: " x

  x=${x,,}
  
  clear

	if  [ $x == "d" ]; then
		echo -e "\nPress Ctrl+C to exit at any time.\n"
		echo -e "This workflow should only be run once; do not run it again unless you have previously cancelled it before completion.\n" | fold -w 80 -s
		refreshAddOn
		read -p "Enter 'C' to continue: " x
		
		x=${x,,}
		clear

		while [ $x ==  "c" ] ;
		do
	    	enabledns
	    	setdns
	    	read -p "Enter 'C' to restart logstash: " y
		
				y=${y,,}
				clear
				while [ $y ==  "c" ] ;
				do
	    			restartlogstash
				  	y="done"
			  done
	    	x="done"

	  done
	  
	 elif  [ $x == "a" ]; then
		echo -e "\nPress Ctrl+C to exit at any time.\n"
		echo -e "This workflow should only be run once; do not run it again unless you have previously cancelled it before completion.\n" | fold -w 80 -s
		refreshAddOn
		read -p "Enter 'C' to continue: " x
		
		x=${x,,}
		clear

		while [ $x ==  "c" ] ;
		do
	    	enableapp
	    	read -p "Enter 'C' to restart logstash: " y
		
				y=${y,,}
				clear
				while [ $y ==  "c" ] ;
				do
	    			restartlogstash
				  	y="done"
			  done
	    	x="done"

	  done
	  
	 elif [  "$x" ==  "s" ]; then
		echo -e "\nPress Ctrl+C to exit at any time.\n"
		echo -e "This workflow should only be run once; do not run it again unless you have previously cancelled it before completion.\n" | fold -w 80 -s
		read -p "Enter 'C' to continue: " x
		
		x=${x,,}
		clear
		while [ $x ==  "c" ] ;
		do
	    	secureelk
		  	x="done"
	  done
	  
	  elif [  "$x" ==  "p" ]; then
		echo -e "\nPress Ctrl+C to exit at any time.\n"
		echo -e "This workflow should only be run once; do not run it again unless you have previously cancelled it before completion.\n" | fold -w 80 -s
		read -p "Enter 'C' to continue: " x
		
		x=${x,,}
		clear
		while [ $x ==  "c" ] ;
		do
	    	psmbuddy
		  	x="done"
	  done
	  
	elif [  "$x" ==  "u" ]; then
		updateos
	  
		
	elif [  "$x" ==  "t" ]; then
		testcode
				  

	elif [ "$x" ==  "x" ]; then
		echo -e "\nExiting...\n"
		exit 0


	else
		echo -e "\nInvalid option, try again...\n"
	fi

done