#!/usr/bin/env python3

import gi
gi.require_version('Gtk', '3.0')
gi.require_version('WebKit2', '4.0')
from gi.repository import Gtk, WebKit2

class BrowserWindow(Gtk.Window):
    def __init__(self):
        super().__init__(title="Hello World - WebKitGTK")
        self.set_default_size(600, 400)

        view = WebKit2.WebView()
        view.load_html("<html><body><h1>Hello World!</h1></body></html>", None)

        scrolled = Gtk.ScrolledWindow()
        scrolled.add(view)
        self.add(scrolled)

win = BrowserWindow()
win.connect("destroy", Gtk.main_quit)
win.show_all()
Gtk.main()

