Overview:

	This is a shell script to create an onion router for your Raspberry Pi with a USB Ethernet
	adapter from a stock Moebius Linux image.  This will allow you to plug your Pi directly into
	your network and force all TCP traffic to be directed through tor, and force all UDP traffic to
	be dropped.

	This script performs the following operations:

		-Uninstalls the dropbear ssh server
		-Upgrades all installed packages
		-Installs and configures tor
		-Forces all TCP traffic to go through the tor network using iptables
		-Drops all UDP traffic, except DNS requests which go through tor using iptables
		-Sets the root file-system to read-only to help prevent SD card issues

What You Need:

	1. A Raspberry Pi
	2. A USB ethernet adapter compatible with the Raspberry Pi
	3. An SD card with size of at least 1 GB
	4. A stock Moebius Linux Image (from here: http://moebiuslinux.sourceforge.net/ )

Directions:

	1. Flash an SD card with a stock Moebius Linux Image (directions can be found here:
	http://moebiuslinux.sourceforge.net/documentation/installation-guide/ )
	
	2. Plug your ethernet cable to the internet into your Pi's onboard NIC.  Plug your ethernet 
	cable to your internal network into your USB NIC.  Your network cables should be in this 
	configuration:
		
		[Internet]---[Raspberry Pi]---[USB Ethernet Dongle]---[Internal Network]

	3. Boot up your Pi and login ( username: root password: raspi )
	4. Change root's default password:

		# passwd

	5. Download the setup script to your Pi:

		# wget https://raw.githubusercontent.com/blufro93/inline-onion-pi/master/setup-onion-pi.sh

	6. Run the setup script:

		# sh setup-onion-pi.sh

	7. Wait until reboot!

	With your Raspberry Pi set up this way, all traffic behind your Raspbery Pi which goes
	through the USB ethernet adapter will be either forced through tor or blocked.