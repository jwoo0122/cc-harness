# AC-6.1 — README word count ≤ 550

Proves `wc -w README.md` ≤ 550. Code fences count toward the total
(this is `wc -w`'s default — no fence-stripping is applied).

Run:
  bash .harness/verifications/ac-6.1/happy.sh

Current README is ~1100 words; this script is expected to FAIL
before INC-1 lands and PASS after.
