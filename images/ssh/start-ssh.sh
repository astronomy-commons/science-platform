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
        mkdir -p /etc/ssh/ssh_config.d
        cp /etc/_ssh/ssh_config.d/chart.conf /etc/ssh/ssh_config.d/.
        cat /etc/_ssh/sshd_config.d/chart.conf
        mkdir -p /etc/ssh/sshd_config.d
        cp /etc/_ssh/sshd_config.d/chart.conf /etc/ssh/sshd_config.d/.
    fi
    # (re)generate missing host keys
    ssh-keygen -A
    # Add /run/sshd
    mkdir -p /run/sshd
}

function pre_ssh_startup {
    echo "Running scripts in /usr/local/bin/pre_ssh_start.d"
    # sources scripts in /usr/local/bin/start.d
    # these are added via Helm chart or by mounting a file with Docker
    if [ -d "/usr/local/bin/pre_ssh_start.d" ]
    then
        scripts=$(find /usr/local/bin/pre_ssh_start.d -type f -name "*.sh")
        for script in ${scripts}
        do
            echo ". ${script}"
            . ${script}
        done
    fi
}

function post_ssh_startup {
    echo "Running scripts in /usr/local/bin/post_ssh_start.d"
    # sources scripts in /usr/local/bin/start.d
    # these are added via Helm chart or by mounting a file with Docker
    if [ -d "/usr/local/bin/post_ssh_start.d" ]
    then
        scripts=$(find /usr/local/bin/post_ssh_start.d -type f -name "*.sh")
        for script in ${scripts}
        do
            echo ". ${script}"
            . ${script}
        done
    fi
}

if test "$#" -ne 0; then
    exec "${@}"
else
    pre_ssh_startup
    echo "Setting up SSH:"
    ssh_setup
    sleep 2
    echo "Starting SSH service"
    # $(which sshd) -ddd -D -p 22
    echo "Using configuration:"
    sshd -T
    service ssh start
    post_ssh_startup
    sleep infinity
fi
