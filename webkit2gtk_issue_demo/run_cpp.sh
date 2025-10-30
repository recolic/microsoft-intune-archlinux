#!/bin/bash
g++ poc.cc -o /tmp/poc.exe $(pkg-config --cflags --libs gtk+-3.0 webkit2gtk-4.1)
/tmp/poc.exe
