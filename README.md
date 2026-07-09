# doil-bootstrap

범용 [Claude Code](https://claude.com/claude-code) 스킬. 새 프로젝트를 **Doness 보일러플레이트**에서
출발시켜 아키텍처 결정 → 프로젝트화 → **문서관리 규칙·카파시 원리·격리 git repo**까지 미리 init한다.

## 2층 구조

- **① 범용 코어** (항상, 어디서든): Doness 클론 → 아키텍처 결정 → 프로젝트화 → 문서/카파시 init →
  격리 신규 repo. 특정 인프라 비의존.
- **② 배선 층** (선택): 공유 게이트웨이/네트워크 뒤에 붙는 스택 배선. **패턴은 공개 템플릿**
  (`templates/integration/`, placeholder만), **환경 고유값은 private 오버레이 repo에서 스크립트 주입**.

방법론 본문: [`SKILL.md`](SKILL.md)

## 설치 (글로벌)

```bash
git clone https://github.com/D0iloppa/doil-bootstrap.git
cd doil-bootstrap
./install.sh          # <config>/skills/ 로 심볼릭 링크
```

## 배선 주입 (선택 — ② 층)

배선 층은 서브모듈이 아니라 런타임 스크립트로 주입한다. **오버레이 접근 권한이 없으면 주입은
실패**하고, 코어 산출물만 남는다(공개 사용자는 템플릿만 얻음).

```bash
export DOIL_BOOTSTRAP_OVERLAY=<private 오버레이 repo git URL>   # 본인 환경 1회 설정
scripts/inject.sh <proj-dir>
```

오버레이 repo(private) 규약: 루트에 `values.env`(`NETWORK`·`DB_ALIAS`·`DOMAIN_SUFFIX`·`CERT_PATH`·
`DNS_RESOLVER`·`PORT` 등 고유값) [+ 선택 `inject-hook.sh`]. placeholder 카탈로그는
[`templates/integration/README.md`](templates/integration/README.md).
