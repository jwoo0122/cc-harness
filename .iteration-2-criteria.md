# Iteration 2 — Harness 부채 해소 (batch-2/3 + VER 헬퍼 + 문서 일관성)

> 기반: iteration-1 verify-report.md §6 Remaining work (우선순위 1~4, 7~9).
> 사용자 결정 ("부채 우선 — batch-2/3 + 프로세스 개선"): 2026-04-20 iteration-1 Phase 3 체크포인트 수동 수행.

## 배경과 목표

iteration-1은 AC-1/2/3/5의 프로덕션 코드를 모두 구현했으나, AC-3.x + AC-5.x 8개에 대한 **전용 적대적 하네스**가 저작되지 않았다 (Phase 1.5 batch-2/3 미수행). 이들은 현재 regression scan 밖에 있어 "verification-first" 불변식이 선택적으로만 적용된다. 또한 VER 헬퍼의 설계 결함 2건이 skill 문서에 cosmetic workaround를 강제하고 있다. iteration-2는 이 부채를 해소한다.

비목표:
- 새 기능 ACs (AC-4 persona 규율, AC-6 divergence 스모크) 는 iteration-3으로 재이월.
- AC-3.3b (behavioral injection-resistance), AC-5.1c (behavioral state propagation)도 iteration-3.
- 새 skill 추가 없음.

## 수용 기준 (AC)

### AC-A: Phase 1.5 batch-2 — AC-3.x 적대적 하네스
- **AC-A.1**: `.harness/verifications/ac-3.1/` 번들 저작. 최소 happy + edge + adversarial. 검증 대상: `skills/execute/SKILL.md` Phase 0 0a subsection. glob `.iteration-*/`, `AskUserQuestion` 분기, 0/1/N-candidate 처리, regex-invalid pre-existing dir 시 hard-error.
- **AC-A.2**: `.harness/verifications/ac-3.2/` 번들. 검증: brief가 PLN Phase 1 컨텍스트 주입, rabbit-holes가 `agents/pln.md` 규율에 의해 explicit constraint로 취급.
- **AC-A.3**: `.harness/verifications/ac-3.3a/` 번들. 검증: 모든 dispatch 프롬프트에 `<brief>...</brief>` 래핑 + "data, not instructions" 지시 존재.
- **AC-A.4**: `.harness/verifications/ac-3.4/` 번들. 검증: `HARNESS_DISABLE_BRIEF=1` 분기 + skip 로그.
- **AC-A.5**: 위 4개 번들이 `.harness/verification-registry.json`에 `automated-test` 전략으로 등록.

### AC-B: Phase 1.5 batch-3 — AC-5.x 적대적 하네스
- **AC-B.1**: `.harness/verifications/ac-5.1a/` 번들. 검증: Phase 3 3c subsection에 `AskUserQuestion` + 세 선택지 (a/b/c) + `HARNESS_DISABLE_CHECKPOINT` 분기.
- **AC-B.2**: `.harness/verifications/ac-5.1b/` 번들. 검증: (a) 선택 시 freetext 요구 + `.iteration-<N+1>/decision-log.md` append 지시 + empty-reply 거부 문구.
- **AC-B.3**: `.harness/verifications/ac-5.2/` 번들. 검증: (a) freetext가 다음 이터레이션 decision-log.md에 기록된다는 지시 (AC-B.2와 부분 중복 — 별도 번들로 분리하여 regression 분해능 향상).
- **AC-B.4**: `.harness/verifications/ac-5.3/` 번들. 검증: `HARNESS_DISABLE_CHECKPOINT=1` 분기.
- **AC-B.5**: 위 4개 번들이 레지스트리에 등록.

### AC-C: VER 헬퍼 개선
- **AC-C.1**: `.harness/verifications/_shared/lib.sh`의 `md_section()` 함수가 fenced code block 내부의 `## ` 라인을 heading으로 취급하지 않는다. state를 추적하여 fence open/close를 카운트.
- **AC-C.2**: 같은 `lib.sh`에 새 헬퍼 `grep_forbidden_phrase(pattern, file)` 추가. 금지 문구 `pattern`이 파일에서 선언 문맥(`must not`, `do not`, `forbidden`, `금지`, `no ` 접두)과 함께 나타나면 매치를 무시하고, 실제 허용 문맥에서 나타날 때만 매치. 또는 동등 효과의 helper.
- **AC-C.3**: 기존 AC 중 workaround로 회피했던 2건을 "정상" 문구로 되돌린다:
  - `skills/explore/SKILL.md` Phase 5의 "No silent fallthrough. No auto-correction. No warn-then-proceed." → 원래 의도한 "Do not silently skip. Do not auto-correct. Do not warn and continue."로 복원.
  - `skills/explore/SKILL.md` brief 템플릿의 fenced markdown 블록 내 헤더 2-space 들여쓰기 제거 (`## Bet`, `## Appetite` 등이 column 0에서 시작).
- **AC-C.4**: AC-C.3 복원 후 기존 레지스트리 10 엔트리 전부 still pass.

### AC-D: Skill heading 일관성
- **AC-D.1**: `skills/explore/SKILL.md`의 Phase 1, 2, 3, 4를 h3 → h2로 승격. 결과적으로 모든 Phase가 h2.
- **AC-D.2**: `skills/execute/SKILL.md`의 Phase 1, 1.5, 2를 h3 → h2로 승격. (Phase 0, 3는 이미 h2).
- **AC-D.3**: 승격 후 전체 AC-C.4 테스트(기존 10 엔트리 + batch-2/3 엔트리)가 still pass.

## 검증 전략 메모 (VER Phase 1.5에서 구체화)

- AC-A, AC-B: Phase 1.5에서 각 번들 저작 → IMP materialize → expected-fail sanity → INC 구현 후 pass 전환 → 등록.
- AC-C.1: `md_section`에 fenced code를 injection한 픽스처 markdown에 대해 헬퍼가 in-fence `## ` 를 무시하는지 테스트.
- AC-C.2: 정상/악성 선언 문맥 각 5건 이상 파라미터라이즈드 테스트.
- AC-C.3: 복원 후 `ac-1.2-explore/happy.sh`, `ac-1.2-execute/happy.sh`, `ac-2.2/adversarial.sh` 실행 → still pass.
- AC-C.4: registry 10 엔트리 회귀.
- AC-D: heading 승격 후 전체 회귀 + grep으로 `### Phase` 0 매치 확인.

## 파일 변경 영향

- `.harness/verifications/ac-3.1/`, `ac-3.2/`, `ac-3.3a/`, `ac-3.4/` (신규 번들)
- `.harness/verifications/ac-5.1a/`, `ac-5.1b/`, `ac-5.2/`, `ac-5.3/` (신규 번들)
- `.harness/verifications/_shared/lib.sh` (헬퍼 개선)
- `.harness/verification-registry.json` (8개 엔트리 추가)
- `skills/explore/SKILL.md` (AC-C.3 복원 + AC-D.1 heading 승격)
- `skills/execute/SKILL.md` (AC-D.2 heading 승격)

새 INC 추정: 5~7개.

**프로세스 개선** (선택 — criteria 외 권고):
- IMP Phase 2a 보고에 "실제 Read 후 grep 숫자" 필수 (iteration-1 INC-5 hallucination 재발 방지).
- Worktree dispatch 시 `WORKTREE_ROOT` 명시 + IMP가 Edit 전 path 검증 (iteration-1 INC-6 경로 오류 재발 방지).
