#!/bin/bash -e

if [ -z "$1" -o -z "$2" ]; then
    echo "Usage: update-jail.sh <jaildir> <username>"
    exit 1
fi

DESTDIR="$1"
USERNAME="$2"

if `echo "$DESTDIR" | egrep -q -x '/*'`; then
    echo "Whoa! I'm not gonna destroy your root directory."
    exit 1
fi

if [ `whoami` != 'root' ]; then
    echo "This must be run as root."
    exit 1
fi

mkdir -p "$DESTDIR"
cd "$DESTDIR"
rm -Rf bin lib lib64 usr
mkdir bin lib lib64 usr

add_binary_deps() {
    local BIN=$1
    local LIBS
    local LIB
    local VER
    
    ldd "$BIN" | egrep -o '=> (..*) \(0x.*\)' | sed 's/=> //' | sed 's/ (.*)$//' > libs.txt
    LIBS=`cat libs.txt | sort`
    rm libs.txt
    for LIB in $LIBS; do
        local BASENAME=`echo $LIB | sed s/[.]so.*$//`
        for VER in `ls -1 $BASENAME* | sort`; do
            echo "$VER" "=>" "`pwd`$VER"
            cp -fpP --parents "$VER" ./
        done
    done
}

echo "Copying binaries and their libraries"

BINARIES="/usr/bin/scp /usr/bin/rsync /usr/lib/openssh/sftp-server /usr/lib/rssh/rssh_chroot_helper"

for BIN in $BINARIES; do
    cp -vfp --parents "$BIN" ./
    add_binary_deps "$BIN"
done

echo "Making rssh_chroot_helper SUID in the chroot AND the main system"
chmod +s ./usr/lib/rssh/rssh_chroot_helper
chmod +s /usr/lib/rssh/rssh_chroot_helper

echo "Making passwd file"
mkdir -p ./etc
cat /etc/passwd | grep "$USERNAME" > ./etc/passwd

glob_exists_in() {
    test -d "$2" && test -n "$(find "$2" -maxdepth 1 -name "$1" -print -quit)"
}

echo "Copying dynamic linker libs"
if `glob_exists_in 'ld-*' '/lib'`; then
    cp -vfpP /lib/ld-* lib/
fi
if `glob_exists_in 'ld-*' '/lib/i386-linux-gnu'`; then
    cp -vfpP --parents /lib/i386-linux-gnu/ld-* ./
fi
if `glob_exists_in 'ld-*' '/lib/x86_64-linux-gnu'`; then
    cp -vfpP --parents /lib/x86_64-linux-gnu/ld-* ./
fi
if `glob_exists_in 'ld-*' '/lib64'`; then
    cp -vfpP --parents /lib64/ld-* ./
fi

echo "Creating /dev/null"
mkdir -p dev
rm -f dev/null
mknod dev/null c 1 3
chmod a+rw dev/null
