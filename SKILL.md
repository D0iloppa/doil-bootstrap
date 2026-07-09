---
name: doil-bootstrap
description: >-
  새 프로젝트를 맨바닥에서 시작할 때 사용한다. Doness 보일러플레이트를 클론해 아키텍처를
  결정하고, 문서관리 규칙(ai-docs·Session Start Protocol)과 카파시 4원칙을 미리 init한 뒤,
  격리된 신규 git repo로 발급해 곧바로 개발에 착수할 수 있게 만든다. 2층 구조 — (1) 어디서든
  쓰는 범용 코어, (2) doil.me 스택 대상일 때만 붙이는 인프라 통합(선택). "새 프로젝트 시작·
  부트스트랩·보일러플레이트 클론·프로젝트 스캐폴딩·프로젝트 골격 잡기" 류에서 트리거된다.
---

# doil-bootstrap

새 프로젝트를 **Doness 보일러플레이트**에서 출발시켜, 아키텍처 결정 → 프로젝트화 →
문서관리·카파시 원리 init → 격리 신규 repo까지 한 번에 세운다.

> 이 스킬 **실행 자체도** 카파시 지침을 따른다(가정 금지·단순성·수술적 변경·목표주도).
> 특히 아키텍처는 임의 선택하지 말고 **묻는다**.

## 층 구조

- **① 범용 코어** (항상): Doness 클론 → 아키텍처 결정 → 프로젝트화 → 문서/카파시 init →
  격리 git repo 발급. 특정 인프라에 의존하지 않는다.
- **② 배선 층** (선택 — 공유 게이트웨이/네트워크 뒤에 붙는 스택일 때): 서브모듈·compose·게이트웨이
  라우팅·공유DB·컨테이너 claude CLI 배선. **패턴은 템플릿(공개)**, **환경 고유값은 private 오버레이에서
  스크립트 주입**한다. → [`templates/`](templates/), [`scripts/inject.sh`](scripts/inject.sh)

착수 시 **어느 층까지 갈지 먼저 확인**한다(코어만 / 배선까지).

## 클론 대상 — Doness

`github.com/D0iloppa/Doness` (자체 git repo인 보일러플레이트). 미리 담고 있는 것 = **init 대상**:

- **카파시 4원칙** — `CLAUDE.md`. 프로젝트의 모든 규칙에 우선.
- **문서관리 골격** — `ai-docs/`(INDEX.md · agent-guidelines.md · context/current.md · spec/task/
  trouble/workflow) + **Session Start Protocol**(전체검색 금지, 지정 3파일부터) + SoT·보안·
  `__DEV Context`·린트 규약.
- **Docker 스택 골격** — nginx GW(:18080) 뒤 FE(React+Vite+TS)·BE(FastAPI)·wiki(Docusaurus)·PG.

(다른 보일러플레이트를 쓰려면 이 URL만 교체한다 — 그 외 절차는 동일.)

## 범용 코어 절차

각 단계는 검증 기준을 먼저 세우고(목표주도) 진행한다.

```
1. 아키텍처·메타 결정 (묻기)     → 검증: 슬러그/표시명/스택 선택 확정
2. Doness 클론 + git 해제        → 검증: <proj>/ 에 골격 복제, .git 제거됨
3. 프로젝트화                    → 검증: placeholder·env·이름 치환, README/CLAUDE 정정
4. 문서·카파시 init             → 검증: .gitignore 3줄 해제, ai-docs/context/current.md 초기화
5. 격리 repo 발급               → 검증: show-toplevel=<proj> 확인 후 신규 repo push
```

### 1. 아키텍처·메타 결정 — 반드시 물어본다 (카파시 #1)

임의로 고르지 말고 확정받을 것:
- **프로젝트 슬러그**(`<proj>`, 소문자) / **표시명**(`<Proj>`)
- **스택 형태**: 단일 컨테이너(멀티스테이지 하나로 FE static + `/api` 서빙, cie/dRec 패턴) vs 멀티서비스(FE·BE·wiki·DB 분리)
- **구성요소 취사**: wiki 필요? DB 필요? admin 콘솔? AI 호출(claude CLI) 여부?
- **신규 GitHub repo 가시성**(private/public) — 공개는 되돌리기 어려우니 확인
- **② 통합 층까지 갈지** (doil.me 스택이면 도메인 `<proj>.doil.me`도)

### 2. 클론 + git 해제

```bash
git clone --depth 1 https://github.com/D0iloppa/Doness /tmp/Doness
cp -a /tmp/Doness/. <proj>/
rm -rf <proj>/.git          # 신규 repo로 재발급하므로 git 해제
```

### 3. 프로젝트화 (보일러플레이트 → 실제 앱)

- `{PROJECT_NAME}` placeholder 치환(`frontend/index.html`, `frontend/src/App.tsx`, `backend/app/main.py`).
- `.env.example`의 `COMPOSE_PROJECT_NAME`/`NETWORK_BRIDGE`/`DB_NAME`/`DB_USER` 등 → `<proj>`.
- `frontend/package.json` `name` → `<proj>-frontend`.
- 단일 컨테이너 패턴이면 자체 `nginx/`·`database/`·`wiki/`·`frontend/Dockerfile`·`frontend/nginx.conf`
  제거하고 루트 멀티스테이지 `Dockerfile` 하나로 통합.
- `README.md`/`CLAUDE.md`의 아키텍처·커맨드 섹션을 실제 구조에 맞게 정정.

### 4. 문서·카파시 init

- `<proj>/.gitignore` 하단 3줄(`GUIDELINE.md`/`skill.md`/`ai-docs/`) 주석 해제 → AI 컨텍스트 산출물
  추적 제외(실제 프로젝트 전환). Doness의 `skill.md`(수동 프롬프트 주입용)는 이 스킬로 대체되므로 그대로 무시/삭제.
- `ai-docs/context/current.md`를 새 프로젝트 초기 상태로 리셋(직전작업/다음우선순위 비움).
- 카파시 지침(`CLAUDE.md`)은 **유지** — 새 프로젝트가 그대로 상속.

### 5. 격리 git init → 신규 repo push

⚠️ **함정(실제 사고): `git init -b main`의 `-b`는 git<2.28 미지원.** 실패 시 이후 명령이 **상위 베이스
repo**에 작용해 오염 커밋·브랜치 개명이 발생한다. **격리를 반드시 검증한다.**

```bash
cd <proj>
git init -q
git symbolic-ref HEAD refs/heads/main         # -b 대신 (구버전 호환)
git rev-parse --show-toplevel                 # 반드시 .../<proj> 인지 검증 (베이스면 즉시 중단!)
git add -A
git -c user.name="D0iloppa" -c user.email="<email>" commit -m "feat: <Proj> 초기 구성"
gh repo create D0iloppa/<Proj> --private       # 가시성은 1단계에서 확정한 값
git remote add origin https://github.com/D0iloppa/<Proj>.git
git push -u origin main
```

> 사고 복구(베이스 오염 시): 베이스에서 `git branch -m <원래브랜치>`로 개명 되돌리고
> `git reset --mixed <직전커밋>`으로 오염 커밋만 해제(working tree 보존).

## 배선 층 (선택 — ② 층): 템플릿 + private 주입

공유 게이트웨이/네트워크 뒤에 붙는 스택이면, 코어 이후 배선을 렌더한다. **배선 패턴**은
`templates/integration/`(공개, placeholder만)이고, **환경 고유값**(네트워크·게이트웨이·도메인·인증서
경로·베이스 repo 등)은 **private 오버레이 repo**에서 주입한다. 서브모듈이 아니라 스크립트 주입이며,
**오버레이 접근 권한이 없으면 주입은 실패**한다(공개 사용자는 템플릿만 얻는다).

```bash
export DOIL_BOOTSTRAP_OVERLAY=<private 오버레이 repo git URL>   # 본인 환경에서 1회 설정
scripts/inject.sh <proj>                                        # 오버레이 값으로 배선 렌더 → <proj>/
```

- `templates/integration/*.tmpl` — `${PROJ}`·`${NETWORK}`·`${DOMAIN}`·`${DB_ALIAS}`·`${CERT_PATH}` 등
  placeholder만 있는 범용 배선(compose·게이트웨이 라우팅 등). 카탈로그: [`templates/integration/README.md`](templates/integration/README.md).
- **오버레이 repo(private)**: `values.env`(고유값 key=value) [+ 필요 시 배선 hook·상세 절차].
- `inject.sh`: `$DOIL_BOOTSTRAP_OVERLAY` clone(**권한 없으면 중단**) → `values.env` 로드 →
  화이트리스트 `envsubst`로 템플릿 렌더(대상 파일의 자체 `${VAR}`는 보존) → `<proj>`에 배치.

이 층이 불필요하거나 오버레이가 없으면 건너뛴다 — 코어만으로도 완결된 프로젝트가 선다.

## 완료 체크

- [ ] 아키텍처·메타 확정(묻고 받은 값)
- [ ] Doness 클론 + `.git` 제거 + `.gitignore` 3줄 해제
- [ ] placeholder/이름 치환, README/CLAUDE 정정
- [ ] `ai-docs/context/current.md` 초기화
- [ ] 격리 git init **검증**(`show-toplevel`=`<proj>`) 후 신규 repo push
- [ ] (선택) doil.me 통합 층 수행
