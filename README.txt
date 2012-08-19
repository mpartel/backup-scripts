My miscellaneous somewhat reusable backup scripts.

## thin-backups.rb ##

Removes old daily backups.
Can be configured to e.g. keep every only monday's and friday's backups when they are over two weeks old and
to keep only weekly backups when they are over a month old.

Run it without arguments for instructions.

## make-rssh-jail.sh ##

Usage:

    sudo make-rssh-jail.sh <jaildir>

Deletes `<jaildir>/bin`, `<jaildir>/lib` and `<jaildir>/lib64` then
copies over `sftp`, `scp` and `rsync` with any libraries they need.
Also creates a /dev/null as it's needed by `scp` and `sftp`.
Useful for setting up an [rssh](http://www.pizzashack.org/rssh/) jail for serving backups.
