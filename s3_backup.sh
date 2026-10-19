#!/bin/bash
# ------------------------------------------------------------
# s3_backup.sh - S3 Backup Automation
# Usage: ./s3_backup.sh [folder-to-backup]
# Does: compress folder -> upload to S3 -> delete old backups
# ------------------------------------------------------------

# ---------- settings (edit these) ----------
BUCKET="manish-backup-lab-2026"
SOURCE_DIR="${1:-$HOME/data}"
KEEP_DAYS=7
# -------------------------------------------

STAMP=$(date +%Y%m%d_%H%M%S)
ARCHIVE="/tmp/backup_$STAMP.tar.gz"
LOG="$HOME/backup.log"

log() { echo "$(date '+%F %T') $*" | tee -a "$LOG"; }

log "===== Backup started ====="

# 1. Check that AWS CLI exists
if ! command -v aws >/dev/null 2>&1; then
    log "FAIL: aws CLI not found"
    exit 1
fi

# 2. Check that the source folder exists
if [ ! -d "$SOURCE_DIR" ]; then
    log "FAIL: folder not found: $SOURCE_DIR"
    exit 1
fi

# 3. Compress the folder
if tar -czf "$ARCHIVE" -C "$(dirname "$SOURCE_DIR")" "$(basename "$SOURCE_DIR")"; then
    SIZE=$(du -h "$ARCHIVE" | cut -f1)
    log "OK: archive created ($SIZE) $ARCHIVE"
else
    log "FAIL: tar command failed"
    exit 1
fi

# 4. Upload to S3
if aws s3 cp "$ARCHIVE" "s3://$BUCKET/backups/" --only-show-errors; then
    log "OK: uploaded to s3://$BUCKET/backups/$(basename "$ARCHIVE")"
else
    log "FAIL: upload failed"
    rm -f "$ARCHIVE"
    exit 1
fi

# 5. Remove the local archive
rm -f "$ARCHIVE"

# 6. Delete backups older than KEEP_DAYS (date is read from the file name)
CUTOFF=$(date -d "-$KEEP_DAYS days" +%Y%m%d)
DELETED=0
for f in $(aws s3 ls "s3://$BUCKET/backups/" | awk '{print $4}'); do
    FILE_DATE=$(echo "$f" | grep -oE '[0-9]{8}' | head -n 1)
    if [ -n "$FILE_DATE" ] && [ "$FILE_DATE" -lt "$CUTOFF" ]; then
        if aws s3 rm "s3://$BUCKET/backups/$f" --only-show-errors; then
            log "Deleted old backup: $f"
            DELETED=$((DELETED + 1))
        fi
    fi
done
log "Old backups deleted: $DELETED"

log "===== Backup finished ====="
