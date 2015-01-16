#!/bin/bash

FLAVOUR=$1
IP=$2
USER=$3

echo -n "Input passoword for $2: "
read -s PASS

NEW_CONFIG=$4

CURRENT_DIR=$(dirname $0)
DELTA_SCRIPT="$CURRENT_DIR/../delta/delta.rb"
CHATTER_SCRIPT="$CURRENT_DIR/../chatter/sc"
CURRENT_CONFIG=`mktemp`
DELTA_CONFIG=`mktemp`

if [ -z "${EDITOR}" ]
  then
  EDITOR="nano"
  echo "Setting default editor to $EDITOR"
fi

echo -n "Check generated config..."
if [ ! -e $NEW_CONFIG ]
  then
  echo "failed."
  echo "generated config not found: $NEW_CONFIG"
  exit 1
fi
echo "success."

echo -n "Check delta script..."
if [ ! -e $DELTA_SCRIPT ]
  then
  echo "failed."
  echo "construqt switch delta script could not be found. Detail: $DELTA_SCRIPT"
  exit 1
fi
echo "success."

echo -n "Check ruby version..."
ruby -v > /dev/null
if [ $? != 0 ]
  then
    echo "failed."
    echo "ruby could not be found on system."
    exit 1
fi
echo "success."

#load current config from switch and save it to temp file
echo -n "Loading config from switch..."
bash -c "$CHATTER_SCRIPT $FLAVOUR ssh://$IP:22 $USER $PASS read" > $CURRENT_CONFIG
if [ $? != 0 ]
  then
    echo "failed."
    echo "an error occured while performing switch chatter."
    exit 1
fi

echo "success"

cat $CURRENT_CONFIG | ruby $DELTA_SCRIPT $FLAVOUR $NEW_CONFIG > $DELTA_CONFIG

while true; do
  echo -e "\n--- Calculated delta ( $DELTA_CONFIG )---\n"
  cat $DELTA_CONFIG
  echo -e "\n-----------------------------------------\n"
  read -p "Do you wish to install this delta? (y=yes, n=no, e=edit, s=show current, q=quit)" answer
  case $answer in
      [Yy]* ) cat $DELTA_CONFIG | bash -c "$CHATTER_SCRIPT $FLAVOUR ssh://$IP:22 $USER $PASS write --persist" ; exit;;
      [Ee]* ) $EDITOR $DELTA_CONFIG ;;
      [Ss]* ) cat $CURRENT_CONFIG ;;
      [NnQq]* ) exit ;;
      * ) ;;
  esac
done
