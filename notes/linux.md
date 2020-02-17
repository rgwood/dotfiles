# Linux notes

## Version

`lsb_release -a`

## Ubuntu
Setting up SSH: needed to install SSH daemon `sudo apt-get install ssh`.

## Fedora

sshd already installed, needed to start it up

* `systemctl status sshd`
* `systemctl start sshd`

Enable it permanently: `systemctl enable sshd`

### OSQuery install
Official yum/RPM instructions:
```bash
curl -L https://pkg.osquery.io/rpm/GPG | sudo tee /etc/pki/rpm-gpg/RPM-GPG-KEY-osquery
sudo yum-config-manager --add-repo https://pkg.osquery.io/rpm/osquery-s3-rpm.repo
sudo yum-config-manager --enable osquery-s3-rpm
sudo yum install osquery
```

Needed to tweak that slightly - Fedora now uses `dnf` instead of `yum`.

```
curl -L https://pkg.osquery.io/rpm/GPG | sudo tee /etc/pki/rpm-gpg/RPM-GPG-KEY-osquery
sudo dnf config-manager --add-repo https://pkg.osquery.io/rpm/osquery-s3-rpm.repo
sudo dnf install osquery
```

### Fish shell

Installed Fish and made it my default shell. `chsh` is the usual command to change shells but it's not installed by default, argh.

```bash
# Install chsh
sudo dnf install util-linux-user
# Use Fish by default
chsh -s /usr/bin/fish
```

### Permissions and Users

By default, can’t read /var/lib/pgsql directory with my regular account - that’s a giant pain.

Fix: add myself (the “parallels” account) to the postgres group and grant group read+execute permissions on everything in the folder. Can’t give write access to the group, Postgres doesn't allow that.

Users and their group IDs: stored in `/etc/passwd`. Fields separated by colons:

1. Username
1. Password: An x character indicates that encrypted password is stored in /etc/shadow file.
1. User ID (UID): Each user must be assigned a user ID (UID). UID 0 (zero) is reserved for root and UIDs 1-99 are reserved for other predefined accounts. Further UID 100-999 are reserved by system for administrative and system accounts/groups.
1. Group ID (GID): The primary group ID (stored in /etc/group file)
1. User ID Info: The comment field. It allow you to add extra information about the users such as user’s full name, phone number etc. This field use by finger command.
1. Home directory: The absolute path to the directory the user will be in when they log in. If this directory does not exists then users directory becomes /
1. Command/shell

Easy to see group membership with `groups username`

```bash
# Add parallels user to postgres group
usermod -aG postgres parallels
# Grant group permissions to everything in the Postgres folder
chmod -R g+rx /var/lib/pgsql
```
Then login/logout.

Change group ownership: `chgrp groupname directorypath`

## DNF/Yum

Can browse packages with `dnf search`. For example:

`dnf search java | grep -e 'java.*openjdk'`

## System logs

Use `journalctl` to view. Good cheat sheet: https://www.cheatography.com/airlove/cheat-sheets/journalctl/

`-b` to show current boot messages.

`jour­nalctl -p err`
Shows you all messages marked as error, critical, alert, or emerge­ncy