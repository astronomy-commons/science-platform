#!/bin/bash

# function that adds system users based on contents of /home
function adduserloop {
    while true
    do
        HOMEDIR=/home

        for USER in $(ls $HOMEDIR); do
            USERID=$(stat -c '%u' "$HOMEDIR/$USER")
            GROUPID=$(stat -c '%g' "$HOMEDIR/$USER")

            groupadd $GROUPID || true
            useradd -M -s /bin/bash -u $USERID -g $GROUPID $USER || true
        done
        echo "[adduserloop] sleeping 5 seconds..."
        sleep 5
    done
}

# Function to setup ssh and link to NFS
function ssh_setup {
    server_config_dir="/home/admin/ssh/server"
    # load ssh config from NFS
    if [ ! -d $server_config_dir ]
    then
        # Back up host keys and config to NFS
        mkdir -p $server_config_dir
        cp -r /etc/ssh/* $server_config_dir/.
    fi
    # remove host keys and config from container
    rm -rf /etc/ssh
    # link to host keys and config on NFS
    ln -s $server_config_dir /etc/ssh
    
    # add config specified via Helm chart
    if [ -d /etc/_ssh ]; then
        cat /etc/_ssh/ssh_config.d/chart.conf
        cp /etc/_ssh/ssh_config.d/chart.conf /etc/ssh/ssh_config.d/.
        cat /etc/_ssh/sshd_config.d/chart.conf
        cp /etc/_ssh/sshd_config.d/chart.conf /etc/ssh/sshd_config.d/.
    fi
    # (re)generate missing host keys
    ssh-keygen -A
    # Add /run/sshd
    mkdir -p /run/sshd
}

if test "$#" -ne 0; then
    exec "${@}"
else
    echo "Adding users:"
    adduserloop &> /dev/null &
    sleep 2
    echo "Setting up SSH:"
    ssh_setup
    sleep 2
    echo "Starting SSH service"
    # $(which sshd) -ddd -D -p 22
    echo "Using configuration:"
    sshd -T
    service ssh start
    sleep infinity
fi
