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
readonly rmq_xz="$script_dir/rabbitmq-server-generic-unix-$rmq_version.tar.xz"
readonly rmq_dir="$script_dir/rabbitmq_server-$rmq_version"
readonly rmq_etc_dir="$rmq_dir/etc/rabbitmq"
readonly rmq_sbin_dir="$rmq_dir/sbin"
readonly rmq_server="$rmq_sbin_dir/rabbitmq-server"
readonly rmq_ctl="$rmq_sbin_dir/rabbitmqctl"
readonly certs_dir="$script_dir/certs"
readonly log_dir="$script_dir/log"

function on_exit
{
    set +o errexit
    echo '[INFO] exiting!'
}
trap on_exit EXIT

if [[ ! -s $rmq_xz ]]
then
    curl -LO "https://github.com/rabbitmq/rabbitmq-server/releases/download/v$rmq_version/rabbitmq-server-generic-unix-$rmq_version.tar.xz"
    tar xf "$rmq_xz"
fi

readonly rmq_plugins="$rmq_sbin_dir/rabbitmq-plugins"
if [[ -x $rmq_plugins ]]
then
    "$rmq_plugins" enable rabbitmq_management rabbitmq_mqtt rabbitmq_auth_mechanism_ssl
else
    echo "[ERROR] expected to find '$rmq_plugins', exiting" 1>&2
    exit 69
fi

# Set up Python virtualenv and install paho.mqtt
readonly venv_dir="$script_dir/venv"
readonly venv_activate="$script_dir/venv/bin/activate"
if [[ ! -x $venv_activate ]]
then
    python -m venv "$venv_dir"
fi
# shellcheck disable=SC1090
source "$venv_activate"
pip install paho.mqtt

sed -e "s/##SERVER_CN##/$server_cn/g" -e "s|##CERTS_DIR##|$certs_dir|g" "$script_dir/rabbitmq.conf.in" > "$rmq_etc_dir/rabbitmq.conf"

# Start RabbitMQ and wait
LOG=debug "$rmq_server" > "$log_dir/console_log" 2> "$log_dir/console_err" &
sleep 5
"$rmq_ctl" await_startup

readonly cn="$(openssl x509 -noout -subject -nameopt multiline -in $certs_dir/client_shostakovich_certificate.pem | awk '/commonName/ { print $3 }')"
set +o errexit
"$rmq_ctl" add_user "$cn" password_unused
"$rmq_ctl" set_permissions "$cn" '.*' '.*' '.*'
set -o errexit

# Start Python program
python "$script_dir/mqtt.py"
