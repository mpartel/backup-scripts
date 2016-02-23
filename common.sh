# Included by other backup scripts

cd `dirname "$0"`

if [ -z "$BACKUP_NAME" ]; then
  echo "BACKUP_NAME not set when including common.sh"
  exit 1
fi

STAGING="/backup/staging/$BACKUP_NAME"
READY="/backup/ready/$BACKUP_NAME"
mkdir -p "/backup/ready"
mkdir -p "$STAGING"

move_staging_to_ready() {
  chgrp backupreader "$STAGING"
  chmod g+rX "$STAGING"

  echo "Moving $STAGING to $READY"
  [ -d "$READY" ] && mv "$READY" "$READY.old"
  mv "$STAGING" "$READY"
  echo "Clearing $READY.old"
  rm -Rf "$READY.old"
}
