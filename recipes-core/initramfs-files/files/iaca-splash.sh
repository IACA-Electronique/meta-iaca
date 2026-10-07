#!/bin/sh


case $1 in
  prereqs)
    e it 0
    ;;
esac

# Define color codes
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
LIGHT_YELLOW='\033[0;93m'
BLUE_BG='\033[48;5;32m'
BLUE='\033[0;34m'
WHITE="\033[38;5;15m"
NC='\033[0;30m' # No Color
NO_FORMAT="\033[0m"

show_logo() {
    echo -e "
                                  ${BLUE_BG}                   ${NO_FORMAT}
    ${LIGHT_YELLOW}██  █████   ██████  █████     ${BLUE_BG}  ${WHITE}██████${BLUE_BG}   ${WHITE}███████${BLUE_BG} ${NO_FORMAT}
    ${LIGHT_YELLOW}██ ██   ██ ██      ██   ██    ${BLUE_BG} ${WHITE}██${BLUE_BG}    ${WHITE}██${BLUE_BG}  ${WHITE}██${BLUE_BG}      ${NO_FORMAT}
    ${LIGHT_YELLOW}██ ███████ ██      ███████    ${BLUE_BG} ${WHITE}██${BLUE_BG}    ${WHITE}██${BLUE_BG}  ${WHITE}███████${BLUE_BG} ${NO_FORMAT}
    ${LIGHT_YELLOW}██ ██   ██ ██      ██   ██    ${BLUE_BG} ${WHITE}██${BLUE_BG}    ${WHITE}██${BLUE_BG}       ${WHITE}██${BLUE_BG} ${NO_FORMAT}
    ${LIGHT_YELLOW}██ ██   ██  ██████ ██   ██    ${BLUE_BG}  ${WHITE}██████${BLUE_BG}   ${WHITE}███████${BLUE_BG} ${NO_FORMAT}
                                  ${BLUE_BG}                   ${NO_FORMAT}
    "
}

show_logo

echo -e "${GREEN}OS Starting..${NO_FORMAT}\n"
