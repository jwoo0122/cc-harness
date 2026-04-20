# Iteration Layout

`/explore` → `/execute` 닫힌 루프에서 이터레이션별 산출물이 저장되는 디렉터리 규약.

## Directory name

이터레이션 디렉터리는 프로젝트 루트 바로 아래에 위치하며, 이름은 반드시 다음 정규식을 따른다:

```
^\.iteration-[1-9][0-9]*$
```

예: `.iteration-1`, `.iteration-2`, `.iteration-42`.

잘못된 이름(`.iteration-0`, `.iteration-01`, `.iter-1`, `.Iteration-1` 등)은 `/explore` Phase 5 시작 시와 `/execute` Phase 0 시작 시 모두 명시적 에러로 중단된다.

## Required files

각 `.iteration-N/` 디렉터리는 다음 세 파일을 **필수(required)**로 포함한다:

- `brief.md` — `/explore` 결과 전략 브리프 (bet, appetite, boundaries, risk-flagged rabbit-holes).
- `verify-report.md` — `/execute` Phase 2~3의 AC별 검증 결과 리포트.
- `decision-log.md` — 이터레이션 간 의사결정 체크포인트 기록 (다음 이터레이션 진입 사유 포함).

이 세 파일의 이름은 고정이며, `plan.md`, `report.md`, `log.md` 같은 대체 이름은 허용되지 않는다.

브리프의 저장 위치는 항상 `.iteration-N/brief.md`이다. 레거시 산출물 경로는 더 이상 사용하지 않는다.

## .gitignore policy (opt-in tracking)

기본값으로 `.iteration-*/` 디렉터리 전체는 `.gitignore`에 포함된다. 민감 정보 누출을 방지하고 작업 공간을 깔끔하게 유지하기 위함이다.

특정 산출물(예: `verify-report.md`, `decision-log.md`)을 팀과 공유하고 싶다면 다음 중 하나의 **opt-in** 방법을 사용한다:

1. `.gitignore`에 negate 라인 추가:
   ```
   .iteration-*/
   !.iteration-*/verify-report.md
   !.iteration-*/decision-log.md
   ```
2. 또는 커밋 시점에만 `git add -f .iteration-<N>/verify-report.md` 로 강제 추가.

## Secret scan guidance

이터레이션 산출물에는 실험 로그, 환경 변수 참조, 디버그 출력 등 민감 정보가 혼입될 위험이 있다. 커밋 전(`pre-commit`) 단계에서 반드시 시크릿 스캔을 실행할 것을 권장한다.

추천 도구:
- [`gitleaks`](https://github.com/gitleaks/gitleaks) — pre-commit 훅으로 통합 (`gitleaks protect --staged`).
- 대안: `trufflehog`, `detect-secrets`.

예시 pre-commit 훅 설정은 각 도구 공식 문서를 참고.
