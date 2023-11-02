#!/usr/bin/env bash

set -eu

##########################################################################
## This is intended to provide an example on SSH key generation for 
## integrating with Github and Gitlab.
##
## By default, it'll generate a ed25519 key that is secured by federal
## government standards of FIPS 186-5 NIST standard for Digital Signatures.
## https://csrc.nist.gov/pubs/fips/186-5/final
##
## Usage:
## bash create-sshkey.sh
## bash create-sshkey.sh -t rsa -f github_id_rsa -e tpz7@cdc.gov
##########################################################################
key_type="ed25519"
key_filename=""
email=""
key_options=""
password_option="-N \"\""
current_datetime=$(date +'%Y-%m-%d-%H-%M-%S')

while getopts "t:f:e:" opt; do
  case $opt in
    t)
      key_type="$OPTARG"
      ;;
    f)
      key_filename="$OPTARG"
      ;;
    e)
      email="-C $OPTARG"
      ;;
    \?)
      echo "Usage: $0 [-t key_type] [-f key_filename] [-e email]"
      exit 1
      ;;
  esac
done

shift $((OPTIND-1))

if [ "$key_type" == "rsa" ]; then
  key_options="-t rsa -b 4096"
elif [ "$key_type" == "ed25519" ]; then
  key_options="-t ed25519 -a 100"
fi

if [ -z "$key_filename" ]; then
  if [ "$key_type" == "ed25519" ]; then
    key_filename="${current_datetime}_id_ed25519"
  else
    key_filename="${current_datetime}_id_rsa"
  fi
fi

##############################################################################
## Note that email or an identifer is optional, and ssh will use 
## your machine name instead if not available. 
## Feel free to copy and paste these commands instead of running this script.
## 
## For ED25519 keys, this script will generate the following:
## ssh-keygen -t ed25519 -a 100 -C "<email>" -N "" -f ~/.ssh/id_ed25519
##
## For RSA keys, this script will generate the following:
## ssh-keygen -t rsa -b 4096 -C "<email>" -N "" -f ~/.ssh/id_ed25519
##############################################################################
ssh-keygen $key_options $email $password_option -f ~/.ssh/"${key_filename}"

echo "Generated Key Results: "
echo "Private key path: ~/.ssh/$key_filename"
echo "Public key path: ~/.ssh/${key_filename}.pub"
echo "Public key:"
cat ~/.ssh/"${key_filename}.pub"