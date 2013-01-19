This repo documents my backup strategy and contains a few somewhat reusable scripts.

# My backup strategy #

I feel this is a reasonably simple and secure strategy for daily full backups.
It doesn't account for incrementality.

On the production server, I write scripts to create backups of databases and other live things
into `/backup/staging`. The scripts moves finished backups to `/backup/ready`.

This two-stage setup has the following benefits.

- When backing up plain files, one can keep a copy in the staging dir
  and incrementally `rsync` it up to speed. This reduces the amount of copying needed.
- It prevents anyone from reading half-finished backups.
  Only an absurdly unlikely potential race condition of seeing a missing file remains.

The production server has a user+group called `backupreader`.
The backup server shall have passwordless SSH access to this user.
In the production server's `/etc/sshd_config` I limit this user to
SFTP only and chroot it to `/backup/ready` with the following configuration block.

    Match User backupreader
        ChrootDirectory /backup/ready
        AllowTcpForwarding no
        X11Forwarding no
        ForceCommand internal-sftp

The backup script should `chgrp backupreader` and `chmod g+rX` everything it puts in `/backup/ready`,
or ensure it as a suitable umask, to make sure the backups are readable.

Now the backup server has a cron'ed script like the following to fetch daily backups.

    #!/bin/sh
    cd `dirname "$0"`
    TIMESTAMP=`date +%Y%m%d`
    DEST=backups/$TIMESTAMP
    mkdir -p $DEST
    
    lftp -c "open sftp://backupreader:@my-server.com/; lcd $DEST; mirror"
    
    # After a week, get rid of every two backups.
    # After two weeks, only keep monday's and friday's backups.
    /path/to/backup-scripts/thin-backups.rb backups 7:1,3,5,7 14:1,5

### Why not just have the production server rsync backups to the backup server? ###

Security. If the production server is compromised, the attacker can (in theory) compromise previous backups.

# Scripts #

## thin-backups.rb ##

Removes old daily backups.
Can be configured to e.g. keep every only monday's and friday's backups when they are over two weeks old and
to keep only weekly backups when they are over a month old.

Run it without arguments for instructions.

## common.sh ##

To be included by other scripts on the production server.
Read it to see what it does, it's quite short.

Usage example:

    #!/bin/sh -e
    BACKUP_NAME=redmine
    . `dirname "$0"`/common.sh

    mysqldump -u redmine -predmine redmine | gzip > "$STAGING/redmine.sql.gz"
    rsync -av --delete /home/redmine/srv/redmine-2.1/files/ "$STAGING/files"
    rm -f "$STAGING/files.tar.gz"
    tar -C "$STAGING" -cpzf "$STAGING/files.tar.gz" files

    ready files.tar.gz redmine.sql.gz
