#--------------------------------------------------------------------
# Script to Install latest Stable version of Nginx Web Server.
# Suppoted OS: Linux Ubuntu (14.04, 16.04, 18.04, 20.04, 22.04), CentOS 7
#
#--------------------------------------------------------------------

#!/bin/sh

# Exit immediately on an error
set -e

# The name of the script - used for tagging of syslog messages
TAG="nginx_install.sh"

# Log a message to the console and syslog.
log_message() {
        SEVERITY=$1
        MESSAGE=$2
        echo `date`: $SEVERITY "$MESSAGE"
        logger -t $TAG $SEVERITY "$MESSAGE"
}

check_if_root() {
        log_message INFO "Checking whether the script runs as root..."
        if [ "$(id -u)" -ne 0 ]; then
                log_message ERROR "This script must be executed with root permissions"
                exit 1
        fi
}

get_distro() {
        log_message INFO "Discovering the used operating system..."
        lsb_dist=""
        osrelease=""
        pretty_name=""
        basearch=""

        # Every system that we support has /etc/os-release or not?
        if [ -r /etc/os-release ]; then
                lsb_dist="$(. /etc/os-release && echo "$ID")"
                osrelease="$(. /etc/os-release && echo "$VERSION_ID")"
                if [ $osrelease = "8" ]; then
                        pretty_name="jessie"
                elif [ $osrelease = 9 ]; then
                        pretty_name="stretch"
                elif [ $osrelease = 10 ]; then
                        pretty_name="buster"
                elif [ $osrelease = 14.04 ]; then
                        pretty_name="trusty"
                elif [ $osrelease = 16.04 ]; then
                        pretty_name="xenial"
                elif [ $osrelease = 18.04 ]; then
                        pretty_name="bionic"
                elif [ $osrelease = 20.04 ]; then
                        pretty_name="focal"
                elif [ $osrelease = 22.04 ]; then
                        pretty_name="jammy"
                elif [ $osrelease = 7 ]; then
                        pretty_name="centos"
                        lsb_dist="$( rpm -qa \centos-release | cut -d"-" -f1 )"
                        osrelease="$( rpm -qa \centos-release | cut -d"-" -f3 )"
                        basearch=$(rpm -q --qf "%{arch}" -f /etc/$distro)
                else
                        log_message ERROR "It looks like script does not support your OS. Detected OS details: osrelease = \"$osrelease\""
                        exit 1
                fi

        elif [ -r /etc/centos-release ]; then
                lsb_dist="$( rpm -qa \centos-release | cut -d"-" -f1 )"
                osrelease="$( rpm -qa \centos-release | cut -d"-" -f3 )"
                basearch=$(rpm -q --qf "%{arch}" -f /etc/$distro)
        else
                log_message ERROR "It looks like script does not support your OS. Detected OS details: osrelease = \"$osrelease\""
                exit 1
        fi


        log_message INFO "Detected OS details: lsb_dist=$lsb_dist, osrelease=$osrelease, pretty_name=$pretty_name, basearch=$basearch"
}

#install
do_install() {
        #check the user is root
        check_if_root

        #do some platform detection
        get_distro

        #install nginx

        case $lsb_dist in
                debian|ubuntu)
                        log_message INFO "Configuring official Nginx repository key..."
                        apt-get update && apt-get install wget apt-transport-https dirmngr -y
                        wget -O nginx_signing.key https://nginx.org/keys/nginx_signing.key
                        apt-key add nginx_signing.key

                        log_message INFO "Configuring official Nginx repository..."
                        sh -c "echo 'deb https://nginx.org/packages/$lsb_dist/ $pretty_name nginx'\
                                > /etc/apt/sources.list.d/nginx.list"
                        sh -c "echo 'deb-src https://nginx.org/packages/$lsb_dist/ $pretty_name nginx'\
                                >> /etc/apt/sources.list.d/nginx.list"

                        log_message INFO "Removing nginx-common package..."
                        apt-get remove nginx-common

                        log_message INFO "Installing official Nginx package..."
                        apt-get update
                        apt-get install -y nginx
                        ;;
                centos)
                        log_message INFO "Configuring official Nginx repository..."
                        echo "[nginx]" > /etc/yum.repos.d/nginx.repo
                        echo "name=nginx repo" >> /etc/yum.repos.d/nginx.repo
                        echo "baseurl=https://nginx.org/packages/centos/$osrelease/$basearch/" >> /etc/yum.repos.d/nginx.repo
                        echo "gpgcheck=0" >> /etc/yum.repos.d/nginx.repo
                        echo "enabled=1" >> /etc/yum.repos.d/nginx.repo

                        log_message INFO "Installing official Nginx packages..."
                        yum update -y
                        if ! rpm --quiet -q nginx; then
                                yum install nginx -y
                        fi
                        ;;
        esac
}


do_install

systemctl enable nginx
systemctl start nginx

curl localhost
nginx -v
