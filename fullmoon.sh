#!/bin/bash

if [[ "$#" -eq 0 ]]; then
    echo "Dude, you need to pass a list of years as argument, space separated."
    exit 1
fi

if ! [ -x "$(command -v jq)" ]; then
    echo "Dude, you need to have 'jq' installed first in order to run me." >&2
    exit 1
fi

echo -e "\\n\\033[0;31mDude, you are going to get laid in a different way around the following dates:\\n"
tput init

DATES=()

for year in "$@"; do
    for date in $(curl -G -H "Accept: application/json" http://api.usno.navy.mil/moon/phase?year="$year" -s |
                jq '.phasedata[] | select(.phase == "Full Moon") | .date' |
                tr -d '"' |
                awk '{print $1$2$3}')
    do
        DATES+=("$date")
    done
done

if [ "$?" -ne 0 ]; then
    echo "Dude, something went wrong while querying/parsing the response from the remote API."
    exit 1
fi

ICAL_HEADER=$(cat <<-ICAL
BEGIN:VCALENDAR
VERSION:2.0
X-WR-CALNAME:Full Moon
PRODID:-//github.com/your/fullmoon.sh NONSGML//EN
ICAL
)
ICAL_BODY=""
ICAL_FOOTER="END:VCALENDAR"

i=0

for date in "${DATES[@]}"; do
    date -jf "%Y%b%d" "${date}" +"%A, %d %B %Y"

    ICAL_EVENT=$(cat <<-ICAL
BEGIN:VEVENT
UID:$(date '+%F/%T%Z')_$i@$(hostname)
DTSTART:$(date -jf "%Y%b%d%H%M%S" "${date}"000000 +"%Y%m%dT%H%M%SZ")
DURATION:PT1D
SUMMARY:Full Moon
DTSTAMP:$(date +"%Y%m%dT%H%M%SZ")
END:VEVENT
ICAL
)

    if [ -n "$ICAL_BODY" ]; then
        ICAL_BODY="${ICAL_BODY}\\n${ICAL_EVENT}"
    else
        ICAL_BODY="${ICAL_EVENT}"
    fi

    ((i++))
done

echo -e "${ICAL_HEADER}\\n${ICAL_BODY}\\n${ICAL_FOOTER}" > fullmoon.ics

if [ "$?" -ne 0 ]; then
    echo -e "\\n(Dude, something went wrong while creating an iCalendar file – skipping.)"
else
    echo -e "\\n(You will find a fullmoon.ics iCalendar file in this folder.)"
fi

echo -e "\\n\\xf0\\x9f\\x98\\x89\\x0a"
