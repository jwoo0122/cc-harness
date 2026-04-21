# AC-A.2 — Corpus of 3 archived debates

Proves: inputs/ contains ≥3 distinct, non-empty, provenance-tagged corpus
files; README cross-references them; they aren't monocultural duplicates.

## Known false-pass risks
- "Provenance header in first 5 lines" is regex-level, so a single comment
  mentioning `iteration-1` passes even if the file's actual body is unrelated.
  This is accepted for Phase 1.5a; PLN audit challenges laziness.
- Topic-diversity heuristic is trigram-free and crude. It only catches
  identical-top-word monocultures, not subtler bias.
