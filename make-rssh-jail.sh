#!/bin/bash -e

if [ -z "$1" ]; then
    echo "Usage: update-jail.sh <jaildir>"
    exit 1
fi

DESTDIR="$1"

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
rm -Rf bin lib lib64
mkdir bin lib lib64

add_binary() {
    local BIN=$1
    local LIBS
    local LIB
    local VER
    
    echo `which "$BIN"` "=>" "`pwd`/$BIN"
    cp -fp `which "$BIN"` ./bin/
    
    ldd `which $BIN` | egrep -o '=> (..*) \(0x.*\)' | sed 's/=> //' | sed 's/ (.*)$//' > libs.txt
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
add_binary sftp
add_binary scp
add_binary rsync

glob_exists_in() {
    test -n "$(find "$2" -maxdepth 1 -name "$1" -print -quit)"
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
