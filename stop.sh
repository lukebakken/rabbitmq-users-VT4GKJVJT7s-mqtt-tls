#!/usr/bin/env bash

set -o errexit
set -o nounset
set -o pipefail
# set -o xtrace

_tmp="$(CDPATH='' cd -- "$(dirname -- "$0")" && pwd)"
readonly script_dir="$_tmp"

_tmp="$(hostname -s)"
readonly server_cn="$_tmp"

unset _tmp

readonly rmq_version='3.13.1'
readonly rmq_dir="$script_dir/rabbitmq_server-$rmq_version"
readonly rmq_sbin_dir="$rmq_dir/sbin"
readonly rmq_ctl="$rmq_sbin_dir/rabbitmqctl"

"$rmq_ctl" shutdown
