#!/bin/bash

cd `dirname "$0"`

for i in ./backup-*.sh; do
  if [ -x "$i" -a "$i" != "./backup-all.sh" ]; then
    $i
  fi
done
