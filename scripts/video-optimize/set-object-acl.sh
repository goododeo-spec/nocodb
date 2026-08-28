#!/usr/bin/env bash
# Change DigitalOcean Spaces object ACLs one key at a time.
# Usage:
#   KEY=nc/uploads/.../file.mp4 ACL=private ./set-object-acl.sh
#   KEYS_FILE=keys.txt ACL=private ./set-object-acl.sh
set -euo pipefail

ACL=${ACL:-private}
ENDPOINT=${NC_S3_ENDPOINT:-https://sgp1.digitaloceanspaces.com}
BUCKET=${NC_S3_BUCKET_NAME:-ainew-sin-doc01}
REGION=${NC_S3_REGION:-us-east-1}

if [[ -z "${NC_S3_ACCESS_KEY:-}" || -z "${NC_S3_ACCESS_SECRET:-}" ]]; then
  echo "NC_S3_ACCESS_KEY and NC_S3_ACCESS_SECRET are required" >&2
  exit 2
fi

apply_one() {
  local key=$1
  docker run --rm \
    -e AWS_ACCESS_KEY_ID="$NC_S3_ACCESS_KEY" \
    -e AWS_SECRET_ACCESS_KEY="$NC_S3_ACCESS_SECRET" \
    -e AWS_DEFAULT_REGION="$REGION" \
    amazon/aws-cli:2.17.0 \
    --endpoint-url "$ENDPOINT" \
    s3api put-object-acl --bucket "$BUCKET" --key "$key" --acl "$ACL" >/dev/null
  echo "acl=$ACL key=$key"
}

if [[ -n "${KEY:-}" ]]; then
  apply_one "$KEY"
  exit 0
fi

if [[ -n "${KEYS_FILE:-}" ]]; then
  while IFS= read -r key; do
    [[ -z "$key" ]] && continue
    apply_one "$key"
  done < "$KEYS_FILE"
  exit 0
fi

echo "set KEY or KEYS_FILE" >&2
exit 2
