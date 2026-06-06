set -e                # exit on error
set -o pipefail       # exit on pipeline error
set -u                # treat unset variable as error

if [ "$FIREFOX_PROVIDER" == "none" ]; then
    print_ok "We don't need to install firefox, please check the config file"
elif [ "$FIREFOX_PROVIDER" == "official_apt" ]; then
    print_ok "Setting up official Mozilla APT repository for Firefox"
    wait_network

    print_ok "Creating APT keyrings directory..."
    install -d -m 0755 /etc/apt/keyrings
    judge "Create keyrings directory"

    print_ok "Importing Mozilla APT repository signing key..."
    wget -q https://packages.mozilla.org/apt/repo-signing-key.gpg -O- | tee /etc/apt/keyrings/packages.mozilla.org.asc > /dev/null
    judge "Import signing key"

    print_ok "Verifying key fingerprint..."
    FINGERPRINT_CHECK=$(gpg --show-keys --with-colons /etc/apt/keyrings/packages.mozilla.org.asc 2>/dev/null | grep '^fpr' | cut -d: -f10)
    if [ "$FINGERPRINT_CHECK" = "35BAA0B33E9EB396F59CA838C0BA5CE6DC6315A3" ]; then
        print_ok "Key fingerprint matches."
    else
        print_error "Fingerprint verification FAILED! Expected '35BAA0B33E9EB396F59CA838C0BA5CE6DC6315A3' but got '$FINGERPRINT_CHECK'"
        exit 1
    fi
    judge "Verify key fingerprint"

    print_ok "Adding Mozilla APT repository source..."
    echo "deb [signed-by=/etc/apt/keyrings/packages.mozilla.org.asc] https://packages.mozilla.org/apt mozilla main" | tee /etc/apt/sources.list.d/mozilla.list > /dev/null
    if [ -n "$BUILD_FIREFOX_MIRROR" ]; then
        print_ok "Replacing packages.mozilla.org with build mirror: $BUILD_FIREFOX_MIRROR"
        sed -i "s|packages.mozilla.org|$BUILD_FIREFOX_MIRROR|g" /etc/apt/sources.list.d/mozilla.list
    fi
    judge "Add APT source"

    print_ok "Configuring APT preferences for Firefox..."
    cat << EOF > /etc/apt/preferences.d/mozilla-firefox
# Prioritize packages from the official Mozilla repository
Package: *
Pin: origin packages.mozilla.org
Pin-Priority: 1000

# Block the transitional Snap package from Ubuntu repositories
Package: firefox*
Pin: release o=Ubuntu*
Pin-Priority: -1
EOF
    if [ -n "$BUILD_FIREFOX_MIRROR" ]; then
        sed -i "s/packages.mozilla.org/$BUILD_FIREFOX_MIRROR/g" /etc/apt/preferences.d/mozilla-firefox
    fi
    chown root:root /etc/apt/preferences.d/mozilla-firefox
    judge "Configure APT preferences"

    print_ok "Updating package list..."
    apt update
    judge "Update package list"

    print_ok "Installing Firefox and locale package $FIREFOX_LOCALE_PACKAGE from official Mozilla repo"
    apt install $INTERACTIVE firefox $FIREFOX_LOCALE_PACKAGE --no-install-recommends
    judge "Install Firefox"

    # Handle live mirror replacement for the final image
    if [ -n "$BUILD_FIREFOX_MIRROR" ] && [ -n "$LIVE_FIREFOX_MIRROR" ]; then
        print_ok "Replacing build mirror $BUILD_FIREFOX_MIRROR with live mirror $LIVE_FIREFOX_MIRROR..."
        sed -i "s/$BUILD_FIREFOX_MIRROR/$LIVE_FIREFOX_MIRROR/g" /etc/apt/sources.list.d/mozilla.list
        sed -i "s/$BUILD_FIREFOX_MIRROR/$LIVE_FIREFOX_MIRROR/g" /etc/apt/preferences.d/mozilla-firefox
        judge "Replace build mirror with live mirror"
    elif [ -n "$LIVE_FIREFOX_MIRROR" ]; then
        print_ok "Replacing packages.mozilla.org with live mirror $LIVE_FIREFOX_MIRROR..."
        sed -i "s/packages.mozilla.org/$LIVE_FIREFOX_MIRROR/g" /etc/apt/sources.list.d/mozilla.list
        sed -i "s/packages.mozilla.org/$LIVE_FIREFOX_MIRROR/g" /etc/apt/preferences.d/mozilla-firefox
        judge "Replace official URL with live mirror"
    else
        print_warn "No LIVE_FIREFOX_MIRROR set, skip replacing mirror"
    fi
else
    print_error "Unknown firefox provider: $FIREFOX_PROVIDER"
    print_error "Valid providers: none, official_apt"
    exit 1
fi
