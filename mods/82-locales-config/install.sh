set -e                  # exit on error
set -o pipefail         # exit on pipeline error
set -u                  # treat unset variable as error

print_ok "Reconfiguring locales..."
# Restore the full SUPPORTED list in case update-locale narrowed it via debconf.
cat /usr/share/i18n/SUPPORTED > /etc/locale.gen
dpkg-reconfigure locales
judge "Reconfigure locales"

# If TIMEZONE was not set, exit.
if [ -z "$TIMEZONE" ]; then
    print_error "Error: TIMEZONE is not set."
    exit 1
fi

if [ ! -f /usr/share/zoneinfo/$TIMEZONE ]; then
    print_error "Error: /usr/share/zoneinfo/$TIMEZONE not found."
    exit 1
fi

print_ok "Configuring /etc/timezone to $TIMEZONE..."
echo $TIMEZONE > /etc/timezone
judge "Configure /etc/timezone"

print_ok "Configuring /etc/localtime to $TIMEZONE..."
rm -f /etc/localtime
ln -sf /usr/share/zoneinfo/$TIMEZONE /etc/localtime
judge "Configure /etc/timezone and /etc/localtime"


