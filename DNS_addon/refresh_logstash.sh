#!/bin/bash


###
### The Following script refreshes the logstash build after any changes to the dss_syslog.conf


elkbasefolder="pensando-elk"
rootfolder="pensandotools"





updatelogstash()
{
cd /$rootfolder/$elkbasefolder

logstash_hash=`docker ps --filter name=pensando-logstash | cut -d " " -f1| tail -n +2`
echo $logstash_hash
docker stop $logstash_hash
docker rm $logstash_hash

docker compose up --detach
# watch -n 2 -d -q 10 docker ps
		
}

while true ;
do
	echo -e "\e[0;31mPress Ctrl+C to exit at any time. \n\e[0m"

	read -p "[U]date logstash or e[X]it: " x

  x=${x,,}
  
  clear

	if [  "$x" ==  "u" ]; then
		updatelogstash
		exit 0

	elif [ "$x" ==  "x" ]; then
		echo -e "\nExiting...\n"
		exit 0


	else
		echo -e "\nInvalid option, try again...\n"
	fi

done
