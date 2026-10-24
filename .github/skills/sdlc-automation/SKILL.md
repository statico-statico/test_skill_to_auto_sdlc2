---
name: sdlc-automation
description: >
  End-to-end SDLC automation skill that transforms Rally issues into
  GitLab Merge Requests. Generates spec-driven documentation (requerimientos.md,
  diseño.md), implements code changes, executes tests, manages git workflows
  with glab CLI, and maintains bidirectional traceability between Rally and GitLab.
  Activate when user mentions Rally IDs like US12345, DE6789, or asks to
  "automate SDLC", "issue to PR", "rally to merge request".
license: proprietary
compatibility: >
  Requires glab CLI authenticated, Rally MCP server configured in
  .vscode/mcp.json, git initialized repository.
allowed-tools: terminal codebase editFiles fetch mcp:rally-mcp
metadata:
  author: engineering-team
  version: "1.0.0"
  methodology: spec-driven-development
---

# SDLC Automation Skill — Operational Procedures

## Trigger Conditions
Activate this skill when:
- User provides a Rally FormattedID (pattern: `US\d+` or `DE\d+`)
- User asks to "automate", "implement", "develop" a Rally issue
- User mentions "issue to MR", "issue to PR", "rally to gitlab"

## Phase 1: Rally Issue Ingestion

### Step 1.1 — Query Rally via MCP
Use the `rally_openapi_search_tools` to find the correct WSAPI operation for
reading a HierarchicalRequirement or Defect.

Then use `rally_openapi_invoke_tool` to execute:
```
GET hierarchicalrequirement
  query: (FormattedID = "{ID}")
  fetch: FormattedID,Name,Description,AcceptanceCriteria,Notes,ScheduleState,
         Owner,Iteration,Project,Tags
```

### Step 1.2 — Validate State
```
IF ScheduleState == "Accepted":
  → ABORT: "Issue {ID} is already Accepted. Cannot modify accepted artifacts."
IF ScheduleState == "Completed":
  → WARN user and ask if they want to proceed
IF ScheduleState == "Defined":
  → Update ScheduleState to "In-Progress" via rally_openapi_invoke_tool
```

### Step 1.3 — Extract & Structure Context
Parse the following from Rally response:
- `title` ← Name
- `description` ← Description (strip HTML tags if present)
- `acceptance_criteria` ← AcceptanceCriteria (parse into discrete testable items)
- `notes` ← Notes (supplementary context)
- `iteration` ← Iteration.Name (for branch naming)

**🚪 GATE 1**: Present extracted context to user:
"I've extracted the following from Rally {ID}:
- Title: {title}
- {N} acceptance criteria identified
- Current state: {state} → transitioning to In-Progress
Does this look correct?"

---

## Phase 2: Specification Generation

### Step 2.1 — Detect Project Stack
Run the stack detection script via terminal:
```bash
# On Windows
.github/skills/sdlc-automation/scripts/detect-stack.bat

# On Unix/Mac
bash .github/skills/sdlc-automation/scripts/detect-stack.sh
```

### Step 2.2 — Generate requerimientos.md
Create file `.docs/requerimientos.md` using the template at
`templates/requerimientos.md`. Fill with:

1. **Header**: Rally ID, title, iteration
2. **User Story**: Reformulate from Description field
3. **Acceptance Criteria**: Convert each criterion to EARS notation
   (reference `references/ears-notation.md` for syntax)
   - Use CUANDO/EL SISTEMA DEBERÁ for event-triggered requirements
   - Use MIENTRAS for state-based requirements
   - Use SI for error/negative requirements
4. **Non-Functional Requirements**: Infer from context (performance, security)
5. **Out of Scope**: Explicitly state what this issue does NOT cover
6. **Open Questions**: Flag any ambiguities found in the Rally issue

### Step 2.3 — Generate diseño.md
Analyze the existing codebase via `#codebase` to understand:
- Project architecture patterns
- Existing conventions (naming, structure, dependency injection)
- Related components that will be affected

Create file `.docs/diseño.md` using the template at
`templates/diseño.md`. Include:

1. **Architecture diagram** (Mermaid) showing affected components
2. **Files to modify**: Exact paths with rationale
3. **New files to create**: With proposed content structure
4. **Data model changes**: If applicable
5. **Interface contracts**: New or modified APIs/functions
6. **Design decisions**: With alternatives considered
7. **Test strategy**: What tests to write and expected coverage
8. **Security considerations**: Input validation, auth, data protection

### Step 2.4 — Review Gate
**🚪 GATE 2**: Present both documents for human review.
"I've generated the specification documents:
- `.docs/requerimientos.md` — {N} requirements, {M} EARS criteria
- `.docs/diseño.md` — {P} files to modify, {Q} new files

Please review and approve before I proceed to implementation."

Options:
- ✅ Approved — proceed to implementation
- ⚠️ Needs adjustments — specify what to change
- ❌ Rejected — regenerate with corrections

**DO NOT proceed to Phase 3 without explicit approval.**

---

## Phase 3: Implementation & Testing

### Step 3.1 — Implement Code
Following the approved `diseño.md`:
1. Create/modify files in the order specified
2. Add traceability comments in each file:
   ```
   // Rally: {FormattedID} — {requirement reference}
   ```
3. Follow existing code conventions detected in Phase 2

### Step 3.2 — Run Tests (Self-Healing Loop)
Detect and execute the project's test command:
```
nodejs  → npm test / npx jest / npx vitest
python  → pytest / python -m pytest
dotnet  → dotnet test
java    → mvn test / gradle test
golang  → go test ./...
```

**Self-healing protocol:**
```
iteration = 0
MAX_ITERATIONS = 3

WHILE tests fail AND iteration < MAX_ITERATIONS:
  1. Read error output from terminal
  2. Identify failing test and root cause
  3. Apply targeted fix (do NOT rewrite entire files)
  4. Re-run tests
  5. iteration++

IF iteration == MAX_ITERATIONS AND tests still fail:
  → STOP and report to user with full error context
```

### Step 3.3 — Quality Checks
Reference `references/quality-checklist.md` and verify:
- [ ] No hardcoded credentials or secrets
- [ ] Input validation on all new user inputs
- [ ] Error handling for external calls
- [ ] Logging for important operations
- [ ] Code follows existing project conventions

### Step 3.4 — Implementation Review Gate
**🚪 GATE 3**: Present implementation summary.
"Implementation complete for {FormattedID}:
- {N} files modified, {M} files created
- Tests: {PASS/FAIL} ({X}/{Y} passing)
- Quality checklist: {status}

Ready to proceed with git workflow and MR creation?"

---

## Phase 4: Git Workflow & Merge Request

### Step 4.1 — Git Branch & Commit
Execute via `#terminal`:
```bash
# Create feature branch
BRANCH_NAME="feature/{FormattedID}-$(echo '{title}' | tr '[:upper:]' '[:lower:]' | tr ' ' '-' | head -c 50)"
git checkout -b "$BRANCH_NAME"

# Stage and commit
git add .
git commit -m "feat({FormattedID}): {concise_title}

- Implements requirements from Rally {FormattedID}
- See .docs/requerimientos.md for full specification
- See .docs/diseño.md for technical design

Rally-Issue: {FormattedID}"

# Push to remote
git push -u origin HEAD
```

### Step 4.2 — Generate report.md
Create `.docs/report.md` using template at `templates/report.md`.
Reference `references/quality-checklist.md` for structure.

Include:
1. **Executive Summary**: What was built and why
2. **Traceability Matrix**: Files ↔ Requirements mapping
3. **Code Quality Metrics**: Test results, coverage if available
4. **Best Practices Compliance**: SOLID, DRY, security checks
5. **Risk Assessment**: Known limitations, technical debt introduced
6. **Testing Summary**: What was tested, edge cases covered

### Step 4.3 — Create Merge Request
Execute via `#terminal`:
```bash
glab mr create \
  --title "feat({FormattedID}): {title}" \
  --description-file .docs/report.md \
  --target-branch main \
  --source-branch "$BRANCH_NAME" \
  --draft \
  --assignee @me \
  --label "bot-generated,{FormattedID}" \
  --yes
```

Capture the MR URL from stdout.

### Step 4.4 — Add MR Notes
```bash
glab mr note create {MR_IID} \
  -m "## 🤖 Automated SDLC Report

**Rally Issue:** {FormattedID}
**Specification:** See \`.docs/requerimientos.md\` and \`.docs/diseño.md\`
**Tests:** {PASS_COUNT}/{TOTAL_COUNT} passing

This MR was generated by the SDLC Automation Agent.
Please review the draft and mark as ready when approved."
```

### Step 4.5 — VCS Review Gate
**🚪 GATE 4**: Present MR details.
"Merge Request created:
- MR URL: {MR_URL}
- Branch: {BRANCH_NAME} → main
- Status: Draft
- Files changed: {N}

Shall I proceed to update Rally with the MR reference?"

---

## Phase 5: Rally Update & Closure

### Step 5.1 — Update Rally State
Use `rally_openapi_invoke_tool` to:
```
POST hierarchicalrequirement/{ObjectID}
  payload: { "ScheduleState": "Completed" }
```

### Step 5.2 — Add Rally Discussion Comment
Use `rally_openapi_invoke_tool` to add a ConversationPost:
```
Message: "Implementation completed by SDLC Automation Agent.

📋 Merge Request: {MR_URL}
📝 Specification: See .docs/requerimientos.md in branch {BRANCH_NAME}
📐 Design: See .docs/diseño.md in branch {BRANCH_NAME}
📊 Report: See .docs/report.md in branch {BRANCH_NAME}

Status: Awaiting human code review.
Next step: Product Owner acceptance after MR merge."
```

### Step 5.3 — Final Summary
Present to user:
```
✅ SDLC Cycle Complete for {FormattedID}

📋 Rally:    {FormattedID} → Completed (was: {original_state})
🔀 GitLab:   MR #{MR_IID} (Draft) → {MR_URL}
📝 Specs:    .docs/requerimientos.md, .docs/diseño.md
📊 Report:   .docs/report.md
🧪 Tests:    {PASS_COUNT}/{TOTAL_COUNT} passing

Pending actions:
1. Review MR and mark as Ready
2. Product Owner: Accept story in Rally after merge
```
