# S3 Backup Automation

Bash script that compresses a folder, uploads it to Amazon S3, deletes backups
older than 7 days, and logs every step. Runs daily with cron.

## Features
- Compresses a folder with tar + gzip
- Uploads to S3 with AWS CLI
- Retention: deletes backups older than 7 days
- Logs all actions to ~/backup.log
- Uses an IAM role (no access keys) with a least-privilege policy

## Architecture
EC2 + cron -> s3_backup.sh -> tar -> aws s3 cp -> S3 bucket (backups/)

## Requirements
- Amazon Linux 2023 EC2 instance
- AWS CLI (pre-installed)
- IAM role with the policy in policy.json
- cronie for scheduling: sudo dnf install -y cronie

## Setup
1. Create an S3 bucket (block public access ON)
2. Create an IAM policy from policy.json and attach it to an EC2 role
3. Edit BUCKET in s3_backup.sh
4. chmod +x s3_backup.sh
5. ./s3_backup.sh

## Schedule (daily at 2 AM server time)
0 2 * * * /home/ec2-user/s3-backup/s3_backup.sh >> /home/ec2-user/cron.out 2>&1

## Restore
aws s3 cp s3://<bucket>/backups/<file>.tar.gz .
tar -xzf <file>.tar.gz

## Sample log
2026-10-19 18:58:20 ===== Backup started =====
2026-10-19 18:58:21 OK: archive created (4.0K) /tmp/backup_20261019_185820.tar.gz
2026-10-19 18:58:21 OK: uploaded to s3://<bucket>/backups/backup_20261019_185820.tar.gz
2026-10-19 18:58:22 Old backups deleted: 0
2026-10-19 18:58:22 ===== Backup finished =====

## Future improvements
- SNS email alert on failure
- Back up multiple folders
- Encrypt archives with GPG
- Verify upload with a checksum
