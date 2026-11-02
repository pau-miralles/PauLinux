#!/bin/sh
unicode="█"

red=$(tput setaf 1)
green=$(tput setaf 2)
yellow=$(tput setaf 3)
blue=$(tput setaf 4)
magenta=$(tput setaf 5)
cyan=$(tput setaf 6)
normal=$(tput sgr0)


model=$(hostnamectl | awk -F': ' '/Hardware Model/ {gsub(/_/, "(", $2); sub(/\($/, ")", $2); print $2}')
mem=$(LC_ALL=C free -b | awk '/^Mem:/ {printf "%.2f GiB / %.2f GiB", $3/1073741824, $2/1073741824}')
up=$(uptime | sed -E 's/^[^,]*up *//; s/mins/minutes/; s/hrs?/hours/;
  s/([[:digit:]]+):0?([[:digit:]]+)/\1 hours, \2 minutes/;
  s/^1 hours/1 hour/; s/ 1 hours/ 1 hour/;
  s/min,/minutes,/; s/ 0 minutes,/ less than a minute,/; s/ 1 minutes/ 1 minute/;
  s/  / /; s/, *[[:digit:]]* users?.*//')


clear
echo "┌───────────┐ "
echo "│ ${red}${normal}  user   │ ${red}$(whoami)@$(hostname -s)${normal}"
echo "│ ${yellow}󰌢${normal}  host   │ ${yellow}${model}${normal}"
echo "│ ${green}${normal}  os     │ ${green}$(sed -nE "s@PRETTY_NAME=\"([^\"]*)\"@\1@p" /etc/os-release)${normal} "
echo "│ ${cyan}${normal}  kernel │ ${cyan}$(uname -r -m)${normal} "
echo "│ ${blue}${normal}  memory │ ${blue}${mem}${normal} "
echo "│ ${magenta}󰐥${normal}  uptime │ ${magenta}${up}${normal} "
echo "│ ${red}${normal}  wm     │ ${red}$XDG_CURRENT_DESKTOP${normal} "
echo "│ ${yellow}${normal}  shell  │ ${yellow}$(echo ${SHELL##*/})${normal} "
echo "│ ${green}${normal}  term   │ ${green}$(ps -o comm= -p "$(($(ps -o ppid= -p "$(($(ps -o sid= -p "$$")))")))")${normal} "
echo "├───────────┤ "
echo "│ ${magenta} ${normal} colors │ ${red}$unicode${yellow}$unicode${green}$unicode${cyan}$unicode${blue}$unicode${magenta}$unicode${normal}"
echo "└───────────┘ "
