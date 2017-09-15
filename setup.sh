#!/bin/bash
# ------------------------------------------------------------------
# [Michael Lee Hobbs] Centos 7 Base Setup
#          Centos 7 Setup script for new server with varios options.
# ------------------------------------------------------------------

SUBJECT=some-unique-id
VERSION=0.1.0
USAGE="Usage: command -hv args"

# --- Option processing --------------------------------------------
while getopts ":vh" optname
  do
    case "$optname" in
      "v")
        echo "Version $VERSION"
        exit 0;
        ;;
      "h")
        echo $USAGE
        exit 0;
        ;;
      "?")
        echo "Unknown option $OPTARG"
        exit 0;
        ;;
      ":")
        echo "No argument value for option $OPTARG"
        exit 0;
        ;;
      *)
        echo "Unknown error while processing options"
        exit 0;
        ;;
    esac
  done

shift $(($OPTIND - 1))

cmd=$1
param=$2
command="command_$1"

# -----------------------------------------------------------------
LOCK_FILE=/tmp/${SUBJECT}.lock

if [ -f "$LOCK_FILE" ]; then
echo "Script is already running"
exit
fi

# -----------------------------------------------------------------
trap "rm -f $LOCK_FILE" EXIT
touch $LOCK_FILE 

# -----------------------------------------------------------------
#function command_test {
#    echo "test"
#}

#function command_ping {
#    echo "ping $param"
#}

function command_base {
    yum install epel-release -y
    yum install dnf -y
    dnf install java vim wget -y
    dnf update -y
    dnf upgrade -y
}

function command_nonm {
    systemctl stop NetworkManager
    systemctl disable NetworkManager
}

function command_xentools {
    mount /dev/cdrom /mnt/
    bash /mnt/Linux/install.sh
    umount /mnt/
}

function command_updatescript {
    curl -O https://raw.githubusercontent.com/MichaelLeeHobbs/centos7base/master/setup.sh
}

function command_init-server-phase1 {
    yum install epel-release -y
    yum install dnf -y
	dnf install gcc java telnet vim nmap ntfs-3g rkhunter -y
	dnf install sssd realmd oddjob oddjob-mkhomedir adcli samba-common samba-common-tools krb5-workstation openldap-clients policycoreutils-python -y
	dnf update -y; dnf upgrade -y
	rkhunter --propupd
	systemctl stop NetworkManager
	systemctl disable NetworkManager
	# disable insecure protrocal
	sed -i 's/#\s*Protocol 2,1/Protocol 2/g' /etc/ssh/ssh_config
	# disable ssh root login
	sed -i 's/#\s*PermitRootLogin yes/PermitRootLogin no/g' /etc/ssh/sshd_config
	# add domain sudoers
	touch /etc/sudoers.d/domain
	echo '## Domain Linux Admins' >> /etc/sudoers.d/domain
	echo '%sudoers ALL=(ALL)      ALL' >> /etc/sudoers.d/domain
	echo 'run> realm join --user=administrator example.com < replacing administrator with you admin account and example.com with your domain.'
	echo 'run> ./centos7base init-server-phase2'
}


function command_init-server-phase2 {
	sed -i 's/use_fully_qualified_names\s=\sTrue/use_fully_qualified_names = False/g' /etc/sssd/sssd.conf
	sed -i 's/fallback_homedir\s=\s\/home\/%u@%d/fallback_homedir = \/home\/%u/g' /etc/sssd/sssd.conf
	systemctl restart sssd

	echo 'Test Domain/Realm Connectivity'
	echo '>id youAdminAccountName - Should give back information about your account and not: no such user'
	echo '>ssh youAdminAccountName@localhost - Should allow you to login'
	echo '>sudo whoami - Should say: root'
	echo '>exit'
	echo 'If all test pass run >./centos7base init-server-phase3'
	echo "This will kick you off if you are ssh'ed in via the root account!"
}

function command_init-server-phase3 {
	rkhunter --check
	systemctl restart sshd
}


function command_spigot {
    mkdir -p spigot
    mkdir -p spigot/plugins
    scp root@192.168.1.202:~/spigotBuild/start.sh ./spigot/start.sh
    scp root@192.168.1.202:~/spigotBuild/spigot*.jar ./spigot/
    scp root@192.168.1.202:~/plugins/LANBroadcaster.jar ./spigot/LANBroadcaster.jar
    echo "eula=true" > ./spigot/eula.txt
    firewall-cmd --add-port 25565/tcp --permanent   # minecraft port
    firewall-cmd --add-port 4445/udp --permanent    # minecraft advertisement port
    firewall-cmd --reload
}

function command_install-php71 {
	dnf remove php -yes
	rpm -Uvh https://dl.fedoraproject.org/pub/epel/epel-release-latest-7.noarch.rpm
	rpm -Uvh https://mirror.webtatic.com/yum/el7/webtatic-release.rpm
	dnf install -y mod_php71w php71w-cli php71w-common php71w-gd php71w-mbstring php71w-mcrypt php71w-mysqlnd php71w-xml
}

function command_install-java {
    curl -O https://raw.githubusercontent.com/MichaelLeeHobbs/centos7base/master/javaInstall.sh
    bash javaInstall.sh
}

# -----------------------------------------------------------------
# -----------------------------------------------------------------
if [ -n "$(type -t ${command})" ] && [ "$(type -t ${command})" = function ]; then 
   ${command}
else 
   echo "'${cmd}' is NOT a command"; 
fi

