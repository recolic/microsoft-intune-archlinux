#!/bin/bash

function i () {
    cd "$1" &&
        makepkg -i &&
        cd -
}

i libsdbus-c++0
i msft-identity-broker
i msalsdk-dbusclient

