#!/bin/bash

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

echo "Starting SSH"
echo "ID: $(id -u)"
if [ "$(id -u)" -ne "0" ]; then
    echo "Script hasn't been run as root, will try to run again as root"
    if [[ "${GRANT_SUDO}" != "1" && "${GRANT_SUDO}" != 'yes' ]]; then
        echo "Must run as root with GRANT_SUDO=1"
        exit -1
    else
        CMD="sudo -u root /usr/local/bin/start-ssh.sh"
        echo "Executing: ${CMD}"
        exec ${CMD}
    fi
fi

echo "Setting up SSH:"
ssh_setup
echo "Starting SSH service"
# $(which sshd) -ddd -D -p 22
echo "Using configuration:"
sshd -T
service ssh start
sleep infinity
