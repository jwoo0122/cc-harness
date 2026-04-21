# AC-6.9 — Install commands are accurate

Asserts README.md:
  - does NOT contain `claude plugin install` (non-existent CLI).
  - if it mentions install/marketplace, uses `/plugin marketplace add`
    or `/plugin install` (real in-session slash commands).
