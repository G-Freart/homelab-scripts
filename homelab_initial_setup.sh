#!/bin/bash

# ------------------------------------------------------------------------------------------ #
#                                                                                            #
#                Copyright (c) 2021 - Gilles Freart. All right reserved                      #
#                                                                                            #
#  Licensed under the MIT License. See LICENSE in the project root for license information.  #
#                                                                                            #
# ------------------------------------------------------------------------------------------ #

PACKAGE_MGR=''
CURRENT_PATH=`pwd`
SCRIPT_PATH=`dirname "$0"`
CURRENT_USER=`whoami`
WKSP_PATH="/home/$CURRENT_USER/wksp"

if [ "$CURRENT_USER" == "root" ]
then
  echo
  echo "You are not allowed to run this script as root"
  echo

  exit 
fi	


which apt > /dev/null

if [ $? -eq 0 ]
then
  PACKAGE_MGR='apt'
else
  which yum > /dev/null
  
  if [ $? -eq 0 ]
  then
    PACKAGE_MGR='yum'
  fi
fi

echo 
echo configuration
echo -------------
echo "  PACKAGE_MGR  : $PACKAGE_MGR"
echo "  CURRENT_PATH : $CURRENT_PATH"
echo "  CURRENT_USER : $CURRENT_USER"
echo "  WKSP_PATH    : $WKSP_PATH"

if [ "${PACKAGE_MGR}" == "" ]
then
  echo
  echo "Error : Unknown package manager"

  exit
fi

#
# --------------------------------------------------------------------------------
#

echo 
echo Ensuring folder tree
echo --------------------
for subpath in bin bin/scripts src legacy .token
do
  if [ ! -d "${WKSP_PATH}/${subpath}" ]
  then
    echo "  Creating ${WKSP_PATH}/${subpath}"
    mkdir ${WKSP_PATH}/${subpath}
  else
    echo " ${WKSP_PATH}/${subpath} already exists"
  fi
done

chmod 750 ${WKSP_PATH}/.token

#
# --------------------------------------------------------------------------------
#

echo 
echo Installing survival kit
echo -----------------------

if   [ "$PACKAGE_MGR" == "apt" ]; then 

  sudo apt -y update
  sudo apt -y upgrade
  sudo apt -y install git 
  sudo apt -y install vim
  sudo apt -y install mc 
  sudo apt -y install sed 
  sudo apt -y install xrdp 
  sudo apt -y install ansible
  sudo apt -y install openssh-server

  sudo apt -y autoremove

  sudo ufw allow ssh
  sudo ufw allow 3389/tcp

elif [ "$PACKAGE_MGR" == "yum" ]; then 

  sudo yum -y install epel-release
  sudo yum -y update
  sudo yum -y install vim
  sudo yum -y install mc 
  sudo yum -y install sed 
  sudo yum -y install git
  sudo yum -y install tmux
  sudo yum -y install xrdp 
  sudo yum -y install ansible
  sudo yum -y install openssh-server

  sudo systemctl start sshd
  sudo systemctl enable sshd

  sudo firewall-cmd --zone=public --permanent --add-service=ssh
  sudo firewall-cmd --zone=public --permanent --add-port=3389/tcp 
  sudo firewall-cmd --reload

fi

#
# --------------------------------------------------------------------------------
#

echo
echo "Retrieving owned repo"
echo "---------------------"

for reponame in G-Freart/homelab-scripts			\
	        G-Freart/homelab-server				\
	        G-Freart/homelab-kubernetes-provider   		\
	        G-Freart/Aspnetcore3-preview4-header-issue	\

do
  GITHUB_USER=`echo $reponame | sed -e 's/\/.*$//g'`
  GITHUB_REPO=`echo $reponame | sed -e 's/^.*\///g'`
  FOLDER_USER="${WKSP_PATH}/src/${GITHUB_USER}"
  FOLDER_REPO="${WKSP_PATH}/src/${GITHUB_USER}/${GITHUB_REPO}"
  OAUTH_FILE="${WKSP_PATH}/.token/github-oauth-token--${GITHUB_USER}"

  echo
  echo "  Working with ${GITHUB_USER} -> ${GITHUB_REPO}"
  if [ ! -d "${FOLDER_USER}" ]
  then
    echo "    -> Creating folder ${FOLDER_USER}"

    mkdir $FOLDER_USER
  fi	  

  echo "    -> Checking if OAUTH_TOKEN exists for the github user"
  if [ ! -f "${OAUTH_FILE}" ]
  then
    echo "    -> Token not found, please go to https://github.com/settings/tokens and generate a personal access tokens"
    echo 
    read -p "       Please give us the generated access token : " tokendata

    echo $tokendata > ${OAUTH_FILE}
  else
    echo "    -> Token retreived"
    tokendata=`cat ${OAUTH_FILE}`
  fi

  if [ ! -d "$FOLDER_REPO" ]
  then
    echo "    -> Cloning master repo branch of ${GITHUB_REPO}"

    cd $FOLDER_USER
    git clone "https://$tokendata:x-oauth-basic@github.com/${GITHUB_USER}/${GITHUB_REPO}"
  fi

  echo "    -> Updating all repo branch ${GITHUB_REPO}"

  cd $FOLDER_REPO
  
  for b in `git branch -r | grep -v -- '->'`
  do 
    git branch --track ${b##origin/} $b 2> /dev/null 
  done

  git fetch --all > /dev/null
done

cd $CURRENT_PATH

#
# --------------------------------------------------------------------------------
#

echo
echo "Retrieving legacy github repo that i'm following"
echo "------------------------------------------------"

for reponame in kubealex/libvirt-k8s-provisioner   		\
		mjebrahimi/Awesome-Microservices-NetCore	\
		mjebrahimi/Top-NET-Libraries-Must-Know		\
		mjebrahimi/Best-Free-Admin-Dashboard-Template	\
		scottslowe/learning-tools 			\

do
  GITHUB_USER=`echo $reponame | sed -e 's/\/.*$//g'`
  GITHUB_REPO=`echo $reponame | sed -e 's/^.*\///g'`
  FOLDER_USER="${WKSP_PATH}/legacy/${GITHUB_USER}"
  FOLDER_REPO="${WKSP_PATH}/legacy/${GITHUB_USER}/${GITHUB_REPO}"

  echo
  echo "  Working with ${GITHUB_USER} -> ${GITHUB_REPO}"
  if [ ! -d "${FOLDER_USER}" ]
  then
    echo "    -> Creating folder ${FOLDER_USER}"

    mkdir $FOLDER_USER
  fi	  


  if [ ! -d "$FOLDER_REPO" ]
  then
    echo "    -> Cloning master repo branch of ${GITHUB_REPO}"

    cd $FOLDER_USER
    git clone "https://github.com/${GITHUB_USER}/${GITHUB_REPO}"
  fi

  echo "    -> Updating all repo branch ${GITHUB_REPO}"

  cd $FOLDER_REPO
  
  for b in `git branch -r | grep -v -- '->'`
  do 
    git branch --track ${b##origin/} $b 2> /dev/null 
  done

  git fetch --all > /dev/null
done

cd $CURRENT_PATH

#
# --------------------------------------------------------------------------------
#

echo
echo Ensuring path contains $WKSP_PATH/bin/scripts/$FILENAME

if [ ! -f ~/.bash_aliases ]
then
  touch ~/.bash_aliases
fi  

if [ `grep -e "$WKSP_PATH/bin/scripts" ~/.bash_aliases | wc -l` == "0" ]
then
  echo "export PATH=\$PATH:${WKSP_PATH}/bin/scripts" >> ~/.bash_aliases 

  source ~/.profile
fi  

if [ `grep -e "~/.bash_aliases" ~/.bashrc | wc -l` == "0" ]
then
  echo "" >> ~/.bashrc 
  echo "if [ -f ~/.bash_aliases ]; then" >> ~/.bashrc 
  echo "    . ~/.bash_aliases" >> ~/.bashrc 
  echo "fi" >> ~/.bashrc 
  echo "" >> ~/.bashrc 

  source ~/.bash_aliases
fi  

configure_link ()
{
  local FILENAME=`echo $1 | sed -e "s/^.*\///g"`
  local TARGET="$WKSP_PATH/bin/scripts/$FILENAME"

  if [ ! -e ${TARGET} ] 
  then
    echo "  Creating link ${FILENAME} from $1"

    ln -s $1 ${TARGET}
  fi	  
}

#
# -------------------------------------------------------------------------------
#
echo 
echo Ensuring /var/lib/libvirt are mount before libvirt starting is present

if [ `which libvirtd | wc -l` != "0" ] ;
then 	
  sh $SCRIPT_PATH/homelab_service_set_mount_required.sh -m /var/lib/libvirt  -s libvirtd
fi  

#
# --------------------------------------------------------------------------------
#

echo
echo Configuring some global define as LIBVIRT_DEFAULT_URI, ....

if [ `grep -e "export LIBVIRT_DEFAULT_URI" ~/.bash_aliases | wc -l` == "0" ]
then
  echo "export LIBVIRT_DEFAULT_URI=qemu:///system" >> ~/.bash_aliases 

  source ~/.profile
fi  

#
# --------------------------------------------------------------------------------
#

echo
echo Configuring binary scripts
	
  configure_link $WKSP_PATH/src/G-Freart/homelab-scripts/homelab_initial_setup.sh

#
# --------------------------------------------------------------------------------
#

echo 
echo Done, have a nice day !
echo 

echo 
echo 'PS: don"t forget to use the command "sudo visudo" in order to allow all sudo command without giving the passwd (only on non-prod environment)'
echo
echo '  - Under Ubuntu 20.04, add the following line at the end of the file :'
echo
echo '       gilfre5	ALL=(ALL) NOPASSWD:ALL'
echo 
echo
echo '  - Under CentOS 8 Stream, comment the following line :'
echo
echo '       %wheel  ALL=(ALL)       ALL'
echo
echo '    And uncomment the following line :'
echo
echo '       # %wheel  ALL=(ALL)       NOPASSWD: ALL'
echo
echo
