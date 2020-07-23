#!/usr/bin/env bash


# JShielder v2.4
# Linux Hardening Script
#
# Jason Soto
# www.jasonsoto.com
# Twitter = @JsiTech

# Tool URL = github.com/jsitech/jshielder

# Based from JackTheStripper Project
# Credits to Eugenia Bahit

# A lot of Suggestion Taken from The Lynis Project
# www.cisofy.com/lynis
# Credits to Michael Boelen @mboelen

#Credits to Center for Internet Security CIS

##############################################################################################################

f_banner(){
	clear 
	echo "


     ██╗███████╗██╗  ██╗██╗███████╗██╗     ██████╗ ███████╗██████╗
     ██║██╔════╝██║  ██║██║██╔════╝██║     ██╔══██╗██╔════╝██╔══██╗
     ██║███████╗███████║██║█████╗  ██║     ██║  ██║█████╗  ██████╔╝
██   ██║╚════██║██╔══██║██║██╔══╝  ██║     ██║  ██║██╔══╝  ██╔══██╗
╚█████╔╝███████║██║  ██║██║███████╗███████╗██████╔╝███████╗██║  ██║
╚════╝ ╚══════╝╚═╝  ╚═╝╚═╝╚══════╝╚══════╝╚═════╝ ╚══════╝╚═╝  ╚═╝
                                                              
Automated Hardening Script for Linux Servers
Developed By Jason Soto @JsiTech

"

}

##############################################################################################################

# Create distro variable
DISTRO=""
CUID=$(id -u)
MYNAME="$(basename "${0}")"

# Allow more generalized selection of distro scripts
run_script() {
	if [ -n "${1}" ]
	then
		if [ -d "${1}" ]
		then
			# Leverage the fact that the child script has the same name
			cd "${1}" 2<&- && chmod +x ./"${MYNAME}" && ./"${MYNAME}"
		else
			perr "${1} is not currently supported!"
		fi
	else
		printf "[%s]: Unknown input provided\n" "${MYNAME%.sh}"
	fi
}

# Print formatted message to stdout and stderr
perr() {
	printf "[%s]: %s\n" "${MYNAME%.sh}" "${@}" >&2
}

main() {
	# Check if Running with root user
	if [ "${CUID}" -ne 0 ]; then
		perr "You must be root to run this script!"
		exit 1
	else
		f_banner
	fi


	menu=""
	until [ "$menu" = "10" ]; do

	f_banner

	echo -e "\e[34m---------------------------------------------------------------------------------------------------------\e[00m"
	echo -e "\e[93m[+]\e[00m SELECT YOUR LINUX DISTRIBUTION"
	echo -e "\e[34m---------------------------------------------------------------------------------------------------------\e[00m"
	printf "\t%d. %s\n"\
		"1" "Ubuntu Server 16.04 LTS"\
		"2" "Ubuntu Server 18.04 LTS"\
		"3" "Linux CentOS 7 (Coming Soon)"\
		"4" "Debian GNU/Linux 8 (Coming Soon)"\
		"5" "Debian GNU/Linux 9 (Coming Soon)"\
		"6" "Red Hat Linux 7 (Coming Soon)"\
		"7" "Exit"

	read -r menu
	case $menu in

		# Simply retain this pattern to make additions easier
		1) DISTRO="UbuntuServer_16.04LTS" ;;
		2) DISTRO="UbuntuServer_18.04LTS" ;;
		7) return 0 ;; # Exit, as stated by the menu
		8) break ;;
		*) return 1 ;; # Invalid selection

		esac
	done
	run_script "${DISTRO}"
}

main
