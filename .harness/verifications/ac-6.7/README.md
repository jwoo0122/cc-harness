# AC-6.7 — plugin.json description cleaned + bigram sync

Proves:
  - `.claude-plugin/plugin.json` .description has none of
    "3-persona", "3-role", "self-affirmation bias".
  - It shares ≥ 2 bigrams with marketplace.json's
    plugins[0].description.

Does NOT assert specific anchor phrases. Those are PLN planning
constraints, not part of AC-6.7 criteria text.

happy.sh        — real manifests.
adversarial.sh  — bigram extractor calibration (punctuation-robust;
                  false-positive-free).

Known false-pass risk: two descriptions sharing only generic bigrams
(e.g., "the harness", "three roles") would trivially pass without
being genuinely synchronized. Mitigation: forbidden-substring list +
PR review of actual description wording.
