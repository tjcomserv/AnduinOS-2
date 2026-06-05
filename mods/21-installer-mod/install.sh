set -e                  # exit on error
set -o pipefail         # exit on pipeline error
set -u                  # treat unset variable as error

print_ok "Installing AnduinOS installer (Ubiquity + wrapper + slides + bwrap compat)..."
wait_network
apt install $INTERACTIVE anduinos-installer-config --no-install-recommends
judge "Install anduinos-installer-config"
