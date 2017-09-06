#!/bin/bash

# Instructions:
#
# Set hostname
#(local) vim ~/.ssh/config
# Set params:
UNAME=apix
REPO=apix
GIT_NAME='Server'
GIT_EMAIL='server@apix.rocks'
# Run the following commands
#(local) scp -r setup.sh git/ environment root@HOSTNAME:~
#(local) ssh root@HOSTNAME
#(remote) ./setup.sh
# Type password 5 times
#(remote) reboot
#(local) git remote add prod git@UNAME:REPO.git
#(local) git push prod

apt update
apt -y upgrade; apt -y dist-upgrade
apt -y remove docker docker-engine
apt -y install build-essential vim curl git apt-transport-https ca-certificates software-properties-common
apt -y autoremove
cat environment > /etc/environment; rm environment
adduser $UNAME; adduser git
echo "$UNAME ALL=(ALL:ALL) ALL" >> /etc/sudoers
echo "git ALL=($UNAME) NOPASSWD: /usr/bin/git, /usr/local/bin/docker-compose" >> /etc/sudoers
# ufw app list
# ufw status
# ufw allow OpenSSH
# ufw allow 'Nginx Full'
# ufw allow https
# ufw allow http
# ufw enable

sudo -i -u $UNAME bash <<EOF
cd /home/$UNAME
mkdir .ssh
sudo cp /root/.ssh/authorized_keys .ssh/
sudo cp .ssh/authorized_keys /home/git/
sudo chown $UNAME:$UNAME .ssh/authorized_keys
sudo chown git:git /home/git/authorized_keys
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add -
sudo apt-key fingerprint 0EBFCD88
sudo add-apt-repository "deb [arch=amd64] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable"
sudo apt update
sudo apt -y install docker-ce=17.06.1~ce-0~ubuntu
sudo usermod -aG docker $UNAME
sudo curl -o /usr/local/bin/docker-compose -L "https://github.com/docker/compose/releases/download/1.16.0/docker-compose-$(uname -s)-$(uname -m)"
sudo chmod +x /usr/local/bin/docker-compose
git config --global user.name $GIT_NAME
git config --global user.email $GIT_EMAIL
git config --global push.default simple
EOF

sudo -i -u git bash <<EOF
cd /home/git
mkdir .ssh
mv authorized_keys .ssh/
git init --bare $REPO.git
mkdir scripts
EOF
sed -i -e "s/UNAME/$UNAME/g" git/post-receive.sh
chown git:git git/*
mv git/post-receive /home/git/$REPO.git/hooks/
mv git/* /home/git/scripts

sudo -i -u $UNAME git clone /home/git/$REPO.git/ app
