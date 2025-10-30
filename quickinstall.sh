#!/bin/bash

function i () {
    cd "$1" &&
        makepkg -i
}

sudo pacman -Sy --noconfirm --asdeps --needed webkit2gtk opensc
( i microsoft-identity-broker )
( i intune-portal )

echo "Done. Don't forget to run 'systemctl enable --user --now intune-agent.timer' and follow the rest steps."

