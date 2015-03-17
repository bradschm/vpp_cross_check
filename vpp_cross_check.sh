#!/bin/bash

###########################################################################################################################
### VPP Cross Check - Add Devices to Push Ready Smart Group														                              		###
### Problem that this script solves: Scope your Apps you want to push to this Smart Group and the user will not see   	###
### multiple prompts to install	the App at enrollment. It waits until it sees that a user has accepted the VPP 	    		###
### invitation then it pushes the app (hopefully silently) to the device.									                        			###
### The script looks up mobile devices that have enrolled recently and checks to see if the user associated with the  	###
### device has accepted the VPP invitation. You could scope this to all devices for the first run to get previously   	###
### enrolled devices. Then scope it to the mobile device smart group described in requirements.		            					###
### Devices that are Push Ready can have Apps scoped to them with the push command  				                  					###
### Authored by Brad Schmidt on 3-10-2015											  							                                      		###
###########################################################################################################################

###########################################################################################################################
### Requirements 																								                                                    		###
### JSS Components:																					                                                  					###
### Advanced user search ( Users that have associated with the VPP invitation)		                    									###
### Mobile Device Advanced Search ( Find iPads that just enrolled that have not been added to Push Ready Smart Group )	###
### Extension Attribute ( Push Ready - Script updates to Yes )									                            						###
### Smart Group ( Push Ready - Devices where Push Ready EA is Yes )								                          						###
### Note: This script uses files to store data, I would like to to eventually use arrays. The files will write to the   ###
### same directory this script is excuted from. It will clean up the files at the end of the script.                    ###
###########################################################################################################################

###########################################################################################################################
### XML2 Binary													                                                    														###
### xml2 - used for xml parsing takes xml input and outputs to a path			                          										###
### For example - <computer><user>username</user></computer> turns into				                        									###
### /computer/user=username																							                                              	###
### xml2 Website: http://www.ofb.net/~egnor/xml2/					                                    													###
### How to obtain: 																				                                                  						###
### Linux: sudo apt-get install xml2										                                          											###
### Mac using Mac brew: brew install xml2											                                        									###
### If you don't have Homebrew on your Mac, check out: http://brew.sh		                          											###
### Quickest way to get Homebrew setup on your Mac: 													                                  				###
### Run this in terminal: ruby -e "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install)"	  	###
### Note: If you install xml2 with apt it will install to /usr/bin/xml2 										                        		###
### If you install on Mac it installs to /usr/local/opt/xml2/bin/xml2 										                        			###
###########################################################################################################################

# xml2 binary location finder
if [ -e /usr/local/opt/xml2/bin/xml2 ]
	then xml2=/usr/local/opt/xml2/bin/xml2 
fi

if [ -e /usr/bin/xml2 ]
	then xml2=/usr/bin/xml2
fi

# If xml2 is install elsewhere set it here:
# xml2=/your/special/path

# Logging -- Each step is logged along with time. Each serial,user is logged to the $LOGFILE 
LOGFILE=VPPCrossCheck.log

# Start a new section of the log
/bin/echo "-------------------------------New Run------------------------------" >> $LOGFILE
/bin/date "+%Y-%m-%d %H:%M:%S: VPP Cross Check started" >> $LOGFILE

# Set Credentials and JSS URL
un=APIUser
pw=password
jssurl='https://jss.com:8443'

# Advanced Mobile Device Search Set to only enrolled in last 24 hours ( Switch to All Mobile Devices Search for first run )
# These need to be created in advance. To get the ID look at the URL when viewing the object. 
advancedmobiledevicesearch=#

# Advanced User Search looking for VPP Associated Status
advancedusersearch=#

# Extension Attribute ID for Push Ready EA
extattribute=#

# Get Recently Enrolled Devices that aren't in the Push Ready group yet.
/usr/bin/curl -s -k -u $un:$pw $jssurl/JSSResource/advancedmobiledevicesearches/id/$advancedmobiledevicesearch > justenrolled.xml

# Log it
if [ $? = 0 ] ; then
/bin/date "+%Y-%m-%d %H:%M:%S: Devices downloaded from JSS." >> $LOGFILE
else
/bin/date "+%Y-%m-%d %H:%M:%S: Devices NOT downloaded from JSS." >> $LOGFILE
fi

# Extract the serial numbers from the XML
$xml2 < justenrolled.xml | /usr/bin/grep '/advanced_mobile_device_search/mobile_devices/mobile_device/Serial_Number=' | /usr/bin/awk -F'=' ' {print $2} ' > mobiledeviceserials.txt

# Log it
if [ $? = 0 ] ; then
/bin/date "+%Y-%m-%d %H:%M:%S: Serial numbers extracted." >> $LOGFILE
else
/bin/date "+%Y-%m-%d %H:%M:%S: Serial numbers NOT extracted." >> $LOGFILE
fi

# Check to see if there are any results, exit the script if no results found.
devices=$(/usr/bin/more mobiledeviceserials.txt | wc -l)
if [[ $devices -eq 0 ]]
	then exit 0
fi

# Log it
/bin/date "+%Y-%m-%d %H:%M:%S: Getting ready to check $devices devices" >> $LOGFILE

# Generate a list of serial numbers and usernames
while read line 
do 
	username=$($xml2 < justenrolled.xml | /usr/bin/grep -A 15 'advanced_mobile_device_search/mobile_devices/mobile_device/Serial_Number='$line | /usr/bin/grep '/advanced_mobile_device_search/mobile_devices/mobile_device/Username=' | /usr/bin/awk -F'=' ' {print $2} ')
	/bin/echo $line,$username >> mobiledeviceinfo.txt
done < mobiledeviceserials.txt

# Log it
if [ $? = 0 ] ; then
/bin/date "+%Y-%m-%d %H:%M:%S: List of usernames and serial numbers generated." >> $LOGFILE
else
/bin/date "+%Y-%m-%d %H:%M:%S: List of usernames and serial numbers NOT generated." >> $LOGFILE
fi

# Get user information from VPP advanced user search
/usr/bin/curl -s -k -u $un:$pw $jssurl/JSSResource/advancedusersearches/id/$advancedusersearch > usersvppaccepted.xml
$xml2 < usersvppaccepted.xml | /usr/bin/grep 'Username' | /usr/bin/awk -F'=' ' {print $2} ' > usersvppaccepted.txt

# Log it
if [ $? = 0 ] ; then
/bin/date "+%Y-%m-%d %H:%M:%S: List of usernames that have accepted a VPP invitation downloaded." >> $LOGFILE
else
/bin/date "+%Y-%m-%d %H:%M:%S: List of usernames that have accepted a VPP invitation NOT downloaded." >> $LOGFILE
fi

# Match the list of users associated with devices to list of users that have accepted VPP - Logs it too.
while read line
do
	user=$(/bin/echo $line | /usr/bin/awk -F',' ' {print $2} ')
	match=$(/usr/bin/more usersvppaccepted.txt | /usr/bin/grep "$user" | wc -l)
		if [[ $match -gt 0 ]]
		then /bin/echo $line >> pushready.txt; /bin/date "+%Y-%m-%d %H:%M:%S: Adding $line to Push Ready Group." >> $LOGFILE 
		fi
done < mobiledeviceinfo.txt

# Log it
if [ $? = 0 ] ; then
/bin/date "+%Y-%m-%d %H:%M:%S: List of users matching devices generated." >> $LOGFILE
else
/bin/date "+%Y-%m-%d %H:%M:%S: List of users matching devices NOT generated." >> $LOGFILE
fi

# If matches then add to Push Ready Static Group
while read line
do 
serial=$(/bin/echo $line | /usr/bin/awk -F',' ' {print $1} ')
# /usr/bin/curl -s -k -u $un:$pw -H "Content-Type: application/xml" -d "<mobile_device><extension_attributes><extension_attribute><id>$extattribute</id><value>Yes</value></extension_attribute></extension_attributes></mobile_device>" -X PUT $jssurl/JSSResource/mobiledevices/serialnumber/$serial
done < pushready.txt

# Count devices added to Push Ready Group
devicesadded=$(/usr/bin/more pushready.txt | wc -l)

# Log it
if [ $? = 0 ] ; then
/bin/date "+%Y-%m-%d %H:%M:%S: EA updated on $devicesadded devices to reflect push readiness." >> $LOGFILE
else
/bin/date "+%Y-%m-%d %H:%M:%S: EA NOT updated on devices to reflect push readiness." >> $LOGFILE
fi

# Clean up time because I didn't use arrays...
/bin/rm mobiledeviceinfo.txt pushready.txt mobiledeviceserials.txt usersvppaccepted.xml justenrolled.xml usersvppaccepted.txt

exit 0
