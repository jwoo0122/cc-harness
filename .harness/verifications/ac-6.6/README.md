# AC-6.6 — marketplace.json description cleaned

Asserts `.claude-plugin/marketplace.json` → `plugins[0].description`:
  - length ≤ 200 chars
  - contains no substring: "3-persona", "3-role", "self-affirmation"
    (case-insensitive).

Current value contains "3-persona"; expected FAIL pre-INC-2.
