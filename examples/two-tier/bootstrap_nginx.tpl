#!/bin/bash

cat <<EOT >> /home/ec2-user/.ssh/authorized_keys
ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQDNLq6dNn/5T/koh9pXuHZ5zvV070G3SIcpYNNj1vfA++RuP7zCS1BG+mD0ZbIEFFj4SqLFnY2lI/vsEoOy97vNwQ6yaNgpwuhpd8++iD9GNo3L9hjQKLWpj/42U4+8kzKot6S4J8uoDgjBeZEnxUFTiOH6uEq/Wzo644DXVKa5xHh5aJtlmZdbyINsypmgfKPpzqaeWJ30uFZYbiBAzIRR1Gyiz0d93VoLSqK/+tYbwvxyG8+rEOh0fiT7U4vg/b4AO+To0kcecTUd16yYK5VdQAmpwHK9EpAH9ujtZ3U1B6c5OZYhJGkRPpTycmgarcny9N0AgbC5Fjkf83aWfixf thirupalanivel@CoE-M-Thiru.local
EOT

function set_hostname()  {
   sudo apt-get -y install wget
   local_ip=`wget -q -O - http://169.254.169.254/latest/meta-data/local-ipv4`
   HOSTNAME=thiru_nginx-$local_ip
   hostname $HOSTNAME
   echo "HOSTNAME=$HOSTNAME" > /etc/hostname
   echo "HOSTNAME=$HOSTNAME" >> /etc/sysconfig/network
   hostnamectl set-hostname $HOSTNAME --static
   echo "preserve_hostname: true" >> /etc/cloud/cloud.cfg
}

function install_nginx {
    sudo apt-get -y install nginx
}

function start_nginx()  {
  sudo service nginx restart
}

#set_hostname
install_nginx
start_nginx