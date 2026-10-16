#!/bin/bash
# WSL out-of-box experience: runs once on first interactive shell launch.
# Creates a non-root user matching the Windows login (with sudo access).
# The shared helper also runs from run-once.service, so whichever runs
# first creates the account and the other only finishes its setup.
set -ue

status=0
/opt/scripts/create-default-user.sh || status=$?
if [ "$status" -eq 0 ]; then
    exit 0
fi
if getent passwd 1000 > /dev/null 2>&1; then
    echo 'The user account exists, but setup did not finish; see the errors above.' >&2
    exit 1
fi

# No usable Windows username, or it was rejected: ask for one instead
echo 'Please create a default UNIX user account.'
echo 'For more information visit: https://aka.ms/wslusers'
while true; do
    read -rp 'Enter new UNIX username: ' username
    if /opt/scripts/create-default-user.sh "$username"; then
        break
    fi
    # The account exists but a later setup step failed; a new name won't help
    if getent passwd 1000 > /dev/null 2>&1; then
        echo 'User setup did not finish; see the errors above.' >&2
        exit 1
    fi
done
