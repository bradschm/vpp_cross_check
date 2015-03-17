# vpp_cross_check
#Push apps to devices when they are ready to install silently.
#VPP Cross Check - Add Devices to Push Ready Smart Group	

Problem that this script solves: Scope your Apps you want to push to this Smart Group and the user will not see multiple prompts to install	the App at enrollment. It waits until it sees that a user has accepted the VPP invitation then it pushes the app (hopefully silently) to the device. The script looks up mobile devices that have enrolled recently and checks to see if the user associated with the device has accepted the VPP invitation. You could scope this to all devices for the first run to get previously enrolled devices. Then scope it to the mobile device smart group described in requirements. Devices that are Push Ready can have Apps scoped to them with the push command.

#Requirements
JSS Components:
Advanced user search ( Users that have associated with the VPP invitation)
Mobile Device Advanced Search ( Find iPads that just enrolled that have not been added to Push Ready Smart Group ) Extension Attribute ( Push Ready - Script updates to Yes )									                            				
Smart Group ( Push Ready - Devices where Push Ready EA is Yes )								                          						
Note: This script uses files to store data, I would like to to eventually use arrays. The files will write to the same directory this script is excuted from. It will clean up the files at the end of the script.                    

XML2 Binary
xml2 - used for xml parsing takes xml input and outputs to a path
For example - <computer><user>username</user></computer> turns into /computer/user=username
xml2 Website: http://www.ofb.net/~egnor/xml2/					                                    													
How to obtain:
Linux: sudo apt-get install xml2
Mac using Mac brew: brew install xml2											                                        									
If you don't have Homebrew on your Mac, check out: http://brew.sh		                          											
Quickest way to get Homebrew setup on your Mac: 													                                  				
Run this in terminal: ruby -e "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install)"	  	
Note: If you install xml2 with apt it will install to /usr/bin/xml2 										                        		
If you install on Mac it installs to /usr/local/opt/xml2/bin/xml2 	
