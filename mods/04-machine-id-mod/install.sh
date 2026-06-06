set -e                  # exit on error
set -o pipefail         # exit on pipeline error
set -u                  # treat unset variable as error

print_ok "Installing dbus and uuid-runtime..."
apt install $INTERACTIVE \
    dbus \
    uuid-runtime
judge "Install dbus and uuid-runtime"

print_ok "Configuring machine id..."
dbus-uuidgen > /etc/machine-id
ln -fs /etc/machine-id /var/lib/dbus/machine-id
judge "Configure machine id"