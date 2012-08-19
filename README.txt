My miscellaneous somewhat reusable backup scripts.

## thin-backups.rb ##

Removes old daily backups.
Can be configured to e.g. keep every only monday's and friday's backups when they are over two weeks old and
to keep only weekly backups when they are over a month old.

Run it without arguments for instructions.

## make-rssh-jail.sh ##

Usage:

    sudo make-rssh-jail.sh <jaildir> <username>

Deletes `bin`, `lib`, `lib64` and `usr` in `<jaildir>`
copies over `scp`, `sftp-server', `rsync` and `rssh_chroot_helper` with any libraries they need.
Creates `/etc/passwd` in the chroot containing the entry for `<username>`.
Also creates a `/dev/null` as it's needed by `scp` and `sftp`.
Useful for setting up an [rssh](http://www.pizzashack.org/rssh/) jail for serving backups.

This script probably only works on Debian/Ubuntu.
