# webkit2gtk issue demo

You are hitting errorCode 1001, and `sudo journalctl -xe` shows:

```
Oct 30 00:49:56 RECOLICPC gnome-shell[23913]: WL: error in client communication (pid 26559)
Oct 30 00:49:56 RECOLICPC microsoft-identity-broker[26559]: Error 71 (Protocol error) dispatching to Wayland display.
```

## RCA

microsoft-identity-device-broker tried to create a window but webkit2gtk somehow fails. This is a minimal repro to validate your issue.

You may run either python version or C++ version (whichever easier for you).

It's your Desktop Environment issue, not intune issue. It's your responsibility to debug and fix your desktop environment.

## Solution for Arch+NVIDIA

Set `WEBKIT_DISABLE_DMABUF_RENDERER="1"` in /etc/environment. Credit: [greg](https://git.recolic.net/root/microsoft-intune-archlinux/-/issues/2)
