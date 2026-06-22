# Repo-root justfile — Template-Smoketests.
# Das gerenderte Projekt hat sein eigenes justfile (siehe
# copier-python-template/template/justfile.jinja).

default:
    @just --list

# --- Template docs site -----------------------------------------------------
# Docs for the template itself (copier-python-template/docs/). The generated
# project has its own docs site rendered from template/mkdocs.yml.jinja.

# Serve the template docs locally with live reload.
docs:
    uv run --with 'mkdocs-material>=9.5' \
        mkdocs serve -f copier-python-template/mkdocs.yml

# Strict build into copier-python-template/site/.
docs-build:
    uv run --with 'mkdocs-material>=9.5' \
        mkdocs build --strict -f copier-python-template/mkdocs.yml

# Notes:
# - Test 1: Claude-Code-only, kein Sandbox (Minimal-Pfad).
# - Test 2: Full-Stack mit Langfuse v3 + Crawl4AI — aktiviert alle
#   profil-gegateten `:?`-Guards (SEARXNG_SECRET, CRAWL4AI_API_TOKEN,
#   LANGFUSE_ENCRYPTION_KEY, LANGFUSE_NEXTAUTH_SECRET).
# - Test 3: Full-Stack mit MLflow — anderer Compose-Jinja-Branch
#   (`elif sandbox_observability == 'mlflow'`) als Langfuse und der
#   eigentliche copier.yml-Default.
# - Compose-Check braucht `--profile dev --profile trace` — sonst
#   filtert Compose alle profil-gegateten Services raus und der Test
#   wird zum False-Pass (Output `services: {}`).
# - `--defaults` koppelt den Test an die aktuellen copier.yml-Defaults:
#   eine Default-Verschiebung verschiebt den Coverage-Scope mit, ohne
#   dass der Test rot wird.

# Render-Smoketest: drei Copier-Szenarien + JSON- + Compose-Validierung.
render-test:
    #!/usr/bin/env bash
    set -euo pipefail

    rm -rf /tmp/render-test-1 /tmp/render-test-2 /tmp/render-test-3

    uv tool run copier copy --trust --defaults --vcs-ref=HEAD \
      --data project_name="Test1" \
      --data coding_agents='["claude_code"]' \
      --data claude_provider=subscription \
      --data include_sandbox=false \
      copier-python-template /tmp/render-test-1

    uv tool run copier copy --trust --defaults --vcs-ref=HEAD \
      --data project_name="Test2" \
      --data coding_agents='["claude_code","opencode","aider"]' \
      --data include_sandbox=true \
      --data sandbox_observability=langfuse \
      --data include_crawl4ai=true \
      copier-python-template /tmp/render-test-2

    uv tool run copier copy --trust --defaults --vcs-ref=HEAD \
      --data project_name="Test3" \
      --data coding_agents='["claude_code","opencode"]' \
      --data include_sandbox=true \
      --data sandbox_observability=mlflow \
      copier-python-template /tmp/render-test-3

    python3 -m json.tool /tmp/render-test-1/.claude/settings.json >/dev/null
    python3 -m json.tool /tmp/render-test-2/.claude/settings.json >/dev/null
    python3 -m json.tool /tmp/render-test-2/opencode.json >/dev/null
    python3 -m json.tool /tmp/render-test-3/.claude/settings.json >/dev/null
    python3 -m json.tool /tmp/render-test-3/opencode.json >/dev/null

    # cd in den Render-Pfad, damit die von `sandbox-init` generierte
    # .env automatisch aufgegriffen wird und die :?-Guards greifen.
    (cd /tmp/render-test-2 \
        && docker compose --profile dev --profile trace config) >/dev/null
    (cd /tmp/render-test-3 \
        && docker compose --profile dev --profile trace config) >/dev/null

    echo "render-test passed"
