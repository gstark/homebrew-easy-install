#!/bin/bash
# sudo calls this helper when SUDO_ASKPASS is set (sudo -A).
# It must print the password to stdout.
/usr/bin/osascript <<'EOF'
set answer to display dialog "Homebrew Installer needs your Mac login password to continue." with title "Administrator Password" default answer "" with hidden answer buttons {"Cancel", "OK"} default button "OK" with icon caution
return text returned of answer
EOF
