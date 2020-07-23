#!/usr/bin/env bash

# Current user ID
CUID="$(id -u)"

spinner () {
    bar=" ++++++++++++++++++++++++++++++++++++++++++++++++++++++++"
    barlength=${#bar}
    i=0
    while ((i < 100)); do
        n=$((i*barlength / 100))
        printf "\e[00;34m\r[%-${barlength}s]\e[00m" "${bar:0:n}"
        ((i += RANDOM%5+2))
        sleep 0.02
    done
}


# Print formatted message to stdout and stderr
perr() {
	printf "[%s]: %s\n" "${MYNAME}" "${@}" >&2
}

# Show "Done."
say_done() {
    printf "%s\n" "Done."
    say_continue
}


# Ask to Continue
say_continue() {
    printf "%s" "To EXIT Press x Key, Press ENTER to Continue: "
    read -r acc
    if [ "$acc" == "x" ]; then
        exit 0
    fi
}


# Obtain Server IP, store for later use
__get_ip() {
		# This will be accessible to the script after sourcing,
		# so the variable can be re-used instead of this function
    serverip=$(ip route get 1 | awk '{print $7;exit}')
}


# Copy Local Config Files
tuning() {
    cp templates/"${1}" /root/."${1}"
    cp templates/"${1}" /home/"${username}"/."${1}"
    chown "${username}":"${username}" /home/"${username}"/."${1}"
}
