#!/bin/sh
set -o errexit

deluser user
addgroup -g ${gid} user
adduser -u ${uid} -D -G user user

exec gosu ${uid}:${gid} rootlesskit buildkitd "$@"
