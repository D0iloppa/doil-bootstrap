# 배선 템플릿 (범용)

공유 게이트웨이/네트워크 뒤에 붙는 스택의 배선 **패턴**. 값이 없는 placeholder만 담는다.
환경 고유값은 private 오버레이 repo의 `values.env`에서 [`../../scripts/inject.sh`](../../scripts/inject.sh)가 주입한다.

## placeholder 카탈로그

| placeholder | 의미 | 예(오버레이에서 채움) |
|-------------|------|----------------------|
| `${PROJ}` | 프로젝트 슬러그 | `myapp` |
| `${NETWORK}` | 게이트웨이 ingress용 공유 외부 도커 네트워크 | `edge` |
| `${DB_NETWORK}` | 공유 DB 전용 외부 도커 네트워크 | `devdb` |
| `${DB_ALIAS}` | 공유 DB 네트워크 별칭 | `devdb` |
| `${DOMAIN_SUFFIX}` | 서브도메인 접미 | `example.com` |
| `${CERT_PATH}` | 와일드카드 인증서 디렉토리 | `/etc/ssl/live/example.com` |
| `${DNS_RESOLVER}` | 도커 내장 DNS | `127.0.0.11` |
| `${PORT}` | 프로젝트 컨테이너 포트 | `8080` |

`${PROJ}`는 slug 인자로도 전달되므로 오버레이 없이도 채워진다. 나머지는 오버레이 `values.env`가 제공한다.

## 렌더 시 보존되는 것

대상 파일 자체가 런타임에 참조하는 `${VAR}`(예: compose의 `${DB_PASSWORD:?}`)는 화이트리스트
`envsubst`로 **치환하지 않고 그대로 남긴다**. inject.sh가 치환 대상 placeholder만 명시적으로 넘긴다.

## 파일

- `docker-compose.yml.tmpl` → `<proj>/docker-compose.yml`
- `gateway.conf.tmpl` → 베이스 게이트웨이 `conf.d/<proj>.<domain>.conf`
