#!/bin/bash

# You must accept the Oracle Binary Code License
# http://www.oracle.com/technetwork/java/javase/terms/license/index.html
# usage: get_jdk.sh <ext> <jdk_version>
# ext: rpm
# jdk_version: default 8

ext=rpm
jdk_version=8
regex="jdk-${jdk_version}u(.*)-linux"

if [ -n "$1" ]; then
    if [ "$1" == "tar" ]; then
        ext="tar.gz"
    fi
fi

readonly url="http://www.oracle.com"
readonly jdk_download_url1="$url/technetwork/java/javase/downloads/index.html"
readonly jdk_download_url2=$(curl -s $jdk_download_url1 | egrep -o "\/technetwork\/java/\javase\/downloads\/jdk${jdk_version}-downloads-.+?\.html" | head -1 | cut -d '"' -f 1)
[[ -z "$jdk_download_url2" ]] && error "Could not get jdk download url - $jdk_download_url1"

readonly jdk_download_url3="${url}${jdk_download_url2}"
readonly jdk_download_url4=$(curl -s $jdk_download_url3 | egrep -o "http\:\/\/download.oracle\.com\/otn-pub\/java\/jdk\/[7-8]u[0-9]+\-(.*)+\/jdk-[7-8]u[0-9]+(.*)linux-x64.$ext")

for dl_url in ${jdk_download_url4[@]}; do
    if [[ ${dl_url} =~ $regex ]]
    then
        rel="${BASH_REMATCH[1]}"
        echo "Release = ${rel}"
    fi
    wget --no-cookies \
         --no-check-certificate \
         --header "Cookie: oraclelicense=accept-securebackup-cookie" \
         -N $dl_url
done

dnf install jdk-${jdk_version}u${rel}-linux-x64.rpm -y

rm -rf /var/lib/alternatives/java
alternatives --install /usr/bin/java java /usr/java/jdk1.$jdk_version.0_$rel/jre/bin/java 20000
alternatives --set java /usr/java/jdk1.$jdk_version.0_$rel/jre/bin/java

rm -rf /var/lib/alternatives/javaws
alternatives --install /usr/bin/javaws javaws /usr/java/jdk1.$jdk_version.0_$rel/jre/bin/javaws 20000
alternatives --set javaws /usr/java/jdk1.$jdk_version.0_$rel/jre/bin/javaws

rm -rf /var/lib/alternatives/javac
alternatives --install /usr/bin/javac javac /usr/java/jdk1.$jdk_version.0_$rel/bin/javac 20000
alternatives --set javac /usr/java/jdk1.$jdk_version.0_$rel/bin/javac

rm -rf /var/lib/alternatives/jar
alternatives --install /usr/bin/jar jar /usr/java/jdk1.$jdk_version.0_$rel/bin/jar 20000
alternatives --set jar /usr/java/jdk1.$jdk_version.0_$rel/bin/jar

java -version