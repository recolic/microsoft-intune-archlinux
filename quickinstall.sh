#!/bin/bash

function i () {
    cd "$1" &&
        makepkg -i
}

sudo pacman -Sy --noconfirm --asdeps jre11-openjdk openssl-1.1 webkitgtk
( i libsdbus-c++0 )
( i microsoft-identity-broker )
( i msalsdk-dbusclient )
( i intune-portal )

echo "Done. Don't forget to run 'systemctl enable --user --now intune-agent.timer' and follow the rest steps."

