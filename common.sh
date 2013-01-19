# Included by other backup scripts

cd `dirname "$0"`

if [ -z "$BACKUP_NAME" ]; then
  echo "BACKUP_NAME not set when including common.sh"
  exit 1
fi

STAGING="/backup/staging/$BACKUP_NAME"
READY="/backup/ready/$BACKUP_NAME"
mkdir -p "$STAGING" "$READY"

ready() {
  for file in $@; do
    local FROM="$STAGING/$file"
    local TO="$READY/$file"
    echo "Moving $FROM -> $TO"
    mv -f "$FROM" "$TO"
    chgrp backupreader "$TO"
    chmod g+rX "$TO"
  done
}
