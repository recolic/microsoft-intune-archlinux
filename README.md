# Intune for Archlinux

There are two levels of Intune Setup. 

After installing level-1, you can access everything with certificate copied from a level-2 machine.   
After installing level-2, you can actually enroll the machine and get a certificate. 

## Install Level-1

1. Install `libsdbus-c++0 msalsdk-dbusclient microsoft-identity-broker` packages in this repo. Note that they depends on `jre11-openjdk`. 
2. Install `microsoft-edge-stable-bin` from AUR. 
3. `[Temporary Fix]` Downgrade `tpm2-tss` to `3.2.0-1`, and add it to `IgnorePkg` in `/etc/pacman.conf`.

## Install Level-2 and enroll

> Installing level-2 components will make your machine managed. You must satisfy password requirements, and disk-encryption requirements. Ref: <https://aka.ms/LinuxPortal>

Use a Ubuntu **20.04** VM to perform level-2 enroll. ArchLinux level-2 enroll is theoretically supported, but I never tested it. 

1. install intune-portal and its dependencies (pwquality)
2. copy /etc/os-release from ubuntu 2004 to archlinux
3. make sure you followed procedure of official doc

It's suggested to keep the Ubuntu VM powered-on forever, to keep the certificate valid. 

> Note: modifying `/etc/os-release` might cause problem for dkms. Run `[[ -f /usr/bin/dkms ]] && sed -i 's/sign_file=[^ ]*$/sign_file=Iamnotubuntudonotlookforsignfileplease /g' /usr/bin/dkms` if you are getting dkms error.

## Move certificates from Level-2 machine to Level-1 machine

> You need to keep your level-2 machine running, or your certificate will invalidate in 1 month. 

Copy the following files from enrolled Level-2 machine to unenrolled Level-1 machine: 

```
/var/lib/microsoft-identity-device-broker/1000.db
/etc/machine-id
/etc/os-release # Note: this is a symbol-link in ubuntu
/home/YourName/.config/microsoft-identity-broker/account-data.db
/home/YourName/.config/microsoft-identity-broker/broker-data.db
/home/YourName/.config/microsoft-identity-broker/cookies.db
/home/YourName/.local/share/keyrings/login.keyring
```

**Reboot** to make sure gnome-keyring-daemon is using the latest keyring file. 

Then, run `seahorse` to double-confirm your "login" keyring is unlocked and non-empty. It may ask you to enter the previous login password. 

> You could change the password but DO NOT remove the password protection! There is a known bug <https://gitlab.gnome.org/GNOME/gnome-keyring/-/issues/103>

You are all set! 

## FAQ and debug

If your edge browser is not allowing you to login, check the following logs: 

1. Any error message in `journalctl --user -u microsoft-identity-broker.service`?
2. Any error message in `sudo journalctl -u microsoft-identity-device-broker.service`? 
3. Run `seahorse` and is there Intune entries in your `login` keyring? Is it `set as default`? 
4. Run `ldd /usr/lib/libmsal_dbus_client.so`. Is there undefined reference? 

### Common errors

#### ArchLinux side

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

#### Ubuntu side (officially supported)

- Cannot log into intune-portal, something went wrong (2400)

Uninstall intune-portal and all other microsoft packages. Do `apt update` and install it again.

- Cannot log into intune-portal, something went wrong (1001)

Simply try again. It will work.

