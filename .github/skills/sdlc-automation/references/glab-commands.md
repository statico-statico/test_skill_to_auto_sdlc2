# Referencia Rápida — glab CLI para el Agente SDLC

## Crear Merge Request

```bash
glab mr create \
  --title "feat({ID}): {title}" \
  --description-file .docs/report.md \
  --target-branch main \
  --draft \
  --assignee @me \
  --label "bot-generated,{ID}" \
  --yes
```

## Añadir nota al MR

```bash
glab mr note create {MR_IID} -m "mensaje"
```

## Verificar estado del MR

```bash
glab mr view {MR_IID}
```

## Listar MRs abiertas

```bash
glab mr list --state opened
```

## Cerrar un MR

```bash
glab mr close {MR_IID}
```

## Ver pipeline del MR

```bash
glab ci view {MR_IID}
```

## Flags de Seguridad — OBLIGATORIOS

| Flag | Razón |
|:-----|:------|
| `--yes` | Evita prompts interactivos que bloquean al agente |
| `--draft` | Impide merge accidental antes de review humano |
| `--description-file` | Preferido sobre `--description` (soporta markdown largo) |

## Flags PROHIBIDOS

| Flag | Razón |
|:-----|:------|
| `--attach` | Experimental, puede fallar silenciosamente |
| Sin `--yes` | Bloquea la ejecución del agente indefinidamente |

## Convenciones de Branch

```bash
# Formato estándar para feature branches
BRANCH_NAME="feature/{FormattedID}-$(echo '{title}' | tr '[:upper:]' '[:lower:]' | tr ' ' '-' | head -c 50)"

# Ejemplo resultante:
# feature/US12345-implement-user-authentication
```

## Convenciones de Commit

```bash
# Formato: Conventional Commits + Rally ID
git commit -m "feat({FormattedID}): {concise_title}

- Implements requirements from Rally {FormattedID}
- See .docs/requerimientos.md for full specification
- See .docs/diseño.md for technical design

Rally-Issue: {FormattedID}"
```

## Troubleshooting

| Problema | Causa | Solución |
|:---------|:------|:---------|
| `glab: command not found` | glab no instalado | `brew install glab` o `winget install GLab.GLab` |
| `401 Unauthorized` | Token expirado o inválido | `glab auth login` para re-autenticar |
| `could not detect git repository` | No hay `.git` en el directorio | Verificar que se ejecuta desde la raíz del repo |
| `remote origin not found` | No hay remote configurado | `git remote add origin {URL}` |
| MR creation hangs | Falta `--yes` | Siempre incluir `--yes` para evitar prompts |

## Verificación Pre-Vuelo

Antes de ejecutar el flujo git, el agente debe verificar:

```bash
# 1. glab está instalado y autenticado
glab auth status

# 2. Git está configurado
git config user.name
git config user.email

# 3. Remote origin existe
git remote -v

# 4. Branch actual está limpia
git status --porcelain
```
