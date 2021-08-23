#!/bin/bash

# Video Source for Raspberry Pi Zero or RPi 3
# Orignal design by Brian, G4EWJ
# Packaged for release by Dave, G8GKQ

whoami | grep -q pi
if [ $? != 0 ]; then
  echo "Install must be performed as user pi"
  exit
fi

# Check which source needs to be loaded
GIT_SRC="BritishAmateurTelevisionClub"
GIT_SRC_FILE=".vidsource_gitsrc"

if [ "$1" == "-d" ]; then
  GIT_SRC="davecrump";
  echo
  echo "-------------------------------------------------------"
  echo "----- Installing development version of VidSource -----"
  echo "-------------------------------------------------------"
elif [ "$1" == "-u" -a ! -z "$2" ]; then
  GIT_SRC="$2"
  echo
  echo "WARNING: Installing ${GIT_SRC} development version, press enter to continue or 'q' to quit."
  read -n1 -r -s key;
  if [[ $key == q ]]; then
    exit 1;
  fi
  echo "ok!";
else
  echo
  echo "-------------------------------------------------------------"
  echo "----- Installing BATC Production Portsdown of VidSource -----"
  echo "-------------------------------------------------------------"
fi

sudo mkdir /boot/testcard
echo
echo "---------------------------"
echo "----- Personalisation -----"
echo "---------------------------"

echo
echo "Please enter your callsign and press enter (it can be changed later)"
read CALL
echo and please enter the locator for $CALL and press enter
read LOCATOR

sudo sh -c "echo $CALL > /boot/testcard/callsign.txt"
sudo sh -c "echo $LOCATOR > /boot/testcard/locator.txt"
sudo sh -c "echo 0000 > /boot/testcard/numbers.txt"

echo
echo Call set to $CALL and locator set to $LOCATOR
echo "these can be changed by editing the files in /boot/testcard/"
echo
echo "The install will now continue without needing any user input"
echo "and reboot when it is finished."

# Update the package manager
echo
echo "------------------------------------"
echo "----- Updating Package Manager -----"
echo "------------------------------------"
sudo dpkg --configure -a
sudo apt-get update --allow-releaseinfo-change

# Uninstall the apt-listchanges package to allow silent install of ca certificates (201704030)
# http://unix.stackexchange.com/questions/124468/how-do-i-resolve-an-apparent-hanging-update-process
sudo apt-get -y remove apt-listchanges

# Upgrade the distribution
echo
echo "-----------------------------------"
echo "----- Performing dist-upgrade -----"
echo "-----------------------------------"
sudo apt-get -y dist-upgrade


# Install the packages that we need
echo
echo "-------------------------------"
echo "----- Installing Packages -----"
echo "-------------------------------"
sudo apt-get -y install git
sudo apt-get -y install cmake libusb-1.0-0-dev libx11-dev buffer libjpeg-dev indent
sudo apt-get -y install ttf-dejavu-core bc usbmount libfftw3-dev wiringpi libvncserver-dev
sudo apt-get -y install fbi netcat imagemagick

echo
echo "--------------------------------"
echo "----- Setting up Autostart -----"
echo "--------------------------------"

# Set auto login to command line
sudo raspi-config nonint do_boot_behaviour B2

# Modify .bashrc to run startup script on ssh logon
echo if test -z \"\$SSH_CLIENT\" >> ~/.bashrc 
echo then >> ~/.bashrc
echo "source /home/pi/vidsource/on_start.sh" >> ~/.bashrc
echo fi >> ~/.bashrc

# Amend /etc/fstab to create a tmpfs drive at ~/tmp for temporary use
sudo sed -i '4itmpfs           /home/pi/tmp    tmpfs   defaults,noatime,nosuid,size=10m  0  0' /etc/fstab

# Download the previously selected version of vidsource
echo
echo "------------------------------------------"
echo "----- Downloading VidSource Software -----"
echo "------------------------------------------"
wget https://github.com/${GIT_SRC}/vidsource/archive/main.zip

# Unzip the VidSource software and copy to the Pi
unzip -o main.zip
mv vidsource-main vidsource
rm main.zip
cd /home/pi


# Compile it here
cd /home/pi/vidsource/src
make
sudo make install
cd /home/pi

# Transfer files from /home/pi/vidsource/ to /boot/testcard/

sudo cp /home/pi/vidsource/tcdata0.txt /boot/testcard/tcdata0.txt
sudo cp /home/pi/vidsource/tcdata1.txt /boot/testcard/tcdata1.txt
sudo cp /home/pi/vidsource/tcdata2.txt /boot/testcard/tcdata2.txt
sudo cp /home/pi/vidsource/tcdata3.txt /boot/testcard/tcdata3.txt
sudo cp /home/pi/vidsource/tcdata4.txt /boot/testcard/tcdata4.txt
sudo cp /home/pi/vidsource/tcdata5.txt /boot/testcard/tcdata5.txt
sudo cp /home/pi/vidsource/tcdata6.txt /boot/testcard/tcdata6.txt
sudo cp /home/pi/vidsource/tcdata7.txt /boot/testcard/tcdata7.txt
sudo cp /home/pi/vidsource/tcdata8.txt /boot/testcard/tcdata8.txt
sudo cp /home/pi/vidsource/tcdata9.txt /boot/testcard/tcdata9.txt

sudo cp /home/pi/vidsource/11g720.jpg /boot/testcard/11g720.jpg
sudo cp /home/pi/vidsource/75cb720.jpg /boot/testcard/75cb720.jpg
sudo cp /home/pi/vidsource/pb720.jpg /boot/testcard/pb720.jpg
sudo cp /home/pi/vidsource/pm5544-720.jpg /boot/testcard/pm5544-720.jpg
sudo cp /home/pi/vidsource/tcc720.jpg /boot/testcard/tcc720.jpg
sudo cp /home/pi/vidsource/tcf640.jpg /boot/testcard/tcf640.jpg
sudo cp /home/pi/vidsource/tcf720.jpg /boot/testcard/tcf720.jpg
sudo cp /home/pi/vidsource/testcard640.jpg /boot/testcard/testcard640.jpg

sudo cp /home/pi/vidsource/camtc23a.sh /boot/testcard/camtc23a.sh

# Enable camera
echo
echo "--------------------------------------------------"
echo "---- Enabling the Pi Cam in /boot/config.txt -----"
echo "--------------------------------------------------"
sudo bash -c 'echo -e "\n##Enable Pi Camera" >> /boot/config.txt'
sudo bash -c 'echo -e "\ngpu_mem=128\nstart_x=1\n" >> /boot/config.txt'

# Reduce the dhcp client timeout to speed off-network startup (201704160)
sudo bash -c 'echo -e "\n# Shorten dhcpcd timeout from 30 to 5 secs" >> /etc/dhcpcd.conf'
sudo bash -c 'echo -e "\ntimeout 5\n" >> /etc/dhcpcd.conf'

# Enable the Video output in PAL mode
cd /boot
sudo sed -i 's/^#sdtv_mode=2/sdtv_mode=2/' config.txt
cd /home/pi

# Save git source used
echo "${GIT_SRC}" > /home/pi/${GIT_SRC_FILE}

# Add aliases to kill the test card generator after boot or to start it
echo "alias stop='sudo killall camtc23a.sh'" >> /home/pi/.bash_aliases
echo "alias start='/home/pi/vidsource/on_start.sh'" >> /home/pi/.bash_aliases

echo
echo "SD Card Serial:"
cat /sys/block/mmcblk0/device/cid

# Reboot
echo
echo "--------------------------------"
echo "----- Complete.  Rebooting -----"
echo "--------------------------------"
sleep 1
echo
echo "-------------------------------------------------------"
echo "----- The video output should be active on reboot -----"
echo "-------------------------------------------------------"

sudo reboot now
exit



