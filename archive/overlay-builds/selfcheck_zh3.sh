#!/usr/bin/env bash
# Pre-deploy self-check for nocodb-zh:2026.06.1-zh3 against a THROWAWAY postgres.
# Validates: boot, fresh migration chain (incl. vendored files), signup/login,
# and the attachment MIME backfill (upload .mp4 as text/plain -> video/mp4).
# Touches nothing in prod. Cleans up all temp resources.
set -u

NET=zh3check-net
PG=zh3check-pg
APP=zh3check-app
IMG=nocodb-zh:2026.06.1-zh3
PASS=checkpass123
JWT=selfcheckjwtsecret

cleanup() {
  docker rm -f "$APP" "$PG" >/dev/null 2>&1
  docker network rm "$NET" >/dev/null 2>&1
}
trap cleanup EXIT
cleanup

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
  -p 18080:8080 \
  "$IMG" >/dev/null

echo "[*] waiting for app to boot + migrate..."
BOOTED=0
for i in $(seq 1 90); do
  code=$(curl -s -o /dev/null -w '%{http_code}' http://127.0.0.1:18080/api/v1/health 2>/dev/null || true)
  if [ "$code" = "200" ]; then BOOTED=1; break; fi
  sleep 2
done
if [ "$BOOTED" != "1" ]; then
  echo "[FAIL] app did not become healthy"; echo "----- app logs (tail) -----"; docker logs --tail 60 "$APP"; exit 1
fi
echo "[OK] health 200"

echo "[*] checking GUI is served (the zh3 regression we are guarding against)..."
ROOT_CT=$(curl -s -o /dev/null -w '%{content_type}' -H 'Accept: text/html' http://127.0.0.1:18080/)
DASH_CODE=$(curl -s -o /dev/null -w '%{http_code}' -H 'Accept: text/html' http://127.0.0.1:18080/dashboard)
echo "[*] / content-type=$ROOT_CT ; /dashboard http=$DASH_CODE"
if ! printf '%s' "$ROOT_CT" | grep -qi 'text/html'; then
  echo "[FAIL] root did not return HTML (GUI not served)"; docker logs --tail 40 "$APP"; exit 1
fi
if [ "$DASH_CODE" = "404" ]; then
  echo "[FAIL] /dashboard 404 (GUI not served)"; exit 1
fi
echo "[OK] GUI served (root HTML, /dashboard=$DASH_CODE)"

echo "[*] checking migration errors in logs..."
if docker logs "$APP" 2>&1 | grep -iE "migration .*fail|error: relation|already exists|MIGRATION ERROR" | grep -v "no such" ; then
  echo "[WARN] potential migration messages above"
fi

echo "[*] signup first admin..."
SIGNUP=$(curl -s -X POST http://127.0.0.1:18080/api/v1/auth/user/signup \
  -H 'Content-Type: application/json' \
  -d '{"email":"selfcheck@example.com","password":"Checkpass123!"}')
TOKEN=$(printf '%s' "$SIGNUP" | python3 -c 'import sys,json;print(json.load(sys.stdin).get("token",""))' 2>/dev/null || true)
if [ -z "$TOKEN" ]; then
  echo "[FAIL] signup/login failed: $SIGNUP"; exit 1
fi
echo "[OK] signup+token acquired"

echo "[*] uploading a .mp4 with Content-Type text/plain (simulating the bad pipeline)..."
TMP=$(mktemp /tmp/selfcheck.XXXXXX.mp4)
head -c 2048 /dev/urandom > "$TMP"
UP=$(curl -s -X POST "http://127.0.0.1:18080/api/v2/storage/upload?path=noco/selfcheck" \
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

echo "ALL_SELFCHECKS_PASSED"
