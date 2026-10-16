Im Folgenden sind Abschnitte von 2 Skills, die essenziell für die Entwicklung der App waren.
Für die Entwicklung von UR Artist wurden ingesamt mehr als 20 Skills verwendet. Davon wurden 13 bereits vor dem Schreiben der ersten Code-Zeile ausgewählt, und die restlichen ergaben sich aus Erkenntnissen während des Entwicklungsprozesses.

1. Swiftui Expert Skill: Großes Skill Folder mit mehreren Referenzpunkten, die den Agenten bei jeder möglichen UI Entscheidung klare Vorgehensweisen angibt. Hier ist nur ein relevanter Abschnitt des Skills:

# SwiftUI Expert Skill

## Operating Rules

- Consult `references/latest-apis.md` at the start of every task to avoid deprecated APIs
- Prefer native SwiftUI APIs over UIKit/AppKit bridging unless bridging is necessary
- Focus on correctness and performance; do not enforce specific architectures (MVVM, VIPER, etc.)
- Encourage separating business logic from views for testability without mandating how
- Follow Apple's Human Interface Guidelines and API design patterns
- Only adopt Liquid Glass when explicitly requested by the user (see `references/liquid-glass.md`)
- Present performance optimizations as suggestions, not requirements
- Use `#available` gating with sensible fallbacks for version-specific APIs

## Task Workflow

### Review existing SwiftUI code
- Read the code under review and identify which topics apply
- Flag deprecated APIs (compare against `references/latest-apis.md`)
- Run the Topic Router below for each relevant topic
- Validate `#available` gating and fallback paths for iOS 26+ features

{...}

2. iOS Code Audit Skill: Essenzieller Skill, der immer am Ende eines Zwischenziels angewandt wurde, um den Stand des gesamten Codes zu analysieren. Gibt dem menschlichen Überwacher klare Punkte, die er bevor das nächste Zwischenziel angegangen wird überprüfen sollte.

   
# iOS Code Audit Skill

## Operating rules

- **Read-only investigation, single deliverable.** No code changes — the output is `CODE_AUDIT.md` at the repo root.
- **Every finding cites `path/to/file.swift:LINE` (or a line range).** "Throughout the codebase" is never acceptable for a Critical or High item.
- **Severity is assigned conservatively.** Critical means crash / data loss / memory corruption / security exposure. Don't inflate. See the severity guide below.
- **Verify every Critical claim before propagating.** Agents will sometimes overstate severity. Open the cited file and confirm the bug is real. If you can't reproduce the claim by reading the lines, demote or drop.
- **Group by root cause, not by occurrence.** If one missing `@MainActor` annotation triggers seven warnings, that's one finding listing the seven sites, not seven findings.
- **`Dead/` (or any explicitly-archived directory) is excluded.** Check `CLAUDE.md` / project README for any "do not edit" directories before launching agents.

## Workflow

### Step 1 — Scope the codebase


Quick measurements to brief the agents:

```bash
find . -name "*.swift" -not -path "./.git/*" -not -path "./Dead/*" -not -path "*/Pods/*" -not -path "*/.build/*" | xargs wc -l 2>/dev/null | tail -1
find . -name "*.swift" -not -path "./.git/*" -not -path "./Dead/*" 2>/dev/null | wc -l
find . -name "*.metal" 2>/dev/null | wc -l
```

Also identify the **hot-spot files** (largest LOC, central state):

```bash
find . -name "*.swift" -not -path "./.git/*" -not -path "./Dead/*" -exec wc -l {} \; | sort -rn | head -10
```

Read `CLAUDE.md` if present — it usually flags central state files (e.g., `AppState.swift`, `CaptureState.swift`), the rendering pipeline, and any intentionally-excluded directories.

### Step 2 — Capture compiler ground truth {...}
### Step 3 — Launch the three parallel Explore agents {...}
### Step 4 — SwiftUI expert pass (if SwiftUI is in use) {...}
### Step 5 — Verify the Critical findings {...}
### Step 6 — Synthesize `CODE_AUDIT.md` {...}
