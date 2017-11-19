#!/bin/bash

if [[ $# -eq 0 ]] ; then
    echo "Dude, you need to pass a list of years as argument, space separated."
    exit 1
fi

if ! [ -x "$(command -v jq)" ]; then
  echo "Dude, you need to have 'jq' installed first in order to run me." >&2
  exit 1
fi

echo -e "\n\033[0;31mDude, you are going to get laid in a different way around the following dates:\n"
tput init

for year in "$@" ; do
    curl -G -H "Accept: application/json" http://api.usno.navy.mil/moon/phase?year="$year" -s |
    jq '.phasedata[] | select(.phase == "Full Moon") | .date'
done

if [ "$?" -ne 0 ] ; then
    echo "Dude, something went wrong while querying/parsing the response from the remote API."
    exit 1
else
    echo -e "\n\xf0\x9f\x98\x89\x0a"
fi
