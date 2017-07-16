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

function command_spigot {
    scp root@192.168.1.202:~/spigotBuild/start.sh start.sh
    scp root@192.168.1.202:~/spigotBuild/spigot*.jar
    echo "eula=true" > eula.txt
}

# -----------------------------------------------------------------
# -----------------------------------------------------------------
if [ -n "$(type -t ${command})" ] && [ "$(type -t ${command})" = function ]; then 
   ${command}
else 
   echo "'${cmd}' is NOT a command"; 
fi

