#!/bin/bash
# T-Pot Universal Installer

##################
# I. Global vars #
##################

myBACKTITLE="T-Pot-Installer"
myCONF_FILE="/root/installer/iso.conf"
myPROGRESSBOXCONF=" --backtitle "$myBACKTITLE" --progressbox 24 80"
mySITES="https://hub.docker.com https://github.com https://pypi.python.org https://debian.org"
myTPOTCOMPOSE="/opt/tpot/etc/tpot.yml"
myLSB_STABLE_SUPPORTED="stretch"
myLSB_TESTING_SUPPORTED="sid"
myREMOTESITES="https://hub.docker.com https://github.com https://pypi.python.org https://debian.org"
myPREINSTALLPACKAGES="aria2 apache2-utils curl dialog figlet grc libcrack2 libpq-dev lsb-release netselect-apt net-tools software-properties-common toilet"
myINSTALLPACKAGES="aria2 apache2-utils apparmor apt-transport-https aufs-tools bash-completion build-essential ca-certificates cgroupfs-mount cockpit cockpit-docker console-setup console-setup-linux curl debconf-utils dialog dnsutils docker.io docker-compose dstat ethtool fail2ban figlet genisoimage git glances grc haveged html2text htop iptables iw jq kbd libcrack2 libltdl7 man mosh multitail netselect-apt net-tools npm ntp openssh-server openssl pass prips software-properties-common syslinux psmisc pv python-pip toilet unattended-upgrades unzip vim wget wireless-tools wpasupplicant"
myINFO="\
########################################
### T-Pot Installer for Debian (Sid) ###
########################################

Disclaimer:
This script will install T-Pot on this system.
By running the script you know what you are doing:
1. SSH will be reconfigured to tcp/64295.
2. Your Debian installation will be upgraded to Sid / unstable.
3. Please ensure other means of access to this system in case something goes wrong.
4. At best this script will be executed on the console instead through a SSH session.

########################################

Usage:
        $0 --help - Help.

Example:
        $0 --type=user - Best option for most users."
myNETWORK_INTERFACES="
wpa-driver wired
wpa-conf /etc/wpa_supplicant/wired8021x.conf

### Example wireless config for 802.1x
### This configuration was tested with the IntelNUC series
### If problems occur you can try and change wpa-driver to \"iwlwifi\"
### Do not forget to enter a ssid in /etc/wpa_supplicant/wireless8021x.conf
### The Intel NUC uses wlpXsY notation instead of wlanX
#
#auto wlp2s0
#iface wlp2s0 inet dhcp
#        wpa-driver wext
#        wpa-conf /etc/wpa_supplicant/wireless8021x.conf
"
myNETWORK_WIRED8021x="ctrl_interface=/var/run/wpa_supplicant
ctrl_interface_group=root
eapol_version=1
ap_scan=1
network={
  key_mgmt=IEEE8021X
  eap=TLS
  identity=\"host/$myCONF_PFX_HOST_ID\"
  private_key=\"/etc/wpa_supplicant/8021x.pfx\"
  private_key_passwd=\"$myCONF_PFX_PW\"
}
"
myNETWORK_WLAN8021x="ctrl_interface=/var/run/wpa_supplicant
ctrl_interface_group=root
eapol_version=1
ap_scan=1
network={
  ssid=\"<your_ssid_here_without_brackets>\"
  key_mgmt=WPA-EAP
  pairwise=CCMP
  group=CCMP
  eap=TLS
  identity=\"host/$myCONF_PFX_HOST_ID\"
  private_key=\"/etc/wpa_supplicant/8021x.pfx\"
  private_key_passwd=\"$myCONF_PFX_PW\"
}
"
myNETWORK_WLANEXAMPLE="
### Example static ip config
### Replace <eth0> with the name of your physical interface name
#
#auto eth0
#iface eth0 inet static
# address 192.168.1.1
# netmask 255.255.255.0
# network 192.168.1.0
# broadcast 192.168.1.255
# gateway 192.168.1.1
# dns-nameservers 192.168.1.1

### Example wireless config without 802.1x
### This configuration was tested with the IntelNUC series
### If problems occur you can try and change wpa-driver to \"iwlwifi\"
#
#auto wlan0
#iface wlan0 inet dhcp
#   wpa-driver wext
#   wpa-ssid <your_ssid_here_without_brackets>
#   wpa-ap-scan 1
#   wpa-proto RSN
#   wpa-pairwise CCMP
#   wpa-group CCMP
#   wpa-key-mgmt WPA-PSK
#   wpa-psk \"<your_password_here_without_brackets>\"
"
myUPDATECHECK="APT::Periodic::Update-Package-Lists \"1\";
APT::Periodic::Download-Upgradeable-Packages \"0\";
APT::Periodic::AutocleanInterval \"7\";
"
mySYSCTLCONF="
# Reboot after kernel panic, check via /proc/sys/kernel/panic[_on_oops]
# Set required map count for ELK
kernel.panic = 1
kernel.panic_on_oops = 1
vm.max_map_count = 262144
# Remove IPv6 disablement as it stops T-Pot from working on AWS (needs ipv6)
# net.ipv6.conf.all.disable_ipv6 = 1
# net.ipv6.conf.default.disable_ipv6 = 1
# net.ipv6.conf.lo.disable_ipv6 = 1
"
myFAIL2BANCONF="[DEFAULT]
ignore-ip = 127.0.0.1/8
bantime = 3600
findtime = 600
maxretry = 5

[nginx-http-auth]
enabled  = true
filter   = nginx-http-auth
port     = 64297
logpath  = /data/nginx/log/error.log

[pam-generic]
enabled = true
port    = 64294
filter  = pam-generic
logpath = /var/log/auth.log

[sshd]
enabled = true
port    = 64295
filter  = sshd
logpath = /var/log/auth.log
"
mySYSTEMDFIX="[Link]
NamePolicy=kernel database onboard slot path
MACAddressPolicy=none
"
myCOCKPIT_SOCKET="[Socket]
ListenStream=
ListenStream=64294
"
mySSHPORT="
Port 64295
"
myCRONJOBS="
# Check if updated images are available and download them
27 1 * * *      root    docker-compose -f /opt/tpot/etc/tpot.yml pull

# Delete elasticsearch logstash indices older than 90 days
27 4 * * *      root    curator --config /opt/tpot/etc/curator/curator.yml /opt/tpot/etc/curator/actions.yml

# Uploaded binaries are not supposed to be downloaded
*/1 * * * *     root    mv --backup=numbered /data/dionaea/roots/ftp/* /data/dionaea/binaries/

# Daily reboot
27 3 * * *      root    systemctl stop tpot && docker stop \$(docker ps -aq) || docker rm \$(docker ps -aq) || reboot

# Check for updated packages every sunday, upgrade and reboot
27 16 * * 0     root    apt-fast autoclean -y && apt-fast autoremove -y && apt-fast update -y && apt-fast upgrade -y && sleep 10 && reboot
"
myROOTPROMPT='PS1="\[\033[38;5;8m\][\[$(tput sgr0)\]\[\033[38;5;1m\]\u\[$(tput sgr0)\]\[\033[38;5;6m\]@\[$(tput sgr0)\]\[\033[38;5;4m\]\h\[$(tput sgr0)\]\[\033[38;5;6m\]:\[$(tput sgr0)\]\[\033[38;5;5m\]\w\[$(tput sgr0)\]\[\033[38;5;8m\]]\[$(tput sgr0)\]\[\033[38;5;1m\]\\$\[$(tput sgr0)\]\[\033[38;5;15m\] \[$(tput sgr0)\]"'
myUSERPROMPT='PS1="\[\033[38;5;8m\][\[$(tput sgr0)\]\[\033[38;5;2m\]\u\[$(tput sgr0)\]\[\033[38;5;6m\]@\[$(tput sgr0)\]\[\033[38;5;4m\]\h\[$(tput sgr0)\]\[\033[38;5;6m\]:\[$(tput sgr0)\]\[\033[38;5;5m\]\w\[$(tput sgr0)\]\[\033[38;5;8m\]]\[$(tput sgr0)\]\[\033[38;5;2m\]\\$\[$(tput sgr0)\]\[\033[38;5;15m\] \[$(tput sgr0)\]"'
myROOTCOLORS="export LS_OPTIONS='--color=auto'
eval \"\`dircolors\`\"
alias ls='ls \$LS_OPTIONS'
alias ll='ls \$LS_OPTIONS -l'
alias l='ls \$LS_OPTIONS -lA'"


#################
# II. Functions #
#################

# Create banners
function fuBANNER {
  toilet -f ivrit "$1"
}

# Create funny words for hostnames
function fuRANDOMWORD {
  local myWORDFILE="$1"
  local myLINES=$(cat $myWORDFILE | wc -l)
  local myRANDOM=$((RANDOM % $myLINES))
  local myNUM=$((myRANDOM * myRANDOM % $myLINES + 1))
  echo -n $(sed -n "$myNUM p" $myWORDFILE | tr -d \' | tr A-Z a-z)
}

# Do we have root?
function fuGOT_ROOT {
echo
echo -n "### Checking for root: "
if [ "$(whoami)" != "root" ];
  then
    echo "[ NOT OK ]"
    echo "### Please run as root."
    echo "### Example: sudo $0"
    exit
  else
    echo "[ OK ]"
fi
}

# Check for pre-installer package requirements.
# If not present install them
function fuCHECKPACKAGES {
  export DEBIAN_FRONTEND=noninteractive
  # Make sure dependencies for apt-fast are installed
  myCURL=$(which curl)
  myWGET=$(which wget)
  if [ "$myCURL" == "" ] || [ "$myWGET" == "" ]
    then
      echo "### Installing deps for apt-fast"
      apt-get -y update
      apt-get -y install curl wget
  fi
  echo "### Installing apt-fast"
  /bin/bash -c "$(curl -sL https://raw.githubusercontent.com/ilikenwf/apt-fast/master/quick-install.sh)"
  echo -n "### Checking for installer dependencies: "
  local myPACKAGES="$1"
  for myDEPS in $myPACKAGES;
    do
      myOK=$(dpkg -s $myDEPS 2>&1 | grep -w ok | awk '{ print $3 }' | head -n 1)
      if [ "$myOK" != "ok" ];
        then
          echo "[ NOW INSTALLING ]"
          apt-fast update -y
          apt-fast install -y $myPACKAGES
          break
      fi
  done
  if [ "$myOK" = "ok" ];
    then
      echo "[ OK ]"
  fi
}

# Check if remote sites are available
function fuCHECKNET {
  if [ "$myTPOT_DEPLOYMENT_TYPE" == "iso" ] || [ "$myTPOT_DEPLOYMENT_TYPE" == "user" ];
    then
      local mySITES="$1"
      mySITESCOUNT=$(echo $mySITES | wc -w)
      j=0
      for i in $mySITES;
        do
          echo $(expr 100 \* $j / $mySITESCOUNT) | dialog --title "[ Availability check ]" --backtitle "$myBACKTITLE" --gauge "\n  Now checking: $i\n" 8 80
          curl --connect-timeout 30 -IsS $i 2>&1>/dev/null
          if [ $? -ne 0 ];
            then
              dialog --keep-window --backtitle "$myBACKTITLE" --title "[ Continue? ]" --yesno "\nAvailability check failed. You can continue, but the installation might fail." 10 50
              if [ $? = 1 ];
                then
                  dialog --keep-window --backtitle "$myBACKTITLE" --title "[ Abort ]" --msgbox "\nInstallation aborted. Exiting the installer." 7 50
                  exit
                else
                  break;
              fi;
          fi;
        let j+=1
        echo $(expr 100 \* $j / $mySITESCOUNT) | dialog --keep-window --title "[ Availability check ]" --backtitle "$myBACKTITLE" --gauge "\n  Now checking: $i\n" 8 80
      done;
  fi
}

# Install T-Pot dependencies
function fuGET_DEPS {
  export DEBIAN_FRONTEND=noninteractive
#  # Determine fastest mirror
#  echo
#  echo "### Determine fastest mirror for your location."
#  echo
#  netselect-apt -n -a amd64 unstable && cp sources.list /etc/apt/
#  mySOURCESCHECK=$(cat /etc/apt/sources.list | grep -c unstable)
#  if [ "$mySOURCESCHECK" == "0" ]
#    then
#      echo "### Automatic mirror selection failed, using main mirror."
# Point to Debian (Sid, unstable)
tee /etc/apt/sources.list <<EOF
deb http://deb.debian.org/debian unstable main contrib non-free
deb-src http://deb.debian.org/debian unstable main contrib non-free
EOF
#  fi
  echo
  echo "### Getting update information."
  echo
  apt-fast -y update
  echo
  echo "### Upgrading packages."
  echo
  # Downlaod and upgrade packages, but silently keep existing configs
  echo "docker.io docker.io/restart       boolean true" | debconf-set-selections -v
  echo "debconf debconf/frontend select noninteractive" | debconf-set-selections -v
  apt-fast -y dist-upgrade -o Dpkg::Options::="--force-confdef" -o Dpkg::Options::="--force-confold" --force-yes
  echo
  echo "### Installing T-Pot dependencies."
  echo
  apt-fast -y install $myINSTALLPACKAGES
  # Remove exim4
  apt-fast -y purge exim4-base mailutils
  apt-fast -y autoremove
  apt-mark hold exim4-base mailutils
}

# Check for other services
function fuCHECK_PORTS {
if [ "$myTPOT_DEPLOYMENT_TYPE" == "user" ];
  then
    echo
    echo "### Checking for active services."
    echo
    grc netstat -tulpen
    echo
    echo "### Please review your running services."
    echo "### We will take care of SSH (22), but other services i.e. FTP (21), TELNET (23), SMTP (25), HTTP (80), HTTPS (443), etc."
    echo "### might collide with T-Pot's honeypots and prevent T-Pot from starting successfully."
    echo
    while [ 1 != 2 ]
      do
        read -s -n 1 -p "Continue [y/n]? " mySELECT
	echo
        case "$mySELECT" in
          [y,Y])
            break
            ;;
          [n,N])
            exit
            ;;
        esac
      done
fi
}

############################
# III. Pre-Installer phase #
############################
fuGOT_ROOT
fuCHECKPACKAGES "$myPREINSTALLPACKAGES"

#####################################
# IV. Prepare installer environment #
#####################################

# Check for Debian release and extract command line arguments
myLSB=$(lsb_release -c | awk '{ print $2 }')
if [ "$myLSB" != "$myLSB_STABLE_SUPPORTED" ] && [ "$myLSB" != "$myLSB_TESTING_SUPPORTED" ];
  then
    echo "Aborting. Debian $myLSB is not supported."
    exit
fi
if [ "$1" == "" ];
  then
    echo "$myINFO"
    exit
fi
for i in "$@"
  do
    case $i in
      --conf=*)
        myTPOT_CONF_FILE="${i#*=}"
        shift
      ;;
      --type=user)
        myTPOT_DEPLOYMENT_TYPE="${i#*=}"
        shift
      ;;
      --type=auto)
        myTPOT_DEPLOYMENT_TYPE="${i#*=}"
        shift
      ;;
      --type=iso)
        myTPOT_DEPLOYMENT_TYPE="${i#*=}"
        shift
      ;;
      --help)
        echo "Usage: $0 <options>"
        echo
        echo "--conf=<Path to \"tpot.conf\">"
	echo "  Use this if you want to automatically deploy a T-Pot instance (--type=auto implied)."
        echo "  A configuration example is available in \"tpotce/iso/installer/tpot.conf.dist\"."
        echo
        echo "--type=<[user, auto, iso]>"
	echo "  user, use this if you want to manually install a T-Pot on a Debian (testing) machine."
        echo "  auto, implied if a configuration file is passed as an argument for automatic deployment."
        echo "  iso, use this if you are a T-Pot developer and want to install a T-Pot from a pre-compiled iso."
        echo
	exit
      ;;
      *)
        echo "$myINFO"
	exit
      ;;
    esac
  done

# Validate command line arguments and load config
# If a valid config file exists, set deployment type to "auto" and load the configuration
if [ "$myTPOT_DEPLOYMENT_TYPE" == "auto" ] && [ "$myTPOT_CONF_FILE" == "" ];
  then
    echo "Aborting. No configuration file given."
    exit
fi
if [ -s "$myTPOT_CONF_FILE" ] && [ "$myTPOT_CONF_FILE" != "" ];
  then
    myTPOT_DEPLOYMENT_TYPE="auto"
    if [ "$(head -n 1 $myTPOT_CONF_FILE | grep -c "# tpot")" == "1" ];
      then
        source "$myTPOT_CONF_FILE"
      else
	echo "Aborting. Config file \"$myTPOT_CONF_FILE\" not a T-Pot configuration file."
        exit
      fi
  elif ! [ -s "$myTPOT_CONF_FILE" ] && [ "$myTPOT_CONF_FILE" != "" ];
    then
      echo "Aborting. Config file \"$myTPOT_CONF_FILE\" not found."
      exit
fi

# Prepare running the installer
echo "$myINFO" | head -n 3
fuCHECK_PORTS


#######################################
# V. Installer user interaction phase #
#######################################

# Set TERM
export TERM=linux

# If this is a ISO installation we need to wait a few seconds to avoid interference with service messages
if [ "$myTPOT_DEPLOYMENT_TYPE" == "iso" ];
  then
    sleep 5
    dialog --keep-window --no-ok --no-cancel --backtitle "$myBACKTITLE" --title "[ Wait to avoid interference with service messages ]" --pause "" 6 80 7
fi

# Check if remote sites are available
fuCHECKNET "$myREMOTESITES"

# Let' s load the iso config file if there is one
if [ -f $myCONF_FILE ];
  then
    dialog --keep-window --backtitle "$myBACKTITLE" --title "[ Found personalized iso.config ]" --msgbox "\nYour personalized settings will be applied!" 7 47
    source $myCONF_FILE
  else
    # dialog logic considers 1=false, 0=true
    myCONF_PROXY_USE="1"
    myCONF_PFX_USE="1"
    myCONF_NTP_USE="1"
fi

### <--- Begin proxy setup
# If a proxy is set in iso.conf it needs to be setup.
# However, none of the other installation types will automatically take care of a proxy.
# Please open a feature request if you think this is something worth considering.
myPROXY="http://$myCONF_PROXY_IP:$myCONF_PROXY_PORT"
myPROXY_ENV="export http_proxy=$myPROXY
export https_proxy=$myPROXY
export HTTP_PROXY=$myPROXY
export HTTPS_PROXY=$myPROXY
export no_proxy=localhost,127.0.0.1,.sock
"
myPROXY_APT="Acquire::http::Proxy \"$myPROXY\";
Acquire::https::Proxy \"$myPROXY\";
"
myPROXY_DOCKER="http_proxy=$myPROXY
https_proxy=$myPROXY
HTTP_PROXY=$myPROXY
HTTPS_PROXY=$myPROXY
no_proxy=localhost,127.0.0.1,.sock
"

if [ "$myCONF_PROXY_USE" == "0" ];
  then
    # Let's setup proxy for the environment
    echo "$myPROXY_ENV" 2>&1 | tee -a /etc/environment | dialog --keep-window --title "[ Setting up the proxy ]" $myPROGRESSBOXCONF
    source /etc/environment

    # Let's setup the proxy for apt
    echo "$myPROXY_APT" 2>&1 | tee /etc/apt/apt.conf | dialog --keep-window --title "[ Setting up the proxy ]" $myPROGRESSBOXCONF

    # Let's add proxy settings to docker defaults
    echo "$myPROXY_DOCKER" 2>&1 | tee -a /etc/default/docker | dialog --keep-window --title "[ Setting up the proxy ]" $myPROGRESSBOXCONF

    # Let's restart docker for proxy changes to take effect
    systemctl stop docker 2>&1 | dialog --keep-window --title "[ Stop docker service ]" $myPROGRESSBOXCONF
    systemctl start docker 2>&1 | dialog --keep-window --title "[ Start docker service ]" $myPROGRESSBOXCONF
fi
### ---> End proxy setup

# Let's ask the user for install flavor
if [ "$myTPOT_DEPLOYMENT_TYPE" == "iso" ] || [ "$myTPOT_DEPLOYMENT_TYPE" == "user" ];
  then
    myCONF_TPOT_FLAVOR=$(dialog --keep-window --no-cancel --backtitle "$myBACKTITLE" --title "[ Choose Your T-Pot NG Edition ]" --menu \
    "\nRequired: 6GB RAM, 128GB SSD\nRecommended: 8GB RAM, 256GB SSD" 14 70 6 \
    "STANDARD" "Honeypots, ELK, NSM & Tools" \
    "SENSOR" "Just Honeypots, EWS Poster & NSM" \
    "INDUSTRIAL" "Conpot, RDPY, Vnclowpot, ELK, NSM & Tools" \
    "COLLECTOR" "Heralding, ELK, NSM & Tools" \
    "NEXTGEN" "NextGen (Glutton, HoneyPy)" 3>&1 1>&2 2>&3 3>&-)
fi

# Let's ask for a secure tsec password if installation type is iso
if [ "$myTPOT_DEPLOYMENT_TYPE" == "iso" ];
  then
    myCONF_TPOT_USER="tsec"
    myPASS1="pass1"
    myPASS2="pass2"
    mySECURE="0"
    while [ "$myPASS1" != "$myPASS2"  ] && [ "$mySECURE" == "0" ]
      do
        while [ "$myPASS1" == "pass1"  ] || [ "$myPASS1" == "" ]
          do
            myPASS1=$(dialog --keep-window --insecure --backtitle "$myBACKTITLE" \
                             --title "[ Enter password for console user (tsec) ]" \
                             --passwordbox "\nPassword" 9 60 3>&1 1>&2 2>&3 3>&-)
          done
            myPASS2=$(dialog --keep-window --insecure --backtitle "$myBACKTITLE" \
                             --title "[ Repeat password for console user (tsec) ]" \
                             --passwordbox "\nPassword" 9 60 3>&1 1>&2 2>&3 3>&-)
        if [ "$myPASS1" != "$myPASS2" ];
          then
            dialog --keep-window --backtitle "$myBACKTITLE" --title "[ Passwords do not match. ]" \
                   --msgbox "\nPlease re-enter your password." 7 60
            myPASS1="pass1"
            myPASS2="pass2"
        fi
        mySECURE=$(printf "%s" "$myPASS1" | cracklib-check | grep -c "OK")
        if [ "$mySECURE" == "0" ] && [ "$myPASS1" == "$myPASS2" ];
          then
            dialog --keep-window --backtitle "$myBACKTITLE" --title "[ Password is not secure ]" --defaultno --yesno "\nKeep insecure password?" 7 50
            myOK=$?
            if [ "$myOK" == "1" ];
              then
                myPASS1="pass1"
                myPASS2="pass2"
            fi
        fi
      done
    printf "%s" "$myCONF_TPOT_USER:$myPASS1" | chpasswd
fi

# Let's ask for web user credentials if deployment type is iso or user
# In case of auto, credentials are created from config values
# Skip this step entirely if SENSOR flavor
if [ "$myTPOT_DEPLOYMENT_TYPE" == "iso" ] || [ "$myTPOT_DEPLOYMENT_TYPE" == "user" ];
  then
    myOK="1"
    myCONF_WEB_USER="webuser"
    myCONF_WEB_PW="pass1"
    myCONF_WEB_PW2="pass2"
    mySECURE="0"
    while [ 1 != 2 ]
      do
        myCONF_WEB_USER=$(dialog --keep-window --backtitle "$myBACKTITLE" --title "[ Enter your web user name ]" --inputbox "\nUsername (tsec not allowed)" 9 50 3>&1 1>&2 2>&3 3>&-)
        myCONF_WEB_USER=$(echo $myCONF_WEB_USER | tr -cd "[:alnum:]_.-")
        dialog --keep-window --backtitle "$myBACKTITLE" --title "[ Your username is ]" --yesno "\n$myCONF_WEB_USER" 7 50
        myOK=$?
        if [ "$myOK" = "0" ] && [ "$myCONF_WEB_USER" != "tsec" ] && [ "$myCONF_WEB_USER" != "" ];
          then
            break
        fi
      done
    while [ "$myCONF_WEB_PW" != "$myCONF_WEB_PW2"  ] && [ "$mySECURE" == "0" ]
      do
        while [ "$myCONF_WEB_PW" == "pass1"  ] || [ "$myCONF_WEB_PW" == "" ]
          do
            myCONF_WEB_PW=$(dialog --keep-window --insecure --backtitle "$myBACKTITLE" \
                             --title "[ Enter password for your web user ]" \
                             --passwordbox "\nPassword" 9 60 3>&1 1>&2 2>&3 3>&-)
          done
        myCONF_WEB_PW2=$(dialog --keep-window --insecure --backtitle "$myBACKTITLE" \
                         --title "[ Repeat password for your web user ]" \
                         --passwordbox "\nPassword" 9 60 3>&1 1>&2 2>&3 3>&-)
        if [ "$myCONF_WEB_PW" != "$myCONF_WEB_PW2" ];
          then
            dialog --keep-window --backtitle "$myBACKTITLE" --title "[ Passwords do not match. ]" \
                   --msgbox "\nPlease re-enter your password." 7 60
            myCONF_WEB_PW="pass1"
            myCONF_WEB_PW2="pass2"
        fi
        mySECURE=$(printf "%s" "$myCONF_WEB_PW" | cracklib-check | grep -c "OK")
        if [ "$mySECURE" == "0" ] && [ "$myCONF_WEB_PW" == "$myCONF_WEB_PW2" ];
          then
            dialog --keep-window --backtitle "$myBACKTITLE" --title "[ Password is not secure ]" --defaultno --yesno "\nKeep insecure password?" 7 50
            myOK=$?
            if [ "$myOK" == "1" ];
              then
                myCONF_WEB_PW="pass1"
                myCONF_WEB_PW2="pass2"
            fi
        fi
      done
fi

dialog --clear

##########################
# VI. Installation phase #
##########################

exec 2> >(tee "/install.err")
exec > >(tee "/install.log")

fuBANNER "Installing ..."

fuGET_DEPS

# If flavor is SENSOR do not write credentials
if ! [ "$myCONF_TPOT_FLAVOR" == "SENSOR" ];
  then
    fuBANNER "Webuser creds"
    mkdir -p /data/nginx/conf
    htpasswd -b -c /data/nginx/conf/nginxpasswd "$myCONF_WEB_USER" "$myCONF_WEB_PW"
    echo
fi

# Let's generate a SSL self-signed certificate without interaction (browsers will see it invalid anyway)
if ! [ "$myCONF_TPOT_FLAVOR" == "SENSOR" ];
then
  fuBANNER "NGINX Certificate"
  mkdir -p /data/nginx/cert
  openssl req \
          -nodes \
          -x509 \
          -sha512 \
          -newkey rsa:8192 \
          -keyout "/data/nginx/cert/nginx.key" \
          -out "/data/nginx/cert/nginx.crt" \
          -days 3650 \
          -subj '/C=AU/ST=Some-State/O=Internet Widgits Pty Ltd'
fi

# Let's setup the ntp server
if [ "$myCONF_NTP_USE" == "0" ];
  then
    fuBANNER "Setup NTP"
    cp $myCONF_NTP_CONF_FILE /etc/ntp.conf
fi

# Let's setup 802.1x networking
if [ "myCONF_PFX_USE" == "0" ];
  then
    fuBANNER "Setup 802.1x"
    cp $myCONF_PFX_FILE /etc/wpa_supplicant/
    echo "$myNETWORK_INTERFACES" | tee -a /etc/network/interfaces
    echo "$myNETWORK_WIRED8021x" | tee /etc/wpa_supplicant/wired8021x.conf
    echo "$myNETWORK_WLAN8021x" | tee /etc/wpa_supplicant/wireless8021x.conf
fi

# Let's provide a wireless example config ...
fuBANNER "Example config"
echo "$myNETWORK_WLANEXAMPLE" | tee -a /etc/network/interfaces

# Let's make sure SSH roaming is turned off (CVE-2016-0777, CVE-2016-0778)
fuBANNER "SSH roaming off"
echo "UseRoaming no" | tee -a /etc/ssh/ssh_config

# Installing elasticdump, yq
fuBANNER "Installing pkgs"
npm install https://github.com/taskrabbit/elasticsearch-dump -g
pip install --upgrade pip
hash -r
pip install elasticsearch-curator yq

# Cloning T-Pot from GitHub
fuBANNER "Cloning T-Pot"
#git clone https://github.com/dtag-dev-sec/tpotce /opt/tpot
git clone https://github.com/apmoreno/T-Pot /opt/tpot


# Let's create the T-Pot user
fuBANNER "Create user"
addgroup --gid 2000 tpot
adduser --system --no-create-home --uid 2000 --disabled-password --disabled-login --gid 2000 tpot

# Let's set the hostname
a=$(fuRANDOMWORD /opt/tpot/host/usr/share/dict/a.txt)
n=$(fuRANDOMWORD /opt/tpot/host/usr/share/dict/n.txt)
myHOST=$a$n
fuBANNER "Set hostname"
hostnamectl set-hostname $myHOST
sed -i 's#127.0.1.1.*#127.0.1.1\t'"$myHOST"'#g' /etc/hosts

# Prevent cloud-init from overwriting our new hostname
if [ -f '/etc/cloud/cloud.cfg' ]; then
    sed -i 's/preserve_hostname.*/preserve_hostname: true/g' /etc/cloud/cloud.cfg
fi

# Let's patch cockpit.socket, sshd_config
fuBANNER "Adjust ports"
mkdir -p /etc/systemd/system/cockpit.socket.d
echo "$myCOCKPIT_SOCKET" | tee /etc/systemd/system/cockpit.socket.d/listen.conf
sed -i '/^port/Id' /etc/ssh/sshd_config
echo "$mySSHPORT" | tee -a /etc/ssh/sshd_config

# Do not allow root login for cockpit
sed -i '2i\auth requisite pam_succeed_if.so uid >= 1000' /etc/pam.d/cockpit

# Let's make sure only myCONF_TPOT_FLAVOR images will be downloaded and started
case $myCONF_TPOT_FLAVOR in
  STANDARD)
    fuBANNER "STANDARD"
    ln -s /opt/tpot/etc/compose/standard.yml $myTPOTCOMPOSE
  ;;
  SENSOR)
    fuBANNER "SENSOR"
    ln -s /opt/tpot/etc/compose/sensor.yml $myTPOTCOMPOSE
  ;;
  INDUSTRIAL)
    fuBANNER "INDUSTRIAL"
    ln -s /opt/tpot/etc/compose/industrial.yml $myTPOTCOMPOSE
  ;;
  COLLECTOR)
    fuBANNER "COLLECTOR"
    ln -s /opt/tpot/etc/compose/collector.yml $myTPOTCOMPOSE
  ;;
  NEXTGEN)
    fuBANNER "NEXTGEN"
    ln -s /opt/tpot/etc/compose/nextgen.yml $myTPOTCOMPOSE
  ;;
esac

# Let's load docker images in parallel
function fuPULLIMAGES {
for name in $(cat $myTPOTCOMPOSE | grep -v '#' | grep image | cut -d'"' -f2 | uniq)
  do
    docker pull $name &
done
wait
}
fuBANNER "Pull images"
fuPULLIMAGES

# Let's add the daily update check with a weekly clean interval
fuBANNER "Modify checks"
echo "$myUPDATECHECK" | tee /etc/apt/apt.conf.d/10periodic

# Let's make sure to reboot the system after a kernel panic
fuBANNER "Tweak sysctl"
echo "$mySYSCTLCONF" | tee -a /etc/sysctl.conf

# Let's setup fail2ban config
fuBANNER "Setup fail2ban"
echo "$myFAIL2BANCONF" | tee /etc/fail2ban/jail.d/tpot.conf

# Fix systemd error https://github.com/systemd/systemd/issues/3374
fuBANNER "Systemd fix"
echo "$mySYSTEMDFIX" | tee /etc/systemd/network/99-default.link

# Let's add some cronjobs
fuBANNER "Add cronjobs"
echo "$myCRONJOBS" | tee -a /etc/crontab

# Let's create some files and folders
fuBANNER "Files & folders"
mkdir -p /data/adbhoney/downloads /data/adbhoney/log \
         /data/ciscoasa/log \
      	 /data/conpot/log \
         /data/cowrie/log/tty/ /data/cowrie/downloads/ /data/cowrie/keys/ /data/cowrie/misc/ \
         /data/dionaea/log /data/dionaea/bistreams /data/dionaea/binaries /data/dionaea/rtp /data/dionaea/roots/ftp /data/dionaea/roots/tftp /data/dionaea/roots/www /data/dionaea/roots/upnp \
         /data/elasticpot/log \
         /data/elk/data /data/elk/log \
	 /data/fatt/log \
         /data/honeytrap/log/ /data/honeytrap/attacks/ /data/honeytrap/downloads/ \
         /data/glutton/log \
         /data/heralding/log \
         /data/honeypy/log \
         /data/mailoney/log \
         /data/medpot/log \
         /data/nginx/log \
         /data/emobility/log \
         /data/ews/conf \
         /data/rdpy/log \
         /data/spiderfoot \
         /data/suricata/log /home/tsec/.ssh/ \
      	 /data/tanner/log /data/tanner/files \
         /data/p0f/log
touch /data/spiderfoot/spiderfoot.db
touch /data/nginx/log/error.log

# Let's copy some files
fuBANNER "Copy configs"
tar xvfz /opt/tpot/etc/objects/elkbase.tgz -C /
cp /opt/tpot/host/etc/systemd/* /etc/systemd/system/
systemctl enable tpot

# Let's take care of some files and permissions
fuBANNER "Permissions"
chmod 770 -R /data
if [ "$myTPOT_DEPLOYMENT_TYPE" == "iso" ];
  then
    usermod -a -G tpot tsec
  else
    usermod -a -G tpot $(who am i | awk '{ print $1 }')
fi
chown tpot:tpot -R /data
chown tsec:tsec -R /home/tsec/.ssh
chmod 644 -R /data/nginx/conf
chmod 644 -R /data/nginx/cert

# Let's replace "quiet splash" options, set a console font for more screen canvas and update grub
fuBANNER "Options"
sed -i 's#GRUB_CMDLINE_LINUX_DEFAULT="quiet"#GRUB_CMDLINE_LINUX_DEFAULT="quiet consoleblank=0"#' /etc/default/grub
sed -i 's#GRUB_CMDLINE_LINUX=""#GRUB_CMDLINE_LINUX="cgroup_enable=memory swapaccount=1"#' /etc/default/grub
update-grub

fuBANNER "Setup console"
cp /usr/share/consolefonts/Uni2-Terminus12x6.psf.gz /etc/console-setup/
gunzip /etc/console-setup/Uni2-Terminus12x6.psf.gz
sed -i 's#FONTFACE=".*#FONTFACE="Terminus"#' /etc/default/console-setup
sed -i 's#FONTSIZE=".*#FONTSIZE="12x6"#' /etc/default/console-setup
update-initramfs -u
sed -i 's#After=.*#After=systemd-tmpfiles-setup.service console-screen.service kbd.service local-fs.target#' /etc/systemd/system/multi-user.target.wants/console-setup.service

# Let's enable a color prompt and add /opt/tpot/bin to path
fuBANNER "Setup prompt"
tee -a /root/.bashrc <<EOF
$myROOTPROMPT
$myROOTCOLORS
PATH="$PATH:/opt/tpot/bin"
EOF
for i in $(ls -d /home/*/)
  do
tee -a $i.bashrc <<EOF
$myUSERPROMPT
PATH="$PATH:/opt/tpot/bin"
EOF
done

# Let's create ews.ip before reboot and prevent race condition for first start
fuBANNER "Update IP"
/opt/tpot/bin/updateip.sh

# Let's clean up apt
fuBANNER "Clean up"
apt-fast autoclean -y
apt-fast autoremove -y

# Final steps
cp /opt/tpot/host/etc/rc.local /etc/rc.local && \
rm -rf /root/installer && \
rm -rf /etc/issue.d/cockpit.issue && \
rm -rf /etc/motd.d/cockpit && \
rm -rf /etc/issue.net && \
rm -rf /etc/motd && \
systemctl restart console-setup.service

if [ "$myTPOT_DEPLOYMENT_TYPE" == "auto" ];
  then
    echo "Done. Please reboot."
  else
    fuBANNER "Rebooting ..."
    sleep 2
    reboot
fi
