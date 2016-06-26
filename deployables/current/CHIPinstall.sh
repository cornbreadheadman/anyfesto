#!/bin/bash

# Anyfesto Install Script for the CHIP
# CC 2016 by tomwsmf

# Upgrae your base install
sudo apt-get -y update
sudo apt-get -y upgrade

# Start installing the services
sudo apt-get -y install vlc
sudo adduser --no-create-home --shell /bin/false --disabled-password vlc
sudo usermod -G audio,chip vlc
sudo apt-get -y install lighttpd
sudo /etc/init.d/lighttpd stop
sudo update-rc.d lighttpd remove
sudo apt-get -y install dnsmasq 
sudo /etc/init.d/dnsmasq  stop
sudo update-rc.d dnsmasq remove 
sudo apt-get -y  install hostapd
sudo /etc/init.d/hostapd  stop
sudo update-rc.d hostapd remove 
sudo apt-get -y install git
sudo apt-get -y install perl sox libsox-fmt-all libav-tools
sudo rm /bin/sh
sudo ln /bin/bash /bin/sh
sudo chmod a+rw /bin/sh
mkdir /home/chip/content
mkdir /home/chip/content/Radio
sudo usermod -d /home/chip/content/Radio vlc

# Install and Config Piratebox Base
cd ~
wget  http://downloads.piratebox.de/piratebox-ws_current.tar.gz
tar xzf piratebox-ws_current.tar.gz
cd piratebox
sudo mkdir -p  /opt
sudo cp -rv  piratebox /opt
cd /opt/piratebox
sudo sed 's:DROOPY_USE_USER="no":DROOPY_USE_USER="yes":' -i  /opt/piratebox/conf/piratebox.conf
sudo ln -s /opt/piratebox/init.d/piratebox /etc/init.d/piratebox
sudo update-rc.d piratebox  defaults 


#########################
sudo ln -s /home/chip/content /opt/piratebox/share/Shared/Archives   
sudo nano /opt/piratebox/conf/piratebox.conf     #Change the following and save
      HOST="anyfestochip.lan"
      INTERFACE="wlan1"
      DNSMASQ_INTERFACE="wlan1"
      NET=10.11.99    
#########################

# Setup hostapd configs in /opt/piratebox/conf/hostapd.conf       
sudo echo "interface=wlan1" >/opt/piratebox/conf/hostapd.conf
sudo echo "driver=nl80211" >>/opt/piratebox/conf/hostapd.conf
sudo echo "ssid=AnyfestoCHIPCommunityNetworking" >>/opt/piratebox/conf/hostapd.conf
sudo echo "channel=1" >>/opt/piratebox/conf/hostapd.conf
sudo echo "ctrl_interface=/var/run/hostapd" >>/opt/piratebox/conf/hostapd.conf
      
# Setup hostapd configs in /etc/default/hostapd                  
sudo echo 'DAEMON_CONF="/opt/piratebox/conf/hostapd.conf"' >/opt/default/hostapd

# Setup allowed hosts for vlc servers in  /usr/share/vlc/lua/http/.hosts
sudo echo "::1" > /usr/share/vlc/lua/http/.hosts
sudo echo "127.0.0.1" >> /usr/share/vlc/lua/http/.hosts
sudo echo "fc00::/7" >> /usr/share/vlc/lua/http/.hosts
sudo echo "fec0::/10" >> /usr/share/vlc/lua/http/.hosts
sudo echo "10.0.0.0/8" >> /usr/share/vlc/lua/http/.hosts
sudo echo "192.0.0.0/8" >> /usr/share/vlc/lua/http/.hosts

# Setuo vlc server and put in a default file for streaming
sudo mkdir /etc/vlc 
cd /usr/share/vlc/lua/http/ 
sudo mv .hosts /etc/vlc 
sudo ln -s /etc/vlc/.hosts .hosts
cd /home/chip/content/Radio
wget https://archive.org/download/Old_Radio_Public_Service_Announcements/OldRadio_Pub--Jack_Benny_Tolerance1.mp3  -O welcome.mp3

# Create /etc/vlc/start.sh
sudo echo "#!/bin/sh  " > /etc/vlc/start.sh                        #Add the follwing and save   
sudo echo "sudo service hostapd start" >> /etc/vlc/start.sh
sudo echo "VLC_PORT=8088" >> /etc/vlc/start.sh
sudo echo "VLC_USER=vlc" >> /etc/vlc/start.sh
sudo echo "VLC_IP=10.11.99.1" >> /etc/vlc/start.sh
sudo echo "VLC_PASWD=changeme" >> /etc/vlc/start.sh    
sudo echo "sudo -u vlc cvlc -vvv -I http --http-password $VLC_PASWD  --http-host $VLC_IP --http-port $VLC_PORT  --sout-keep --sout='#duplicate{dst=rtp{mux=ts,dst=10.11.99.1:8086},dst=gather:std{access=http,mux=mpeg1,dst=:8085},dst=display,select="novideo"}'  -LZ /home/chip/content/*/./*.mp3" >> /etc/vlc/start.sh        
    
sudo chmod a+rx /etc/vlc/start.sh  
sudo nano /etc/rc.local                           #Add the follwing and save    
      /etc/vlc/start.sh &

# Get default web pages and clean up the piratebox install
sudo rm /opt/piratebox/www/index.html
sudo wget https://raw.githubusercontent.com/tomhiggins/anyfesto/master/deployables/AnyfestoCHiP-index.html -O /opt/piratebox/www/index.html
sudo wget https://raw.githubusercontent.com/tomhiggins/anyfesto/master/deployables/anyfestochiplogosm.jpg -O /opt/piratebox/www/logo.jpg
sudo rm /opt/piratebox/www/favicon.ico
sudo rm /opt/piratebox/www/Shared/HEADER.txt
sudo rm /opt/piratebox/www/Shared/README.txt

sudo /etc/init.d/piratebox start

sudo sync 
sudo reboot

----------------------------------------------------------------------------
Adding a USB Drive
----------------------------------------------------------------------------
  Connect the usb drive to the usb port
sudo mkdir /drives
sudo mount /dev/sda1 /drives
sudo nano /etc/fstab                     #Add/Change the following and save
   /dev/sda1 /drives vfat defaults 0 0
sudo mount -a                            #drive will now automount on boot. If you disconect the drive and reattach it run sudo mount -a again

Adding a Direcotry on the USB Drive to the shared file listing (these will show up uner the Files selection of the Web Page)
sudo ln -s /drives/(NameOfDirectory)/ /home/chip/content/

Example - for my test setup 
  sudo ln -s /drives/SpokenWord/ /home/chip/content/
  sudo ln -s /drives/Books/ /home/chip/content/
  sudo ln -s /drives/Audio/ /home/chip/content/


----------------------------------------------------------------------------
Optional - Add Mumble Server for secure voip and chat
----------------------------------------------------------------------------
sudo apt-get install mumble-server
sudo dpkg-reconfigure mumble-server
   Autostart:  Yes
   High Priority: No
   SuperUser: Set the admin password
sudo nano /etc/mumble-server.ini
    Find welcomeText and update to whatever you would like displayed when a user joins
    Find serverpassword and update if you would like a password for users, leave as is to  have no password for users.
sudo /etc/init.d/mumble-server restart 
# Add a link in /opt/piratebox/www/index.html to service and clients

------------------------------------------------------------------------------
Optional - Add Kiwix to serve up Wikipedia and other wikimedia sites
------------------------------------------------------------------------------
cd ~
wget https://download.kiwix.org/bin/kiwix-server-arm.tar.bz2
bzip2 -d kiwix-server-arm.tar.bz2 
tar xvf kiwix-server-arm.tar
rm kiwix-server-arm.tar
sudo cp kiwix-serve /usr/bin/kiwix-serve
sudo cp kiwix-manage /usr/bin/kiwix-manage
sudo mkdir /drives/kiwix
     # You can find a list of premade data stores at http://www.kiwix.org/wiki/Content . Use non indexed ones. 
cd /drives/kiwix
sudo wget http://download.kiwix.org/zim/wikipedia_en_for-schools.zim  # your milage may vary
# If you want to add several zims  wget them to /media/usb/kiwix and then use kiwiz-manage to create a libray file
# For each zim add it to the library
sudo kiwix-manage /drives/kiwix/library.xml /drives/kiwix/NameOfZimFile.zim 
sudo nano /etc/rc.local                                           # add the line and save
   /usr/bin/kiwix-serve --daemon --port=8099 /drives/kiwix/wikipedia_en_for-schools.zim
   # If you are using multiple zim files use this line
   /usr/bin/kiwix-serve --daemon --port=8099 --library /drives/kiwix/library.xml
sudo sync
sudo reboot
# Add a description and link  to http://YourServersIP:8099 to the captive portal landing page so users can get to the main library page
