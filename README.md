# Intune for Arch Linux

> **This repo will stay outdated until it stops working.** Intune is already buggy and let's don't break it further!!

You have two options to access MSFT resources on Arch Linux.

1. Install level-1 & level-2, enroll your Arch machine.
2. Install level-1 & level-2 in another Ubuntu VM, enroll your Ubuntu VM. Install level-1 on your Arch, and copy certificate from Ubuntu to Arch.

## Install Level-1

> To **use** a certificate.

> Disclaimer: AUR `microsoft-identity-broker-bin` and `intune-portal-bin` were not maintained by me. But I tested, they works perfectly fine.

1. Install `microsoft-identity-broker` packages in this repo. (Use quickinstall.sh as your will)
2. Install `microsoft-edge-stable-bin` from AUR. 
3. `[Temporary Fix]` Downgrade `tpm2-tss` to `3.2.0-1`, and add it to `IgnorePkg` in `/etc/pacman.conf`.

## Install Level-2 and enroll

> To **generate** a certificate.

> Note: Enrollment makes your machine managed. You must satisfy password requirements, and disk-encryption requirements. Ref: <https://aka.ms/LinuxPortal>

### For Ubuntu

For MS employee, follow [MS official guide](https://aka.ms/LinuxPortal).

For other organizations, follow official guide from your org. Ubuntu should be officially supported by them.

### For Arch Linux

1. Install `intune-portal` packages in this repo. Don't forget to run `systemctl enable --user --now intune-agent.timer` after installation.(Use quickinstall.sh as your will)
2. Follow ubuntu guide above to setup password policy file & disk encryption, or any requirements from your org.
3. Copy the `/etc/os-release` file from ubuntu.
4. If `lsb_release` is present in your system, uninstall or destroy it.
5. [none-gnome user only] Install `seahorse` and make sure you have a default keyring **with password**. ([why?](https://gitlab.gnome.org/GNOME/gnome-keyring/-/issues/103))
6. `[Temporary Fix]` Run [fix-libssl.sh](./fix-libssl.sh) and follow instructions.
7. Run `intune-portal` to enroll your machine.

> For disk encryption settings, theoretically, dm-crypt (with or without LUKS) + LVM for root partition should be enough.

## Move certificates from Level-2 machine to Level-1 machine

> **This is not recommended, as certificate expires in 1 month & requires frequent manual maintenance.**

<details><summary>See Details</summary>

Copy the following files from enrolled Level-2 machine to unenrolled Level-1 machine: 

```
# TODO: double confirm if this guide still works for broker v2
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

</details>

## FAQ and debug

You should be able to log into Edge browser without password. If Edge is not happy, check the following logs: 

1. Any error message in `sudo journalctl -u microsoft-identity-device-broker.service`? 
2. Run `seahorse` and is there Intune entries in your `login` keyring? Is it `set as default`? 

If you cannot do level-2 enroll, these additional logs might help:

1. Any error message in `intune-daemon.socket, intune-daemon.service, intune-agent.timer`?

If everything looks good, also check `journalctl -xe` and `sudo journalctl -xe` for other information.

<!-- for old broker 1.x
### Known bugs

- Memory Leak / High RAM usage

microsoft-intune-device broker service is known to be eating memory. It will eat all your RAM if running long enough. Use whatever script you like to run the following command every 12 hours:

```
# Leaks a lot
sudo systemctl restart microsoft-identity-device-broker.service
# Leaks little
systemctl restart --user microsoft-identity-broker.service
```
-->

### Common errors

<!-- for old broker 1.x
- microsoft-identity-broker.service: Failed at step STATE_DIRECTORY spawning /opt/microsoft/identitybroker/bin/microsoft-identity-broker: Operation not permitted

This is a permission issue. Please run `chmod 777 -R /opt/microsoft` as root, **and** run `chown -R YourName /home/YourName/.config`, and restart the service. 

- microsoft-identity-broker.service: Failed to set up special execution directory in /home/YourName/.config: Operation not permitted

This is also a permission issue while overwritting user config with root account manually. Please run `chown -R YourName /home/YourName/.config` and restart the service. 

- Failed to decrypt with key:LinuxBrokerRegularUserSecretKey thumbprint, Tried all decryption keys and decryption still fails

Possible reason and solution:

1. Run `seahorse` and make sure your **default** keyring is unlocked, and contains **valid** certificates. 
2. The cert in keyring doesn't match `microsoft-identity-broker` database. If you just upgraded `microsoft-identity-broker` to a newer version, remove all existing database (including `msft-identity-broker`), and do level-1 installation again.

- Cannot find directory `.../msft-identity-broker/...`

This directory was renamed from `msft-identity-broker` to `microsoft-identity-broker` in latest intune. Either upgrade your identity broker, or rename things manually (might be error-prone).
-->

- microsoft-identity-device-broker.service: StatusInternal::KeyNotFound, Crypto key not found

Install `opensc` and insert your Yubikey. This is necessary even if you are not going to use Yubikey auth.

- Microsoft Edge crashed immediately on startup (SIGSEGV)

If your Microsoft Edge crashes immediately on startup because of SIGSEGV, and GDB shows `Thread 107 "ThreadPoolForeg" received signal SIGSEGV, Segmentation fault.`

Downgrade the `tpm2-tss` package to `3.2.0-1`, and add it into `IgnorePkg` to prevent it from being upgraded again.

RCA: `ldd libmip_core.so` in Edge installation directory, you can see it depends on old tpm2-tss.

- Everything seems fine, no error in log, but Edge still says `Not Syncing`

Sign out and sign in Edge again.

- Cannot log into intune-portal: something went wrong (2400)

Unknown reason. (TODO: RCA) Uninstall intune-portal and all other microsoft packages. Do `apt update` and install it again. It worked for me.

- Cannot log into intune-portal: something went wrong (1001)

This is not root cause. Check `journalctl -xe` for other error message.

- Cannot log into intune-portal: errorCode 1001, WL: error in client communication

> Also known as: Error 71 (Protocol error) dispatching to Wayland display.

Ref: [Click for details](webkit2gtk_issue_demo/README.md)

If there is no other error, simply try again. (reboot works for me)

- Cannot log into intune-portal: Terms of use error. we couldn't sign you in.

Please check program output. It should be one of the following two errors:

- Error calling IWS for Terms of Use: Unexpected failure: Internal Server Error

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

If you have `lsb_release` installed, please uninstall or destroy this program. Updating `/etc/lsb-release` is not enough.

```
sudo mv /usr/bin/lsb_release /usr/bin/lsb_release.backup
```

You can also write a fake `/usr/bin/lsb_release`. Just make sure the output matches real Ubuntu.

- Error calling IWS for Terms of Use: Network or I/O operation failed ; unrecognized public key / BadCertificate

Downgrade your openssl to 3.3.4 or older. Please use [fix-libssl.sh](./fix-libssl.sh) instead of your package manager to avoid breaking other programs.

[Error Screenshot](.res/1.png)

<details><summary>Detailed RCA</summary>

```
Fucking OpenSSL upstream intentionally introduced this bug:
https://github.com/openssl/openssl/pull/23965

at this commit (included since openssl 3.4.0):
397051a40db2d68433b842e7505e8cf3c9effb36 (main)

Observed regression in other projects such as:
https://github.com/ruby/openssl/issues/734

Solution 1: Downgrade to openssl-3.3.4
Solution 2: Write libssl_fix.so with a good version of that tiny function, use LD_PRELOAD to shadow the original buggy impl.
```
</details>

- Couldnt enroll your device: X509\_REQ\_set\_version:passed invalid argument:crypto/x509/x509set.c

Same as previous issue.

Downgrade your openssl to 3.3.4 or older. Please use [fix-libssl.sh](./fix-libssl.sh) instead of your package manager to avoid breaking other programs.

[Error Screenshot](.res/2.png)

- Cannot log into intune-portal: Login box doesn't show up. Stuck at white screen.

Try reboot. It works for me.

- intune-portal 400 Bad Request, Couldnt enroll your device (or Open Company Portal and run a check on your device to get a current status)

Follow the `How to delete MS account login cache` guide below, and try again.

If you are using intune-portal older than `1.2404.23`, please upgrade your intune-portal.

- couldn't enroll your device. There was an expected error trying to enroll the device.

Same as previous issue.

- We're still checking if you can access company resources.

Just wait for a few seconds and click "Refresh".

- intune-portal white screen. journalctl shows: Unable to save to Keyring. Likely because there is no default keyring set on the machine. 

Install seahorse, create a "password keyring". You MUST set a password (because of a known bug mentioned above) and then set it as default.

- intune-portal white screen during login (after email address, before password)

Check if systemctl shows any java exception. It could be device broker service issue.

Try the `How to delete existing enrollment data and enroll from fresh` guide below.

- intune-portal white screen on Manjaro: libEGL warning: egl: failed to create dri2 screen

This is not the root cause. ArchLinux has the same error message, and everything works. `journalctl -xe` shows no error message at all.

- intune-portal white screen: glx: failed to create drisw screen; failed to load driver: zink

This is not the root cause. ArchLinux has the same error message, and everything works. `journalctl -xe` shows no error message at all.

- intune-portal says not compliant: Upgrade to a supported distributions...

Run `journalctl | grep intune-agent | grep Reporting` to check what is intune-agent telling intune-portal. If you already updated `/etc/os-release` but intune-portal is not updated, please run `systemctl enable --user --now intune-agent.timer` manually.

- intune-agent: Failed to checkin with intune. Failed updating device inventory details with Intune: Unexpected failure: Bad request (Error code 308)

TODO...

- intune-portal says not compliant: Sync your device with Intune

If getting this error message `Non-compliant status indicated by IWS issues=[("Sync your device with Intune", "Open Company Portal and run a check on your device to get a current status."`, please:

1. Search for intune-agent output starting with: `Reporting status to Intune statuses`. Make sure all items are compliant. (usually they are all good)
2. Simply wait for a moment and try again.

Sometimes, problem will disappear after few seconds. But it could take more than 20 minutes to fix (depending on the intune server). Be patient.

- intune-portal white screen `Failed to create GBM buffer of size 456x551: Invalid argument`

If you get this error when clicking `sign-in`, please try:

Set env `export WEBKIT_DISABLE_DMABUF_RENDERER=1`. Ref: [link](https://bugs.webkit.org/show_bug.cgi?id=259644)

Example:

```
WEBKIT_DISABLE_DMABUF_RENDERER=1 /opt/microsoft/intune/bin/intune-portal
```

Ref: <https://github.com/recolic/microsoft-intune-archlinux/issues/3>

- intune-portal is too old in this repo

I will not upgrade it until it stops working.

- intune-portal SIGSEGV, cannot register URI scheme oneauth more than once

Please retry. Be patient, trust me, you keep trying, it will eventually work.

Updating intune-portal won't help. I already tried.

### FAQ & Tricks

- How to delete MS account login cache?

```
rm -rf ~/.Microsoft ~/.cache/intune-portal ~/.config/intune
```

- How to delete existing enrollment data and enroll from fresh?

```
# TODO: double confirm if this guide still works for broker v2
rm -rf ~/.config/microsoft-identity-broker
sudo rm -rf /var/lib/microsoft-identity-device-broker
rm -f ~/.local/state/log/microsoft-identity-broker
mkdir -p ~/.config/microsoft-identity-broker

sudo systemctl restart microsoft-identity-device-broker.service
```

Then run `intune-portal`.

## Tested on

> fresh OS installation

|Env                        |Version|Tested         |
|---------------------------|-------|---------------|
|Arch Linux + Xorg Gnome    |2024.01|Level1 + Level2|
|Arch Linux + Xorg Xfce4    |2024.01|Level1 + Level2|
|Manjaro Linux + Wayland KDE|240113 |Level1 + Level2|
|Arch Linux + Wayland Gnome |2024.02|Level1 + Level2|

