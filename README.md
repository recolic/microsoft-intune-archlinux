# Intune for Arch Linux

You have two options to access MSFT resources on Arch Linux.

1. Install level-1 & level-2, enroll your Arch machine.
2. Install level-1 & level-2 in another Ubuntu VM, enroll your Ubuntu VM. Install level-1 on your Arch, and copy certificate from Ubuntu to Arch.

## Install Level-1

> To **use** a certificate.

1. Install `libsdbus-c++0 msalsdk-dbusclient microsoft-identity-broker` packages in this repo. Note that they depends on `jre11-openjdk`. 
2. Install `microsoft-edge-stable-bin` from AUR. 
3. `[Temporary Fix]` Downgrade `tpm2-tss` to `3.2.0-1`, and add it to `IgnorePkg` in `/etc/pacman.conf`.

## Install Level-2 and enroll

> To **generate** a certificate.

> Note: Enrollment makes your machine managed. You must satisfy password requirements, and disk-encryption requirements. Ref: <https://aka.ms/LinuxPortal>

### For Ubuntu

Simply follow [the official guide](https://aka.ms/LinuxPortal)

### For Arch Linux

1. Install `intune-portal` packages in this repo. Don't forget to run `systemctl enable --user --now intune-agent.timer` after installation.
2. Follow [the official guide](https://aka.ms/LinuxPortal) to setup password policy file & disk encryption.
3. Copy the `/etc/os-release` file from ubuntu.
4. [none-gnome user only] Install `seahorse` and make sure you have a default keyring **with password**.
5. Run `intune-portal` to enroll your machine.

> For disk encryption settings, theoretically, dm-crypt (with or without LUKS) + LVM for root partition should be enough.

## Move certificates from Level-2 machine to Level-1 machine

> The certificate will usually expire, and get rotated in 1 month. 

Copy the following files from enrolled Level-2 machine to unenrolled Level-1 machine: 

```
/var/lib/microsoft-identity-device-broker/1000.db
/etc/machine-id
/home/YourName/.config/microsoft-identity-broker/account-data.db
/home/YourName/.config/microsoft-identity-broker/broker-data.db
/home/YourName/.config/microsoft-identity-broker/cookies.db
/home/YourName/.local/share/keyrings/login.keyring
```

**Reboot** to make sure gnome-keyring-daemon is using the latest keyring file. 

Then, run `seahorse` to double-confirm your "login" keyring is unlocked and non-empty. It may ask you to enter the previous login password. 

> You may change the password but DO NOT remove the password protection! There is a known bug <https://gitlab.gnome.org/GNOME/gnome-keyring/-/issues/103>

You are all set! 

## FAQ and debug

You should be able to log into Edge browser without password. If Edge is not happy, check the following logs: 

1. Any error message in `journalctl --user -u microsoft-identity-broker.service`?
2. Any error message in `sudo journalctl -u microsoft-identity-device-broker.service`? 
3. Run `seahorse` and is there Intune entries in your `login` keyring? Is it `set as default`? 
4. Run `ldd /usr/lib/libmsal_dbus_client.so`. Is there undefined reference? 

If you cannot do level-2 enroll, these additional logs might help:

1. Any error message in `intune-daemon.socket, intune-daemon.service, intune-agent.timer`?
2. Make sure `intune-daemon.socket` and user service `intune-agent.timer` is enabled.

If everything looks good, also check `journalctl -xe` and `sudo journalctl -xe` for other information.

### Common errors

- microsoft-identity-broker.service: Failed at step STATE_DIRECTORY spawning /opt/microsoft/identitybroker/bin/microsoft-identity-broker: Operation not permitted

This is a permission issue. Please run `chmod 777 -R /opt/microsoft` as root, **and** run `chown -R YourName /home/YourName/.config`, and restart the service. 

- microsoft-identity-broker.service: Failed to set up special execution directory in /home/YourName/.config: Operation not permitted

This is also a permission issue while overwritting user config with root account manually. Please run `chown -R YourName /home/YourName/.config` and restart the service. 

- Failed to decrypt with key:LinuxBrokerRegularUserSecretKey thumbprint, Tried all decryption keys and decryption still fails

Possible reason and solution:

1. Run `seahorse` and make sure your **default** keyring is unlocked, and contains **valid** certificates. 
2. The cert in keyring doesn't match `microsoft-identity-broker` database. If you just upgraded `microsoft-identity-broker` to a newer version, remove all existing database (including `msft-identity-broker`), and do level-1 installation again.

- Microsoft Edge crashed immediately on startup (SIGSEGV)

If your Microsoft Edge crashes immediately on startup because of SIGSEGV, and GDB shows `Thread 107 "ThreadPoolForeg" received signal SIGSEGV, Segmentation fault.`

Downgrade the `tpm2-tss` package to `3.2.0-1`, and add it into `IgnorePkg` to prevent it from being upgraded again.

- Everything seems fine, no error in log, but Edge still says `Not Syncing`

Sign out and sign in again.

- Cannot find directory `.../msft-identity-broker/...`

This directory was renamed from `msft-identity-broker` to `microsoft-identity-broker` in latest intune. Either upgrade your identity broker, or rename things manually (might be error-prone).

- Cannot log into intune-portal: something went wrong (2400)

Unknown reason. (TODO: RCA) Uninstall intune-portal and all other microsoft packages. Do `apt update` and install it again. It worked for me.

- Cannot log into intune-portal: something went wrong (1001)

This is not root cause. Check `journalctl -xe` for other error message.

If there is no other error, simply try again.

- Cannot log into intune-portal: Terms of use error. we couldn't sign you in.

On archlinux, if you get this error, please make sure your `/etc/os-release` is ubuntu. This is a sample:

```
NAME="Ubuntu"
VERSION="20.04.6 LTS (Focal Fossa)"
ID=ubuntu
ID_LIKE=debian
PRETTY_NAME="Ubuntu 20.04.6 LTS"
VERSION_ID="20.04"
HOME_URL="https://www.ubuntu.com/"
SUPPORT_URL="https://help.ubuntu.com/"
BUG_REPORT_URL="https://bugs.launchpad.net/ubuntu/"
PRIVACY_POLICY_URL="https://www.ubuntu.com/legal/terms-and-policies/privacy-policy"
VERSION_CODENAME=focal
UBUNTU_CODENAME=focal
```

If getting this problem on ubuntu... I don't know.

- intune-portal crashed after code 1200:

`rm -rf ~/.Microsoft ~/.cache/intune-portal` and try again.

- couldn't enroll your device. There was an expected error trying to enroll the device.

Terminal shows 400 bad request. I fixed this problem by `rm -rf ~/.Microsoft ~/.cache/intune-portal`, reinstall intune-portal, and enroll again.

- intune-portal white screen. journalctl shows: Unable to save to Keyring. Likely because there is no default keyring set on the machine. 

Install seahorse, create a "password keyring". You MUST set a password (because of a known bug mentioned above) and then set it as default.

- intune-portal white screen on Manjaro: libEGL warning: egl: failed to create dri2 screen

This is not the root cause. ArchLinux has the same error message, and everything works. `journalctl -xe` shows no error message at all.

I resolved this problem by setting correct `/etc/os-release` file.

- intune-portal white screen: glx: failed to create drisw screen; failed to load driver: zink

This is not the root cause. ArchLinux has the same error message, and everything works. `journalctl -xe` shows no error message at all.

I resolved this problem by setting correct `/etc/os-release` file.

- intune-portal says not compliant: Upgrade to a supported distributions...

Run `journalctl | grep intune-agent | grep Reporting` to check what is intune-agent telling intune-portal. If you already updated `/etc/os-release` but intune-portal is not updated, please run `systemctl enable --user --now intune-agent.timer` manually.

- intune-agent: Failed to checkin with intune. Failed updating device inventory details with Intune: Unexpected failure: Bad request (Error code 308)

TODO...

## Tested on

> fresh OS installation

|Env                        |Version|Tested         |
|---------------------------|-------|---------------|
|Arch Linux + Xorg Gnome    |2024.01|Level1 + Level2|
|Arch Linux + Xorg Xfce4    |2024.01|Level1 + Level2|
|Manjaro Linux + Wayland KDE|240113 |Level1 + Level2|

