#!/bin/sh
set -o errexit

deluser user
addgroup -g ${gid} user
adduser -u ${uid} -D -G user user
echo "source /etc/profile.d/wrapper.sh" >/home/user/.bashrc
chown user:user /home/user/.bashrc

exec gosu ${uid}:${gid} rootlesskit buildkitd "$@"
