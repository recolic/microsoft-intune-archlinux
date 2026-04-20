# Troubleshoot steps / How to setup (PIV) smartcard for intune-portal (Arch Linux)

Refer to Microsoft official doc before asking any question: https://learn.microsoft.com/en-us/entra/identity/devices/sso-linux

## step 0 - install shits

> Just taking Yubikey as example. ANY PIV smartcard works in similar way.

Before all, please make sure you have installed: 

`pacman -S pcsclite opensc nss p11-kit yubikey-manager openssl`

make sure you have `microsoft-identity-broker > 2.0.2`.

## [step 1-competitor] `ps aux | grep scdaemon` should NOT be running.

scdaemon is alive? It's for GPG. To temporarily disable it, add `disable-scdaemon` into `~/.gnupg/gpg-agent.conf` then `gpg-connect-agent reloadagent /bye`

## [step 2-middleware] `systemctl status pcscd` should be running, and 

pcscd not running? please install pcscd and enable it.

> `LIBUSB_ERROR_BUSY` error? double check if your step-1 works.

## [step 3-hardware] `ykman piv info` should show your yubikey and cert.

no yubikey? Refer to other guide about "why my yubikey doesn't work".

no cert? Ask your employer/university "Hey how to setup my yubikey".

## [step 4-middleware] `pkcs15-tool --list-certificates` should show your yubikey.

No? Fix TODO

## [step 5-software] `modutil -list -dbdir $HOME/.pki/nssdb/` should show `opensc-pkcs11.so` and your yubikey.

No? Fix by running this. Note: archlinux has a different opensc-pkcs11.so path.

```
mkdir -p $HOME/.pki/nssdb
chmod 700 $HOME/.pki
chmod 700 $HOME/.pki/nssdb
modutil -force -create -dbdir sql:$HOME/.pki/nssdb
modutil -force -dbdir sql:$HOME/.pki/nssdb -add 'SC Module' -libfile /usr/lib/pkcs11/opensc-pkcs11.so
```

## [step 6-software] `p11-kit list-modules` should show `opensc-pkcs11.so` and the cert in your yubikey.

No? Fix by running this. Reason: archlinux has a different opensc-pkcs11.so path.

```
sudo mkdir -p /etc/pkcs11/modules
echo "module: /usr/lib/pkcs11/opensc-pkcs11.so" | sudo tee /etc/pkcs11/modules/opensc.module
```

