#!/bin/sh
set -o errexit

deluser user
#if ! grep -q ":x:${gid}:" /etc/group; then
    addgroup -g ${gid} user
#fi
#if ! grep -q ":x:${uid}:" /etc/passwd; then
    adduser -u ${uid} -D -G user user
#fi
echo "source /wrapper.sh" >/home/user/.bashrc
chown user:user /home/user/.bashrc

exec gosu ${uid}:${gid} rootlesskit buildkitd "$@"
