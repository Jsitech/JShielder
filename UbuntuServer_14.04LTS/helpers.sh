#!/bin/bash

spinner ()
{
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



# Show "Done."
function say_done() {
    echo " "
    echo -e "Done."
    say_continue
}


# Ask to Continue
function say_continue() {
    echo -n " To EXIT Press x Key, Press ENTER to Continue"
    read acc
    if [ "$acc" == "x" ]; then
        exit
    fi
    echo " "
}


# Obtain Server IP
function __get_ip() {
    linea=`ifconfig eth0 | grep -e "inet\ addr:"`
    serverip=`python scripts/get_ip.py $linea`
    echo $serverip
}


# Copy Local Config Files
function tunning() {
    whoapp=$1
    cp templates/$whoapp /root/.$whoapp
    cp templates/$whoapp /home/$username/.$whoapp
    chown $username:$username /home/$username/.$whoapp
    say_done
}


# Add BlockIP Command
function add_command_blockip() {
    echo "  ===> blockip [IP] -- Adds IP To Block List in IPTABLES (OK)"
    echo "  ===> unblockip [IP] -- Remove IP From Block List (OK)"
    cp commands/blockip /sbin/jts-iptables
    chmod +x /sbin/jts-iptables
    ln -s /sbin/jts-iptables /sbin/blockip
    ln -s /sbin/jts-iptables /sbin/unblockip
    echo -n "  Adding Man Pages blockip(8) and unblockip(8)"
    cp commands/manpages/blockip /usr/share/man/man8/blockip.8
    gzip -q /usr/share/man/man8/blockip.8
    cp commands/manpages/unblockip /usr/share/man/man8/unblockip.8
    gzip -q /usr/share/man/man8/unblockip.8
    echo " (Done!)"
}
