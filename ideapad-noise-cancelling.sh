#!/usr/bin/env bash

function is_percentage {
  seq 0 100 | grep -xq $1 -
  return $?
}

function is_ge_capa_conservation_mode_limit {
  seq 60 100 | grep -xq $1 -
  return $?
}

function bool_to_onoff {
  case $1 in
    0) echo "off" ;;
    1) echo "on" ;;
    *) echo "unknown" ;;
  esac
}

function load_default_configuration {
  # define hard coded default configuration
  CAPA_FILE_DEFAULT=/sys/class/power_supply/BAT1/capacity
  CAPA_CONSERVATION_MODE_FILE_DEFAULT=/sys/bus/platform/drivers/ideapad_acpi/VPC2004:00/conservation_mode
  CAPA_UPPER_LIMIT_MODE_HEALTH_DEFAULT=65
  CAPA_LOWER_LIMIT_MODE_HEALTH_DEFAULT=60
  CAPA_UPPER_LIMIT_MODE_HIGH_DEFAULT=80
  CAPA_LOWER_LIMIT_MODE_HIGH_DEFAULT=75
  CAPA_UPPER_LIMIT_MODE_FULL_DEFAULT=100
  CAPA_LOWER_LIMIT_MODE_FULL_DEFAULT=95
  CAPA_MODE_DEFAULT=high 
}

function load_configuration {
  # start out with default configuration
  CAPA_FILE=$CAPA_FILE_DEFAULT
  CAPA_CONSERVATION_MODE_FILE=$CAPA_CONSERVATION_MODE_FILE_DEFAULT
  CAPA_UPPER_LIMIT_MODE_HEALTH=$CAPA_UPPER_LIMIT_MODE_HEALTH_DEFAULT
  CAPA_LOWER_LIMIT_MODE_HEALTH=$CAPA_LOWER_LIMIT_MODE_HEALTH_DEFAULT
  CAPA_UPPER_LIMIT_MODE_HIGH=$CAPA_UPPER_LIMIT_MODE_HIGH_DEFAULT
  CAPA_LOWER_LIMIT_MODE_HIGH=$CAPA_LOWER_LIMIT_MODE_HIGH_DEFAULT
  CAPA_UPPER_LIMIT_MODE_FULL=$CAPA_UPPER_LIMIT_MODE_FULL_DEFAULT
  CAPA_LOWER_LIMIT_MODE_FULL=$CAPA_LOWER_LIMIT_MODE_FULL_DEFAULT
  CAPA_MODE=$CAPA_MODE_DEFAULT

  # overwrite with user configuration, if available
  if [ -e /etc/ideapad-noise-cancelling.conf ]; then
    source /etc/ideapad-noise-cancelling.conf
  fi

  # validate configuration
  if ! is_percentage $CAPA_UPPER_LIMIT_MODE_HEALTH ||
     ! is_percentage $CAPA_LOWER_LIMIT_MODE_HEALTH ||
     ! is_percentage $CAPA_UPPER_LIMIT_MODE_HIGH ||
     ! is_percentage $CAPA_LOWER_LIMIT_MODE_HIGH ||
     ! is_percentage $CAPA_UPPER_LIMIT_MODE_FULL ||
     ! is_percentage $CAPA_LOWER_LIMIT_MODE_FULL; then
    echo "ERROR: Capacity limits must be percentages."
    exit 1
  fi

  if ! is_ge_capa_conservation_mode_limit $CAPA_UPPER_LIMIT_MODE_HEALTH ||
     ! is_ge_capa_conservation_mode_limit $CAPA_LOWER_LIMIT_MODE_HEALTH ||
     ! is_ge_capa_conservation_mode_limit $CAPA_UPPER_LIMIT_MODE_HIGH ||
     ! is_ge_capa_conservation_mode_limit $CAPA_LOWER_LIMIT_MODE_HIGH ||
     ! is_ge_capa_conservation_mode_limit $CAPA_UPPER_LIMIT_MODE_FULL ||
     ! is_ge_capa_conservation_mode_limit $CAPA_LOWER_LIMIT_MODE_FULL; then
    echo "ERROR: Capacity limits must be greater than or equal the conservation mode"
    echo "       threshold (60%), as lower values can not be enforced while on AC power."
    exit 1
  fi

  if [ $CAPA_UPPER_LIMIT_MODE_HEALTH -le $CAPA_LOWER_LIMIT_MODE_HEALTH ] ||
     [ $CAPA_UPPER_LIMIT_MODE_HIGH -le $CAPA_LOWER_LIMIT_MODE_HIGH ] ||
     [ $CAPA_UPPER_LIMIT_MODE_FULL -le $CAPA_LOWER_LIMIT_MODE_FULL ]; then
    echo "ERROR: Capacity upper limits must exceed the lower limits."
    exit 1
  fi

  if [ $CAPA_MODE != 'system-default' ] &&
     [ $CAPA_MODE != 'system-health' ] &&
     [ $CAPA_MODE != 'health' ] &&
     [ $CAPA_MODE != 'high' ] &&
     [ $CAPA_MODE != 'full' ]; then
    echo "ERROR: '$CAPA_MODE' is not a valid capacity mode. Valid modes are:"
    echo "       - system-default      Charge up to 100% capacity and stick there"
    echo "       - system-health       Charge up to 60% capacity and stick there"
    echo "       - health              Stay in a healthy capacity range, trying to"
    echo "                             avoid noise (defaults: ${CAPA_LOWER_LIMIT_MODE_HEALTH}% to ${CAPA_UPPER_LIMIT_MODE_HEALTH}%)"
    echo "       - high                Stay in a rather high capacity range, trying to"
    echo "                             avoid noise (defaults: ${CAPA_LOWER_LIMIT_MODE_HIGH}% to ${CAPA_UPPER_LIMIT_MODE_HIGH}%)"
    echo "       - full                Stay in an almost full capacity range, trying to"
    echo "                             avoid noise (defaults: ${CAPA_LOWER_LIMIT_MODE_FULL}% to ${CAPA_UPPER_LIMIT_MODE_FULL}%)"
    exit 1
  fi

  # apply configuration
  if [ $CAPA_MODE = 'system-default' ] || [ $CAPA_MODE = 'system-health' ]; then
    CAPA_UPPER_LIMIT=
    CAPA_LOWER_LIMIT=
  elif [ $CAPA_MODE = 'health' ]; then
    CAPA_UPPER_LIMIT=$CAPA_UPPER_LIMIT_MODE_HEALTH
    CAPA_LOWER_LIMIT=$CAPA_LOWER_LIMIT_MODE_HEALTH
  elif [ $CAPA_MODE = 'high' ]; then
    CAPA_UPPER_LIMIT=$CAPA_UPPER_LIMIT_MODE_HIGH
    CAPA_LOWER_LIMIT=$CAPA_LOWER_LIMIT_MODE_HIGH
  elif [ $CAPA_MODE = 'full' ]; then
    CAPA_UPPER_LIMIT=$CAPA_UPPER_LIMIT_MODE_FULL
    CAPA_LOWER_LIMIT=$CAPA_LOWER_LIMIT_MODE_FULL
  fi
}

function start {
  echo "Started."

  echo "Loading default configuration..."
  load_default_configuration
  echo "Loaded default configuration."
 
  echo "Loading (user) configuration..."
  load_configuration
  echo "Loaded (user) configuration."

  echo "Saving original conservation mode state..."
  CAPA_CONSERVATION_MODE_INITIAL=$(cat $CAPA_CONSERVATION_MODE_FILE)
  echo "Saved original conservation mode state ($( bool_to_onoff ${CAPA_CONSERVATION_MODE_INITIAL} ))."
}

function reload {
  echo "Received request to reload (user) configuration."

  echo "Reloading (user) configuration..."
  load_configuration
  echo "Reloaded (user) configuration."
}

function stop {
  echo "Received request to stop."

  echo "Restoring original conservation mode state ($( bool_to_onoff ${CAPA_CONSERVATION_MODE_INITIAL} ))..."
  echo $CAPA_CONSERVATION_MODE_INITIAL > $CAPA_CONSERVATION_MODE_FILE
  echo "Restored original conservation mode state."

  echo "About to stop."
  exit 0
}


trap reload SIGHUP
trap stop SIGTERM
start

while [ true ]; do
  CAPA=$(cat $CAPA_FILE)
  CAPA_CONSERVATION_MODE_NOW=$(cat $CAPA_CONSERVATION_MODE_FILE)
  
  if [ ! $CAPA_MODE_LAST_KNOWN ] || [ $CAPA_MODE != $CAPA_MODE_LAST_KNOWN ]; then
    echo "Switched to capacity mode '${CAPA_MODE}'."
    CAPA_MODE_LAST_KNOWN=$CAPA_MODE
  fi

  if [ $CAPA_MODE = 'system-default' ] && [ $CAPA_CONSERVATION_MODE_NOW -ne 0 ]; then
    echo "System default mode requested: Force-disabling conservation mode."
    echo 0 > $CAPA_CONSERVATION_MODE_FILE
  elif [ $CAPA_MODE = 'system-health' ] && [ $CAPA_CONSERVATION_MODE_NOW -ne 1 ]; then
    echo "System health mode requested: Force-enabling conservation mode."
    echo 1 > $CAPA_CONSERVATION_MODE_FILE
  elif [ $CAPA_UPPER_LIMIT ] && [ $CAPA -ge $CAPA_UPPER_LIMIT ] && [ $CAPA_CONSERVATION_MODE_NOW -ne 1 ]; then
    echo "${CAPA}% capacity >= ${CAPA_UPPER_LIMIT}% upper capacity limit: Enabling conservation mode."  
    echo 1 > $CAPA_CONSERVATION_MODE_FILE
  elif [ $CAPA_LOWER_LIMIT ] && [ $CAPA -le $CAPA_LOWER_LIMIT ] && [ $CAPA_CONSERVATION_MODE_NOW -ne 0 ]; then
    echo "${CAPA}% capacity <= ${CAPA_LOWER_LIMIT}% lower capacity limit: Disabling conservation mode."  
    echo 0 > $CAPA_CONSERVATION_MODE_FILE
  fi
  
  sleep 5
done
