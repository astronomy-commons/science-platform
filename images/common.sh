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
