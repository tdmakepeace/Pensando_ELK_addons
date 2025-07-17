# Pensando_ELK_Addons

The script is to add on customisations built by the team.


### To run directly off Github run the following command.
```
wget -O PensandoELKaddons.sh  https://raw.githubusercontent.com/tdmakepeace/Pensando_ELK_addons/refs/heads/main/PensandoELKaddons.sh && chmod +x PensandoELKaddons.sh  &&  ./PensandoELKaddons.sh $$ rm PensandoELKaddons.sh

```

### Run
Options available.

1. Option D - DNS enrichment of the CX10K flowlogs - written by Max Schmidt @ AMD - Max.Schmidt@amd.com
- Note: Option to add host-names if accessable via local DNS server reverse lookup.  Cache setting are set, but might need to be tweeked based on requirments.
2. Option A - Application enrichment of the CX10K flowlogs - written by Max Schmidt @ AMD - Max.Schmidt@amd.com
- Note: a sample "yaml" file as an example has been created, you can edit the "yaml" manually, or via PSM-Buddy. This does not map and corospond to the applications in PSM.
3. Option S - Enable Security HTTP, username and password for loging - written by Toby Makepeace @ AMD - toby.makepeace@amd.com
- Note - This option is for the enablement of username and password login to Kibana, this does not replace the full process of certificate creation and security.For that you will need to follow the Elastic Guides.
4. Option P - PSM Buddy, a day 1 enablement tool, that takes information for the CX10k series swtiches and pushes it to PSM for small project.
- Note: when the VLANs are created in PSM they are created with Connection-Tracking DISABLED, Fragmentation ENABLED, and Service Bypass ENABLED. This is to minimise the risks when activating.
The PSM Buddy does not change and enforce policy, you need to enable (DISABLE - Service Bypass) in PSM as part of a change.

DNS enrichment requires you to provide details of 1-3 dns servers. <br><br>
Application enrichment requires you to maintain the prot_port_to_app_mapping.yml file in the /pensandotools/pensando-elk/logstash/ folder once deployed.

If you make a change to the prot_port_to_app_mapping.yml or the dss_syslog.conf file, you can reload using the refresh_logstash.sh script in the /pensandotools/pensando-elk/ folder
- Note: If you are using PSM buddy, and it modifies the prot_port_to_app_mapping.yml list, you need to copy the file from the /pensandotools/pensando-elk/psmbuddy/app-instance folder to the /pensandotools/pensando-elk/logstash/ folder., and logstash will need a restart. If you modify the file manually, both PSM buddy and Logstash will require a restart.

