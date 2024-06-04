#!/bin/bash

function i () {
    cd "$1" &&
        makepkg -i
}

sudo pacman -Sy --noconfirm --asdeps jre11-openjdk
( i libsdbus-c++0 )
( i microsoft-identity-broker )
( i msalsdk-dbusclient )

