# Iteration 4 — Multi-provider 페르소나 매핑 착수 (baseline + PLN→Codex)

> 기반: 2026-04-21 /explore 세션 합성 결과. 사용자 scope 선택 (b): Baseline variance 측정 + PLN→Codex 1개 선제응. 직전 메타-디베이트 결론: "동질-모델 ensemble은 페르소나 prompt만 다를 뿐 같은 뉴럴 네트워크의 샘플링이라 상관된 blindspot을 공유."

## Bet

동질-모델 ensemble의 상관된 blindspot 문제를 해소하는 첫 단계로, (1) 과거 디베이트의 baseline variance를 측정해 향후 매핑 실험의 평가 기준(delta > 2σ)을 확보하고, (2) 디베이트에서 가장 안전하게 합의된 PLN→Codex 매핑을 선제응하여 계측 infra를 실전 검증한다. IMP/VER은 writing-heavy + hook-gated이므로 Claude 유지.

## Appetite

1 이터레이션. INC 5–7개. INC-1 (baseline 측정)을 gate로 두고, INC-2~4 (call-codex.sh + hook whitelist + PLN 분기)를 순차 진행. baseline variance σ가 비합리적으로 크면 PLN 매핑 실험 자체를 iter-5로 연기.

## Boundaries / Non-goals

- IMP=Claude, VER=Claude 고정 (사용자 정책 + `gate-mutating.sh` hook은 `agent_type=imp`에만 반응). iter-4에서 변경 금지.
- Fork octopus 전체 vendor import는 iter-5 이후. 이번 이터레이션은 `call-codex.sh` (경량 wrapper) + preflight auth만.
- OPT/PRA/SKP/EMP 매핑 변경 금지. baseline 데이터 + sycophancy 측정 이후 iter-5 결정.
- 15pp recall-lift 같은 고정 threshold 설정 금지. σ 기반 상대 threshold만 인정.
- Silent-skip 금지 (claude-octopus CHANGELOG 선행 버그, claude-code issues #49541 / #19468).
- 새 skill 추가 없음. 기존 explore/execute SKILL.md만 수정.

## 수용 기준 (AC)

### AC-A: Baseline variance 측정 infrastructure

- **AC-A.1**: `.harness/experiments/baseline-variance/` 디렉터리 생성. README.md에 목적, 재현 절차, 메트릭 정의, 사용된 archived 디베이트 소스 명시.
- **AC-A.2**: archived 디베이트 코퍼스 3개 선정 및 샘플 입력으로 명시 (`inputs/` 하위). 소스: `.iteration-1-criteria.md`, `.iteration-2-criteria.md`, 직전 메타-디베이트 합성 결과 등.
- **AC-A.3**: 측정 스크립트 (`run.sh` 또는 `measure.sh`) 작성 — 같은 입력에 대해 현재 /explore를 5회 재실행하고 페르소나 stance agreement rate, Round 3 surviving recommendation 일치율 메트릭을 `.harness/experiments/baseline-variance/results.jsonl`에 append-only 기록. 스키마 버전 필드(`schema_version`) 포함.
- **AC-A.4**: σ 요약 보고서 `.harness/experiments/baseline-variance/summary.md` 자동 생성 — 평균, σ, 95% 신뢰구간, 샘플 수.

### AC-B: Codex CLI 호출 스크립트 (preflight + loud-fail)

- **AC-B.1**: `.harness/scripts/call-codex.sh` 생성 — stdin 프롬프트 수신, `codex exec --json` 호출, JSON Lines 응답 본문만 stdout으로 출력.
- **AC-B.2**: Preflight auth check — `command -v codex` 실패 또는 API 키 env 미설정 시 stderr에 `⚠ Codex preflight failed: <reason>` 경고 출력 후 exit 2로 종료. Silent-skip 금지.
- **AC-B.3**: 타임아웃 (기본 60s) 적용 — 초과 시 stderr 경고 + exit 3. 타임아웃 값은 env `HARNESS_CODEX_TIMEOUT`로 override 가능.
- **AC-B.4**: 프롬프트 주입 안전성 — 사용자 프롬프트를 ARGV로 받지 않고 stdin으로만 처리. shell metacharacter 이스케이프 검증.

### AC-C: Hook whitelist 확장

- **AC-C.1**: `skills/execute/gate-mutating.sh`에 Bash tool 허용 조건 추가 — `tool_name=Bash` AND `command`가 정규식 `^\.harness/scripts/call-[a-z]+\.sh$`에 매치되면 agent_type 상관없이 허용. 다른 Bash 명령은 기존 정책(IMP만 허용)이 유지되어야 함. **IMP는 기존처럼 전체 Edit/Write/Bash 가능.**
- **AC-C.2**: `skills/explore/block-mutating.sh`에 동일 whitelist 추가. Bash 자체는 여전히 차단이지만 `^\.harness/scripts/call-[a-z]+\.sh$`만 예외 허용.
- **AC-C.3**: 화이트리스트 정규식이 `.harness/scripts/call-evil.sh` 같은 임의 이름으로 악용될 위험 — 대응: 스크립트 이름은 `call-<provider>.sh` 엄격 패턴, provider 리스트(`codex`, `gemini`, 미래 확장)는 hook 내부 화이트리스트로 관리.

### AC-D: PLN 디스패치 분기 (optional Codex call)

- **AC-D.1**: `skills/execute/SKILL.md`의 Phase 1 PLN 디스패치 섹션에, 환경변수 `HARNESS_PLN_PROVIDER=codex`가 설정되면 `.harness/scripts/call-codex.sh`를 통해 PLN 호출, 미설정이면 기존 `Agent(subagent_type: "pln", ...)` 경로 유지한다는 분기 로직 명시.
- **AC-D.2**: Codex 호출 실패(exit 2/3) 시 자동 fallback to Claude PLN + stderr에 loud 경고. Silent fallback 금지.
- **AC-D.3**: PLN 출력 포맷 — Codex와 Claude 양쪽 모두 동일한 INC plan 구조(markdown bullet list)를 유지하도록 prompt에 포맷 제약 명시. 불일치 시 Claude PLN fallback.
- **AC-D.4**: Phase 2d의 "AC 판정 cross-check" PLN 디스패치는 이번 이터레이션에서는 **Claude 전용** 유지(스코프 축소). Codex 분기는 Phase 1 플래닝에만 적용.

### AC-E: 문서 + re-measure

- **AC-E.1**: `docs/multi-provider-dispatch.md` 작성 — 개요, 사용법 (`HARNESS_PLN_PROVIDER`), 실패 모드, debug 팁, iter-5 로드맵.
- **AC-E.2**: 이터레이션 말 re-measure — INC-1 baseline variance 스크립트를 `HARNESS_PLN_PROVIDER=codex`로 1회 재실행. 결과를 `.harness/experiments/baseline-variance/codex-pln-probe.md`에 기록. 결론(ship/kill)은 iter-5로 연기 — 이번 이터레이션은 수치 확보만.

## 검증 전략 메모 (VER Phase 1.5에서 구체화)

- **AC-A**: 결정론성 — 같은 시드/입력으로 2회 실행 결과 일치 테스트. edge: 코퍼스 파일 누락 시 명시적 에러, 메트릭 NaN 방어. adversarial: 코퍼스 파일에 악의적 콘텐츠(거대 문자열, binary) 주입 시 스크립트 안정성.
- **AC-B**: preflight 실패 4가지 시나리오 — (i) missing codex binary, (ii) stale/absent API token, (iii) quota exceeded mock (API 응답 4xx/5xx), (iv) network down. 각 시나리오 stderr 경고 + 올바른 exit code + NO silent continue. adversarial: API-key 형태 문자열(`sk-...` / `AIza...`)이 stdin에 포함되면 호출 로그·stderr·results에 잔존 여부 검증(redaction).
- **AC-C**: gate hook이 `call-evil.sh`, `.harness/scripts/../../evil.sh`, 절대경로 bypass 시도 등 5가지 이상 우회 시도를 차단하는지. PLN/VER 에이전트가 화이트리스트를 통해 Bash를 쓸 수 있는지 (explore에서도) 양성 테스트.
- **AC-D**: Codex stub (고정 응답 반환하는 테스트용 `call-codex.sh` mock)으로 PLN 호출 분기 동작 확인. Codex 실패 → Claude fallback 경로 전체. PLN 출력 포맷 불일치 시 fallback 동작 검증.
- **AC-E**: 문서의 각 필수 필드 존재 검증(heading grep), re-measure 숫자가 results.jsonl에 기록되는지.

## Risk-flagged rabbit-holes (VER Phase 1.5 적대적 probe 필수)

- **Codex CLI 인증 폴리싱**: preflight check가 실제로 모든 실패 경로 (missing binary / stale token / quota exceeded / network down)를 커버하나? VER: 4개 실패 시나리오 각각 inject, 모두 stderr loud warning + olaf fallback 관찰.

- **Codex 호출 스크립트 인젝션/secret 유출**: `call-codex.sh`가 사용자 프롬프트를 stdin으로 받을 때 quoting 처리가 shell injection에 안전한가? 프롬프트에 API key-shape 문자열이 포함되면 Codex에 전송·기록에 잔존할 위험? VER: fake API-key 문자열 inject, 호출 로그·stderr·Codex side에 잔존 여부 검증.

- **Baseline variance 코퍼스의 representativeness**: archived 디베이트 3개 × 5회 반복 = 15 runs이 σ 추정에 통계적으로 충분한가? 특정 topic에 편향된 코퍼스이면 baseline이 잘못 설정됨. VER: topic-category covariance 점검, σ 신뢰구간 보고. (n=15는 의도적으로 작은 표본 — 이터레이션-4에서는 변동성 scope만 확보, 정밀 추정은 iter-5+ 데이터로.)

- **PLN→Codex character/role fidelity**: Codex-Max 모델이 PLN의 "scope and order" 역할을 Claude만큼 정교하게 수행하나? 증분 3-파일 제한, AC-coverage 점검, IMP/VER 반려 대응 스타일이 보존되나? VER: 같은 플래닝 프롬프트에 대해 Claude PLN vs Codex PLN 출력 비교, 계획 품질 metrics (증분 수, AC-coverage 완전성, re-dispatch 횟수) 5회 각각 측정.

- **Hook whitelist 범위 확대의 부작용**: `gate-mutating.sh`와 `block-mutating.sh`에 `.harness/scripts/call-*.sh` 화이트리스트를 추가하면, 장래 악의적 스크립트가 이 이름 규약을 훔쳐 코드 변경을 우회할 위험. VER: `call-evil.sh` 같은 이름으로 Edit/Write 시도, 실제로 추가 권한을 얻는지 검증.

- **Persona collapse under correlated provider failure** (SKP uncured risk, 측정 대상): 모든 frontier 모델이 동일 training-data bias를 공유하는 특정 topic(AI safety, 최신 framework)에서 debate가 echo chamber로 수렴 가능. Provider diversity는 이 risk에 zero protection. iter-4는 감지 infra(baseline variance)만 확보 — 예방은 iter-5+ scope.

## 파일 변경 영향

예상 수정/생성:
- `.harness/experiments/baseline-variance/` (신규 디렉터리: README.md, inputs/, run.sh, results.jsonl, summary.md)
- `.harness/scripts/call-codex.sh` (신규)
- `skills/execute/gate-mutating.sh` (수정)
- `skills/explore/block-mutating.sh` (수정)
- `skills/execute/SKILL.md` (PLN 분기 — Phase 1만)
- `docs/multi-provider-dispatch.md` (신규)
- `.harness/verifications/ac-A.*/`, `ac-B.*/`, `ac-C.*/`, `ac-D.*/`, `ac-E.*/` (Phase 1.5에서 VER 저작)
- `.harness/verification-registry.json` (엔트리 추가)

마이크로 인크리먼트당 3파일 제한 고려 시 PLN은 5–8개 INC로 분해 예상.
