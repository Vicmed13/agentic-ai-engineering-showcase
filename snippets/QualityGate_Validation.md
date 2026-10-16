Im Folgenden sind einige Guardrails und Validierungsschritte, die entweder vor oder während der agentischen Entwicklung ausgewählt und implementiert wurden. Diese dienen explizit dazu, den Agenten nicht intuitiv Code schreiben zu lassen. Stattdessen wird er gezwungen Voraussetzungen zu überprüfen, defensive patterns einzuhalten und echte plattformspezifische Einschränkungen zu validieren.

1. Pre-Flight Hardware & Permission Validation
The Validation Step:
Before initializing or mounting any ARView or ARSession, verify camera authorization asynchronously via AVCaptureDevice.authorizationStatus(for: .video).
Agentic Guardrail:
Never render camera views with an undetermined or denied state. Running an ARSession without an explicit pre-flight check causes "silent camera failures" (a black viewport with no Xcode runtime error or console output).
Validation Check: Ensure lifecycle state transitions account for all four non-crash states: .active, .limited(reason), .interrupted(reason), and .failed(error).

2. Defensive Codable Ingestion Validation

The Validation Step:
Audit all JSON-to-Swift decoding layers against the Acronym Trap and Omitted Array Trap.
Agentic Guardrail:
Acronyms: .convertFromSnakeCase translates look_id to lookId. If the Swift struct uses standard Swift acronym casing (lookID), the app crashes on decode. The agent must enforce explicit CodingKeys for fields with acronyms (ID, AR, HUD).
Null/Missing Fields: In tutorial datasets, preparation steps often omit coordinate arrays. The agent validates that custom init(from decoder:) implementations fall back to empty collections ([]) rather than throwing fatal decode errors.

3. Ground-Truth Compiler & Concurrency Audit

The Validation Step:
Extract actual compiler warnings via xcodebuild before asserting concurrency or deprecation issues.
Agentic Guardrail:
Never guess: "Capture compiler ground truth before writing audit reports." Concurrency claims must be backed by compiler warnings or code inspection, not hallucinated.
Single Root Cause Rule: If one missing @MainActor triggers 7 compiler warnings across a file, the agent groups them into 1 finding with 7 citations, rather than inflating the report with 7 separate critical bugs.
Evidence Verification: Before flagging a bug as Critical, the agent must verify that it can cause a crash, data loss, or security compromise at the cited file.swift:line.

4. Security & Keychain Access Validation

The Validation Step:
Scan all persistent storage code against the 10 Security Anti-Patterns.
Agentic Guardrail:
Examplary Anti-Patterns:
Anti-Pattern #1: Disallow storing authentication tokens, device IDs, or secrets in UserDefaults. Must use Keychain Services (kSecClassGenericPassword).
Anti-Pattern #3: Validate that biometric authentication (LAContext.evaluatePolicy) is not used as an isolated if-statement gate, but is tied directly to Keychain item access control (SecAccessControlCreateWithFlags).
Return Code Check: Validate that every Keychain query checks and handles the returned OSStatus (e.g., errSecItemNotFound, errSecDuplicateItem).

7. Global Keyboard Dismissal & Focus Validation

The Validation Step:
Verify text fields and navigation flows conform to the 3-point dismissal standard:
Window-Level Tap: A UITapGestureRecognizer attached to the root window with cancelsTouchesInView = false so it doesn't block scroll views or buttons.
Screen Transitions: An .onChange listener on navigation/workflow state variables that calls resignFirstResponder.
Return Key: Explicit .onSubmit blocks on TextField and SecureField that submit and dismiss the keyboard simultaneously.
