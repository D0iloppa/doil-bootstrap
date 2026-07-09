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
export GIT_TERMINAL_PROMPT=0   # 자격증명 프롬프트로 멈추지 말고 즉시 실패

PROJ_DIR="${1:?사용법: inject.sh <proj-dir>}"
PROJ="$(basename "$(cd "$PROJ_DIR" && pwd)")"
REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
TMPL_DIR="$REPO_DIR/templates/integration"

# 1) 오버레이 위치 필수 — 미설정이면 주입 불가
: "${DOIL_BOOTSTRAP_OVERLAY:?배선 오버레이 미설정: DOIL_BOOTSTRAP_OVERLAY 환경변수(private repo URL)를 설정하라. 미설정 시 배선 주입 불가(코어만 사용).}"

# 2) 오버레이 clone — 권한 없으면 여기서 즉시 실패(주입 중단)
#    권한 게이팅은 gh 토큰 기준: github.com 오버레이면 토큰을 URL에 주입해 인증한다.
#    자격증명 helper(GCM 등 GUI)는 비활성 — 캐시가 없어도 프롬프트로 멈추지 않고 실패한다.
OVERLAY="$(mktemp -d)"
trap 'rm -rf "$OVERLAY"' EXIT
CLONE_URL="$DOIL_BOOTSTRAP_OVERLAY"
if [[ "$CLONE_URL" == https://github.com/* ]]; then
  GH_TOKEN="$(gh auth token 2>/dev/null || true)"
  [ -n "$GH_TOKEN" ] && CLONE_URL="https://x-access-token:${GH_TOKEN}@github.com/${CLONE_URL#https://github.com/}"
fi
if ! git -c credential.helper= -c credential.interactive=false \
        clone --depth 1 "$CLONE_URL" "$OVERLAY" 2>/dev/null; then
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
