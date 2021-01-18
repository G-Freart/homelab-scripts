#!/bin/bash

# ------------------------------------------------------------------------------------------ #
#                                                                                            #
#                Copyright (c) 2021 - Gilles Freart. All right reserved                      #
#                                                                                            #
#  Licensed under the MIT License. See LICENSE in the project root for license information.  #
#                                                                                            #
# ------------------------------------------------------------------------------------------ #

SCRIPT_NAME=`basename "$0"`

MOUNT_PATH=
SERVICE_NAME=

usage ()
{
  echo
  echo "usage : ${SCRIPT_NAME} -m \"mount-path\" -s \"service-name\""
  echo
  echo " f.i. : ${SCRIPT_NAME} -m /var/lib/libvirt -s libvirtd"
  echo 

  exit 1
}	

while getopts ":m:s:" opt; do
  case ${opt} in
    m)
	MOUNT_PATH=$OPTARG
        ;;

    s)
	SERVICE_NAME=$OPTARG
        ;;

    \?)
        usage
        ;;

    :)
        usage
        ;;
  esac
done  

if [ -z "$MOUNT_PATH" ] || [ -z "$SERVICE_NAME" ]; 
then
  usage
fi  

#
# Searching after definition of the service
#
SERVICE_DEFINITION=`systemctl show -p FragmentPath ${SERVICE_NAME} | sed 's/FragmentPath=//g'`

if [ -z "${SERVICE_DEFINITION}" ] 
then
  echo
  echo "Error : Unable to find service definition for ${SERVICE_NAME}"
  echo

  exit 2
fi

#
# Checking that the mounting path exists
#
if [ ! -d "${MOUNT_PATH}" ];
then
  echo
  echo "Error : Unable to find the mount path at ${MOUNT_PATH}"
  echo

  exit 3
fi	

#
# Searching after the service in charge to perform the path mounting
#
MOUNT_SERVICE=`systemctl list-units | grep -e " ${MOUNT_PATH} " | awk '{ print $1 }'`

if [ -z "${MOUNT_SERVICE}" ];
then
  echo
  echo "Error : Unable to find the mount service related to the path ${MOUNT_PATH}"
  echo

  exit 4
fi	

#
# Check if the dependencies already exists
#
FOUNDED=`grep -e "After=${MOUNT_SERVICE}" ${SERVICE_DEFINITION} | wc -l`

if [ "$FOUNDED" = "0" ];
then
  echo
  echo "  Processing $MOUNT_PATH for $SERVICE_NAME defined at $SERVICE_DEFINITION and mounted by $MOUNT_SERVICE"

  sudo sed -i "/^\[Unit\].*/a After=${MOUNT_SERVICE}" $SERVICE_DEFINITION
  sudo systemctl daemon-reload
  sudo systemctl restart $SERVICE_NAME

  echo
  echo "  => Patching done, have a nice day !"
fi

