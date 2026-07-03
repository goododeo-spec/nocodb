#!/usr/bin/env bash
# Attachment-specific self-check: [P1] selfcheck 增附件专项 (MAINTENANCE.md).
# Guards against this round's core bug regressing on a future upgrade:
#   - large image upload -> API returns thumbnails.tiny/small/card_cover, each URL 200
#   - video upload -> API response has NO `thumbnails` field
#   - frontend source still has the non-image render gate (grid canvas + carousel thumbnail)
#
# Meant to be run right after selfcheck.sh against the same still-running
# instance (reuses its app container so NC_THUMBNAIL_MAX_SIZE / DB state carry
# over). Chained automatically by build.sh; can also be run standalone:
#
#   selfcheck-attachments.sh <host_port> <token> <repo_root> <app_container>
set -euo pipefail

HOST_PORT="${1:?usage: selfcheck-attachments.sh <host_port> <token> <repo_root> <app_container>}"
TOKEN="${2:?usage: selfcheck-attachments.sh <host_port> <token> <repo_root> <app_container>}"
REPO_ROOT="${3:?usage: selfcheck-attachments.sh <host_port> <token> <repo_root> <app_container>}"
APP_CONTAINER="${4:?usage: selfcheck-attachments.sh <host_port> <token> <repo_root> <app_container>}"
BASE_URL="http://127.0.0.1:${HOST_PORT}"

echo "[*] --- attachment selfcheck ---"

echo "[*] source gate check: grid canvas + carousel thumbnail must not image-load non-images..."
GATE_FILE_1="$REPO_ROOT/packages/nc-gui/components/smartsheet/grid/canvas/cells/Attachment.ts"
GATE_FILE_2="$REPO_ROOT/packages/nc-gui/components/cell/attachment/Preview/Thumbnail.vue"
for f in "$GATE_FILE_1" "$GATE_FILE_2"; do
  if [ ! -f "$f" ]; then
    echo "[FAIL] expected gated file missing: $f"; exit 1
  fi
  if ! grep -q "isImage(" "$f"; then
    echo "[FAIL] $f no longer calls isImage() -- the video-as-image regression gate may have been reverted"
    exit 1
  fi
done
echo "[OK] non-image render gate present in both files"

echo "[*] creating throwaway base/table with an Attachment column..."
BASE_ID=$(curl -s -X POST "$BASE_URL/api/v1/db/meta/projects" \
  -H "xc-auth: $TOKEN" -H 'Content-Type: application/json' \
  -d '{"title":"selfcheck-attachments-base"}' | python3 -c 'import sys,json;print(json.load(sys.stdin)["id"])')
TABLE_RESP=$(curl -s -X POST "$BASE_URL/api/v1/db/meta/projects/$BASE_ID/tables" \
  -H "xc-auth: $TOKEN" -H 'Content-Type: application/json' \
  -d '{"table_name":"sc_attach","title":"sc_attach","columns":[{"column_name":"Title","title":"Title","uidt":"SingleLineText"},{"column_name":"Attach","title":"Attach","uidt":"Attachment"}]}')
TABLE_ID=$(printf '%s' "$TABLE_RESP" | python3 -c 'import sys,json;print(json.load(sys.stdin)["id"])')
echo "[OK] base=$BASE_ID table=$TABLE_ID"

echo "[*] generating a >3MB test JPEG inside the app container (uses the image's own sharp)..."
docker exec "$APP_CONTAINER" node -e "
const sharp = require('/usr/src/app/node_modules/sharp');
const w=3000,h=2200;
const buf = Buffer.alloc(w*h*3);
for (let i=0;i<buf.length;i++) buf[i] = Math.floor(Math.random()*256);
sharp(buf, {raw:{width:w,height:h,channels:3}}).jpeg({quality:100}).toFile('/tmp/sc_big.jpg')
  .then(()=>process.exit(0)).catch(e=>{console.error(e);process.exit(1)});
"
docker cp "$APP_CONTAINER:/tmp/sc_big.jpg" /tmp/selfcheck_attach_big.jpg

echo "[*] uploading large image..."
UP_IMG=$(curl -s -X POST "$BASE_URL/api/v2/storage/upload?path=noco/sc-attach" \
  -H "xc-auth: $TOKEN" -F "file=@/tmp/selfcheck_attach_big.jpg;type=image/jpeg;filename=sc_big.jpg")
rm -f /tmp/selfcheck_attach_big.jpg
IMG_PATH=$(printf '%s' "$UP_IMG" | python3 -c 'import sys,json;print(json.load(sys.stdin)[0]["path"])')
IMG_SIZE=$(printf '%s' "$UP_IMG" | python3 -c 'import sys,json;print(json.load(sys.stdin)[0]["size"])')

IMG_ROW=$(curl -s -X POST "$BASE_URL/api/v2/tables/$TABLE_ID/records" \
  -H "xc-auth: $TOKEN" -H 'Content-Type: application/json' \
  -d "{\"Title\":\"img\",\"Attach\":[{\"path\":\"$IMG_PATH\",\"title\":\"sc_big.jpg\",\"mimetype\":\"image/jpeg\",\"size\":$IMG_SIZE}]}")
IMG_ROW_ID=$(printf '%s' "$IMG_ROW" | python3 -c 'import sys,json;print(json.load(sys.stdin)["Id"])')

echo "[*] waiting for thumbnail generation job..."
THUMBS_JSON=""
for i in $(seq 1 15); do
  READ_BACK=$(curl -s "$BASE_URL/api/v2/tables/$TABLE_ID/records/$IMG_ROW_ID" -H "xc-auth: $TOKEN")
  THUMBS_JSON=$(printf '%s' "$READ_BACK" | python3 -c 'import sys,json
d=json.load(sys.stdin)
a=d.get("Attach",[{}])[0]
print(json.dumps(a.get("thumbnails")) if a.get("thumbnails") else "")' 2>/dev/null || true)
  [ -n "$THUMBS_JSON" ] && break
  sleep 2
done

if [ -z "$THUMBS_JSON" ]; then
  echo "[FAIL] image attachment did not get a thumbnails field after upload (checked NC_THUMBNAIL_MAX_SIZE and worker job wiring)"
  exit 1
fi
echo "[*] thumbnails=$THUMBS_JSON"

for size in tiny small card_cover; do
  SIGNED=$(printf '%s' "$THUMBS_JSON" | python3 -c "import sys,json;print(json.load(sys.stdin).get('$size',{}).get('signedPath',''))")
  if [ -z "$SIGNED" ]; then
    echo "[FAIL] thumbnails.$size missing from response"; exit 1
  fi
  # The thumbnail job generates tiny/small/card_cover sequentially; the signed
  # URL is returned as soon as one exists in the response, but the underlying
  # file for a *different* size may still be mid-write. Retry briefly.
  CODE=""
  for i in $(seq 1 10); do
    CODE=$(curl -s -o /dev/null -w '%{http_code}' "$BASE_URL/$SIGNED")
    [ "$CODE" = "200" ] && break
    sleep 1
  done
  if [ "$CODE" != "200" ]; then
    echo "[FAIL] thumbnails.$size URL returned $CODE (expected 200): $SIGNED"; exit 1
  fi
  echo "[OK] thumbnails.$size -> 200"
done
echo "[OK] image attachment returns all 3 thumbnail sizes, all URLs 200"

echo "[*] uploading a video and confirming NO thumbnails field..."
head -c 4096 /dev/urandom > /tmp/selfcheck_attach_vid.mp4
UP_VID=$(curl -s -X POST "$BASE_URL/api/v2/storage/upload?path=noco/sc-attach" \
  -H "xc-auth: $TOKEN" -F "file=@/tmp/selfcheck_attach_vid.mp4;type=video/mp4;filename=sc_vid.mp4")
rm -f /tmp/selfcheck_attach_vid.mp4
VID_PATH=$(printf '%s' "$UP_VID" | python3 -c 'import sys,json;print(json.load(sys.stdin)[0]["path"])')

VID_ROW=$(curl -s -X POST "$BASE_URL/api/v2/tables/$TABLE_ID/records" \
  -H "xc-auth: $TOKEN" -H 'Content-Type: application/json' \
  -d "{\"Title\":\"vid\",\"Attach\":[{\"path\":\"$VID_PATH\",\"title\":\"sc_vid.mp4\",\"mimetype\":\"video/mp4\",\"size\":4096}]}")
VID_ROW_ID=$(printf '%s' "$VID_ROW" | python3 -c 'import sys,json;print(json.load(sys.stdin)["Id"])')
sleep 3
VID_READ_BACK=$(curl -s "$BASE_URL/api/v2/tables/$TABLE_ID/records/$VID_ROW_ID" -H "xc-auth: $TOKEN")
HAS_THUMBS=$(printf '%s' "$VID_READ_BACK" | python3 -c 'import sys,json
d=json.load(sys.stdin)
a=d.get("Attach",[{}])[0]
print("yes" if a.get("thumbnails") else "no")')
if [ "$HAS_THUMBS" = "yes" ]; then
  echo "[FAIL] video attachment unexpectedly has a thumbnails field: $VID_READ_BACK"
  exit 1
fi
echo "[OK] video attachment has no thumbnails field"

echo "ALL_ATTACHMENT_SELFCHECKS_PASSED"
