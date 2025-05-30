# Pensando_ELK_Addons

The script is to add on customisations built by the team.


### To run directly off Github run the following command.
```
wget -O PensandoELKaddons.sh  https://raw.githubusercontent.com/tdmakepeace/Pensando_ELK_addons/refs/heads/main/PensandoELKaddons.sh && chmod +x PensandoELKaddons.sh  &&  ./PensandoELKaddons.sh $$ rm PensandoELKaddons.sh

```

### Run
Options available.

1. Option D - DNS enrichment of the CX10K flowlogs - written by Max Schmidt @ AMD - Max.Schmidt@amd.com
2. Option A - Application enrichment of the CX10K flowlogs - written by Max Schmidt @ AMD - Max.Schmidt@amd.com
3. Option S - Enable Security HTTP, username and password for loging - written by Toby Makepeace @ AMD - toby.makepeace@amd.com

DNS enrichment requires you to provide details of 1-3 dns servers.
Application enrichment requires you to maintain the prot_port_to_app_mapping.yml file in the /pensandotools/pensando-elk/logstash/ folder once deployed.

If you make a change to the prot_port_to_app_mapping.yml or the dss_syslog.conf file, you can reload using the refresh_logstash.sh script in the /pensandotools/pensando-elk/ folder

