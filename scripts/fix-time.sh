#!/usr/bin/env bash

set -eu

###########################################################################
## This function takes in a location input as the first parameter which is
## a timezone location of the continential US location you're in.
## 
## It will set the timezone to that time.
########################################################################### 
set_timezone() {
  case $1 in
    "Eastern" | "eastern" | "EST" | "EDT")
      timezone="America/New_York"
      ;;
    "Central" | "central" | "CST" | "CDT")
      timezone="America/Chicago"
      ;;
    "Mountain" | "mountain" | "MST" | "MDT")
      timezone="America/Denver"
      ;;
    "Pacific" | "pacific" | "PST" | "PDT")
      timezone="America/Los_Angeles"
      ;;
    "UTC" | "utc")
      timezone="UTC"
      ;;
    *)
      echo "Invalid or unsupported location: $1"
      exit 1
      ;;
  esac

  # Set the timezone
  timedatectl set-timezone $timezone

  echo "Timezone set to $timezone"
}

if [[ $EUID -ne 0 ]]; then
  echo "This script must be run as root (sudo)." 
  exit 1
fi


##########################################################
## Usage of this script: sudo ./set_timezone.sh Eastern
##########################################################
if [ $# -eq 0 ]; then
  echo "Usage: $0 [Eastern|Central|Mountain|Pacific|UTC]"
  exit 1
fi

set_timezone "$1"
