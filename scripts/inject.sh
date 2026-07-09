#!/usr/bin/env bash
# 배선 층 주입: private 오버레이 repo의 고유값으로 templates/integration/*.tmpl 을 렌더해
# 대상 프로젝트에 배치한다. 서브모듈이 아니라 런타임 스크립트 주입이며,
# 오버레이 접근 권한이 없으면(클론 실패) 주입은 실패한다.
#
#   export DOIL_BOOTSTRAP_OVERLAY=<private 오버레이 repo git URL>
#   scripts/inject.sh <proj-dir>
#
# 오버레이 repo 규약: 루트에 values.env (key=value, 아래 placeholder 값들).
set -euo pipefail

PROJ_DIR="${1:?사용법: inject.sh <proj-dir>}"
PROJ="$(basename "$(cd "$PROJ_DIR" && pwd)")"
REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
TMPL_DIR="$REPO_DIR/templates/integration"

# 1) 오버레이 위치 필수 — 미설정이면 주입 불가
: "${DOIL_BOOTSTRAP_OVERLAY:?배선 오버레이 미설정: DOIL_BOOTSTRAP_OVERLAY 환경변수(private repo URL)를 설정하라. 미설정 시 배선 주입 불가(코어만 사용).}"

# 2) 오버레이 clone — 권한 없으면 여기서 실패(주입 중단)
OVERLAY="$(mktemp -d)"
trap 'rm -rf "$OVERLAY"' EXIT
if ! git clone --depth 1 "$DOIL_BOOTSTRAP_OVERLAY" "$OVERLAY" 2>/dev/null; then
  echo "✖ 오버레이 clone 실패(권한 없음/URL 오류) — 배선 주입 중단. 코어 산출물은 그대로 유효." >&2
  exit 1
fi
[ -f "$OVERLAY/values.env" ] || { echo "✖ 오버레이에 values.env 없음 — 중단." >&2; exit 1; }

# 3) 고유값 로드 + slug 주입
set -a
# shellcheck disable=SC1091
source "$OVERLAY/values.env"
PROJ="$PROJ"
set +a

# 4) 화이트리스트 envsubst — 명시한 placeholder만 치환, 대상 파일의 ${VAR}는 보존
VARS='${PROJ} ${NETWORK} ${DB_ALIAS} ${DOMAIN_SUFFIX} ${CERT_PATH} ${DNS_RESOLVER} ${PORT}'
render() { envsubst "$VARS" < "$1"; }

# compose → <proj>/docker-compose.yml
render "$TMPL_DIR/docker-compose.yml.tmpl" > "$PROJ_DIR/docker-compose.yml"
echo "→ $PROJ_DIR/docker-compose.yml"

# gateway conf → 오버레이가 GATEWAY_CONFD를 주면 거기에, 아니면 <proj>에 남김
GW_OUT="${GATEWAY_CONFD:-$PROJ_DIR}/${PROJ}.${DOMAIN_SUFFIX:-local}.conf"
render "$TMPL_DIR/gateway.conf.tmpl" > "$GW_OUT"
echo "→ $GW_OUT"

# 5) 오버레이 고유 hook(선택)
if [ -x "$OVERLAY/inject-hook.sh" ]; then
  echo "→ 오버레이 hook 실행"
  DOIL_PROJ="$PROJ" DOIL_PROJ_DIR="$PROJ_DIR" "$OVERLAY/inject-hook.sh"
fi

echo "✔ 배선 주입 완료: $PROJ"
