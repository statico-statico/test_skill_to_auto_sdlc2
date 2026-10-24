# Copilot Instructions

## SDLC Automation

This project uses the **SDLC Automation Agent Skill** for end-to-end development
lifecycle management. When working with Rally issues, use the `@sdlc-orchestrator`
agent or reference the skill at `.github/skills/sdlc-automation/SKILL.md`.

### Quick Start
1. Mention a Rally ID (e.g., "Automate US12345") to trigger the SDLC workflow
2. The agent will guide you through 5 phases with human review gates
3. All generated documentation goes to `.docs/` directory
4. All MRs are created as drafts for safety

### Available Agent
- `@sdlc-orchestrator` — Full SDLC cycle automation (Rally → Specs → Code → Tests → MR → Rally Update)

### Key Conventions
- **Branching**: `feature/{FormattedID}-{description}`
- **Commits**: Conventional Commits with Rally ID prefix
- **Documentation**: `.docs/requerimientos.md`, `.docs/diseño.md`, `.docs/report.md`
- **Safety**: All MRs as `--draft`, no force pushes, human gates at every phase
