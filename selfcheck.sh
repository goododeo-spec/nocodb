#!/usr/bin/env bash
# Generic pre-deploy self-check for any nocodb-zh:<tag> image, run against a
# THROWAWAY postgres + local (non-S3) attachment storage. Touches nothing in
# prod. Cleans up all temp resources on exit (success or failure).
#
# Usage: selfcheck.sh <image-tag>
#
# Validates:
#   - boot + fresh migration chain (incl. vendored files)
#   - GUI actually served (the zh6 "blank page / 404 dashboard" regression class)
#   - signup/login
#   - attachment MIME backfill (upload .mp4 as text/plain -> video/mp4)
#
# Attachment-specific thumbnail checks (image thumbnails 3 sizes + 200,
# video has no thumbnails field, non-image render gate) live in
# selfcheck-attachments.sh and are run separately by build.sh.
set -u

IMG="${1:?usage: selfcheck.sh <image-tag>}"
RUN_ID="sc-$$-$RANDOM"
NET="${RUN_ID}-net"
PG="${RUN_ID}-pg"
APP="${RUN_ID}-app"
PASS=checkpass123
JWT=selfcheckjwtsecret
HOST_PORT=$(( (RANDOM % 5000) + 20000 ))

cleanup() {
  docker rm -f "$APP" "$PG" >/dev/null 2>&1
  docker network rm "$NET" >/dev/null 2>&1
}
trap cleanup EXIT

set -e
docker network create "$NET" >/dev/null
docker run -d --name "$PG" --network "$NET" \
  -e POSTGRES_DB=nocodb -e POSTGRES_USER=nocodb -e POSTGRES_PASSWORD="$PASS" \
  postgres:16-alpine >/dev/null

echo "[*] waiting for postgres..."
for i in $(seq 1 30); do
  if docker exec "$PG" pg_isready -U nocodb >/dev/null 2>&1; then break; fi
  sleep 1
done

docker run -d --name "$APP" --network "$NET" \
  -e NC_DB="pg://$PG:5432?u=nocodb&p=$PASS&d=nocodb" \
  -e NC_AUTH_JWT_SECRET="$JWT" \
  -e NC_DISABLE_TELE=true \
  -e NC_THUMBNAIL_MAX_SIZE=10485760 \
  -p "$HOST_PORT:8080" \
  "$IMG" >/dev/null
# NC_THUMBNAIL_MAX_SIZE mirrors the production runtime config (see MAINTENANCE.md
# "运行时配置") so selfcheck-attachments.sh exercises the same threshold prod uses.

echo "[*] waiting for app to boot + migrate (image=$IMG, port=$HOST_PORT)..."
BOOTED=0
for i in $(seq 1 90); do
  code=$(curl -s -o /dev/null -w '%{http_code}' "http://127.0.0.1:$HOST_PORT/api/v1/health" 2>/dev/null || true)
  if [ "$code" = "200" ]; then BOOTED=1; break; fi
  sleep 2
done
if [ "$BOOTED" != "1" ]; then
  echo "[FAIL] app did not become healthy"; echo "----- app logs (tail) -----"; docker logs --tail 60 "$APP"; exit 1
fi
echo "[OK] health 200"

echo "[*] checking GUI is served (the zh6 regression class we guard against)..."
ROOT_CT=$(curl -s -o /dev/null -w '%{content_type}' -H 'Accept: text/html' "http://127.0.0.1:$HOST_PORT/")
DASH_CODE=$(curl -s -o /dev/null -w '%{http_code}' -H 'Accept: text/html' "http://127.0.0.1:$HOST_PORT/dashboard")
echo "[*] / content-type=$ROOT_CT ; /dashboard http=$DASH_CODE"
if ! printf '%s' "$ROOT_CT" | grep -qi 'text/html'; then
  echo "[FAIL] root did not return HTML (GUI not served)"; docker logs --tail 40 "$APP"; exit 1
fi
if [ "$DASH_CODE" = "404" ]; then
  echo "[FAIL] /dashboard 404 (GUI not served)"; exit 1
fi
echo "[OK] GUI served (root HTML, /dashboard=$DASH_CODE)"

echo "[*] checking migration errors in logs..."
if docker logs "$APP" 2>&1 | grep -iE "migration .*fail|error: relation|already exists|MIGRATION ERROR" | grep -v "no such"; then
  echo "[WARN] potential migration messages above (non-fatal, review manually)"
fi

echo "[*] signup first admin..."
SIGNUP=$(curl -s -X POST "http://127.0.0.1:$HOST_PORT/api/v1/auth/user/signup" \
  -H 'Content-Type: application/json' \
  -d '{"email":"selfcheck@example.com","password":"Checkpass123!"}')
TOKEN=$(printf '%s' "$SIGNUP" | python3 -c 'import sys,json;print(json.load(sys.stdin).get("token",""))' 2>/dev/null || true)
if [ -z "$TOKEN" ]; then
  echo "[FAIL] signup/login failed: $SIGNUP"; exit 1
fi
echo "[OK] signup+token acquired"

echo "[*] uploading a .mp4 with Content-Type text/plain (simulating the bad upload pipeline)..."
TMP=$(mktemp /tmp/selfcheck.XXXXXX.mp4)
head -c 2048 /dev/urandom > "$TMP"
UP=$(curl -s -X POST "http://127.0.0.1:$HOST_PORT/api/v2/storage/upload?path=noco/selfcheck" \
  -H "xc-auth: $TOKEN" \
  -F "file=@$TMP;type=text/plain;filename=selfcheck.mp4")
rm -f "$TMP"
echo "[*] upload response: $UP"
MIME=$(printf '%s' "$UP" | python3 -c 'import sys,json
d=json.load(sys.stdin)
x=d[0] if isinstance(d,list) and d else d
print(x.get("mimetype","") if isinstance(x,dict) else "")' 2>/dev/null || true)
echo "[*] stored mimetype = $MIME"
if [ "$MIME" = "video/mp4" ]; then
  echo "[OK] MIME backfill works (text/plain .mp4 -> video/mp4)"
else
  echo "[FAIL] expected video/mp4, got: $MIME"; exit 1
fi

echo "[*] shared-base access-request smoke..."
# Migration table must exist after boot.
if ! docker exec "$PG" psql -U nocodb -d nocodb -Atc \
  "SELECT to_regclass('public.nc_shared_base_access_requests');" | grep -q 'nc_shared_base_access_requests'; then
  echo "[FAIL] nc_shared_base_access_requests table missing after migration"
  exit 1
fi
echo "[OK] access-request migration table present"

# Anonymous create must be rejected.
ANON_CODE=$(curl -s -o /tmp/selfcheck-anon-ar.json -w '%{http_code}' \
  -X POST "http://127.0.0.1:$HOST_PORT/api/v2/meta/shared-bases/00000000-0000-0000-0000-000000000000/access-requests" \
  -H 'Content-Type: application/json' \
  -d '{}')
if [ "$ANON_CODE" != "401" ] && [ "$ANON_CODE" != "403" ]; then
  echo "[FAIL] anonymous access-request create expected 401/403, got $ANON_CODE"
  cat /tmp/selfcheck-anon-ar.json; exit 1
fi
echo "[OK] anonymous access-request create blocked ($ANON_CODE)"

# Create a base, enable shared link, and exercise authenticated request APIs.
BASE_JSON=$(curl -s -X POST "http://127.0.0.1:$HOST_PORT/api/v2/meta/bases" \
  -H "xc-auth: $TOKEN" -H 'Content-Type: application/json' \
  -d '{"title":"Selfcheck Access Request Base"}')
BASE_ID=$(printf '%s' "$BASE_JSON" | python3 -c 'import sys,json;print(json.load(sys.stdin).get("id",""))' 2>/dev/null || true)
if [ -z "$BASE_ID" ]; then
  echo "[FAIL] could not create base for access-request smoke: $BASE_JSON"; exit 1
fi

SHARED_JSON=$(curl -s -X POST "http://127.0.0.1:$HOST_PORT/api/v2/meta/bases/$BASE_ID/shared" \
  -H "xc-auth: $TOKEN" -H 'Content-Type: application/json' \
  -d '{"roles":"viewer"}')
SHARED_UUID=$(printf '%s' "$SHARED_JSON" | python3 -c 'import sys,json;d=json.load(sys.stdin);print(d.get("uuid") or d.get("shared_base_id") or "")' 2>/dev/null || true)
if [ -z "$SHARED_UUID" ]; then
  # Some builds return the updated base with uuid field.
  SHARED_UUID=$(printf '%s' "$SHARED_JSON" | python3 -c 'import sys,json;d=json.load(sys.stdin);print(d.get("uuid",""))' 2>/dev/null || true)
fi
if [ -z "$SHARED_UUID" ]; then
  echo "[FAIL] could not enable shared base: $SHARED_JSON"; exit 1
fi
echo "[OK] shared base enabled uuid=$SHARED_UUID"

OWNER_STATUS=$(curl -s -X GET "http://127.0.0.1:$HOST_PORT/api/v2/meta/shared-bases/$SHARED_UUID/access-requests" \
  -H "xc-auth: $TOKEN")
OWNER_HAS_ACCESS=$(printf '%s' "$OWNER_STATUS" | python3 -c 'import sys,json;d=json.load(sys.stdin);print("1" if d.get("already_has_access") else "0")' 2>/dev/null || true)
if [ "$OWNER_HAS_ACCESS" != "1" ]; then
  echo "[FAIL] owner should already have edit access via shared UUID status: $OWNER_STATUS"; exit 1
fi
echo "[OK] owner status returns already_has_access"

LIST_CODE=$(curl -s -o /tmp/selfcheck-ar-list.json -w '%{http_code}' \
  "http://127.0.0.1:$HOST_PORT/api/v2/meta/bases/$BASE_ID/shared-access-requests?status=pending" \
  -H "xc-auth: $TOKEN")
if [ "$LIST_CODE" != "200" ]; then
  echo "[FAIL] list pending access requests expected 200, got $LIST_CODE"
  cat /tmp/selfcheck-ar-list.json; exit 1
fi
echo "[OK] list pending access requests works"

# Second user requests edit access, then owner approves.
SIGNUP2=$(curl -s -X POST "http://127.0.0.1:$HOST_PORT/api/v1/auth/user/signup" \
  -H 'Content-Type: application/json' \
  -d '{"email":"selfcheck-editor@example.com","password":"Checkpass123!"}')
TOKEN2=$(printf '%s' "$SIGNUP2" | python3 -c 'import sys,json;print(json.load(sys.stdin).get("token",""))' 2>/dev/null || true)
if [ -z "$TOKEN2" ]; then
  echo "[FAIL] second-user signup failed: $SIGNUP2"; exit 1
fi

REQ_JSON=$(curl -s -X POST "http://127.0.0.1:$HOST_PORT/api/v2/meta/shared-bases/$SHARED_UUID/access-requests" \
  -H "xc-auth: $TOKEN2" -H 'Content-Type: application/json' \
  -d '{"message":"selfcheck please grant editor"}')
REQ_ID=$(printf '%s' "$REQ_JSON" | python3 -c 'import sys,json;print(json.load(sys.stdin).get("id",""))' 2>/dev/null || true)
REQ_STATUS=$(printf '%s' "$REQ_JSON" | python3 -c 'import sys,json;print(json.load(sys.stdin).get("status",""))' 2>/dev/null || true)
if [ -z "$REQ_ID" ] || [ "$REQ_STATUS" != "pending" ]; then
  echo "[FAIL] expected pending access request, got: $REQ_JSON"; exit 1
fi
echo "[OK] second user created pending access request id=$REQ_ID"

# Idempotent re-submit while pending.
REQ2_JSON=$(curl -s -X POST "http://127.0.0.1:$HOST_PORT/api/v2/meta/shared-bases/$SHARED_UUID/access-requests" \
  -H "xc-auth: $TOKEN2" -H 'Content-Type: application/json' \
  -d '{}')
REQ2_PENDING=$(printf '%s' "$REQ2_JSON" | python3 -c 'import sys,json;d=json.load(sys.stdin);print("1" if d.get("already_pending") or d.get("status")=="pending" else "0")' 2>/dev/null || true)
if [ "$REQ2_PENDING" != "1" ]; then
  echo "[FAIL] duplicate pending request should be idempotent: $REQ2_JSON"; exit 1
fi
echo "[OK] duplicate pending request is idempotent"

APPROVE_JSON=$(curl -s -X POST "http://127.0.0.1:$HOST_PORT/api/v2/meta/bases/$BASE_ID/shared-access-requests/$REQ_ID/approve" \
  -H "xc-auth: $TOKEN")
APPROVE_STATUS=$(printf '%s' "$APPROVE_JSON" | python3 -c 'import sys,json;print(json.load(sys.stdin).get("status",""))' 2>/dev/null || true)
if [ "$APPROVE_STATUS" != "approved" ]; then
  echo "[FAIL] approve expected status=approved, got: $APPROVE_JSON"; exit 1
fi
echo "[OK] owner approved access request"

AFTER_JSON=$(curl -s -X GET "http://127.0.0.1:$HOST_PORT/api/v2/meta/shared-bases/$SHARED_UUID/access-requests" \
  -H "xc-auth: $TOKEN2")
AFTER_ACCESS=$(printf '%s' "$AFTER_JSON" | python3 -c 'import sys,json;d=json.load(sys.stdin);print("1" if d.get("already_has_access") else "0")' 2>/dev/null || true)
if [ "$AFTER_ACCESS" != "1" ]; then
  echo "[FAIL] requester should have editor access after approval: $AFTER_JSON"; exit 1
fi
echo "[OK] requester has edit access after approval"

echo "ALL_SELFCHECKS_PASSED image=$IMG host_port=$HOST_PORT app=$APP"
# Export for callers (e.g. selfcheck-attachments.sh chained by build.sh) that
# want to reuse this still-running instance instead of booting a new one.
echo "$APP" > /tmp/.selfcheck-last-app
echo "$HOST_PORT" > /tmp/.selfcheck-last-port
echo "$TOKEN" > /tmp/.selfcheck-last-token
trap - EXIT
echo "[*] leaving $APP running for chained checks; caller must clean up with: docker rm -f $APP $PG; docker network rm $NET"
echo "$NET" > /tmp/.selfcheck-last-net
echo "$PG" > /tmp/.selfcheck-last-pg
