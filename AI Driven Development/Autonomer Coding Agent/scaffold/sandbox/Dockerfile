# Dockerfile — agent-sandbox:latest
# Sandbox fuer autonome OpenCode-Runs. Enthaelt OpenCode + Python-Toolchain.
# Egress ist im run-sandbox.sh-Wrapper OFFEN (ADR-010) — der Agent SOLL Doku ziehen.
# Isolation kommt aus: non-root user, KEINE Secret-Mounts, read-only root-fs (Projekt-Volume rw),
# tmpfs /tmp, Resource-Limits. Nicht aus Netzwerk-Abschottung.

FROM python:3.12-slim

# --- System-Tools + Node (fuer OpenCode) ---
RUN apt-get update && apt-get install -y --no-install-recommends \
        git curl ca-certificates build-essential ripgrep \
    && curl -fsSL https://deb.nodesource.com/setup_22.x | bash - \
    && apt-get install -y --no-install-recommends nodejs \
    && rm -rf /var/lib/apt/lists/*

# --- uv (schneller Python-Paketmanager, von den Pre-Commit-Guidelines vorausgesetzt) ---
RUN curl -LsSf https://astral.sh/uv/install.sh | sh \
    && mv /root/.local/bin/uv /usr/local/bin/uv

# --- OpenCode global ---
RUN npm install -g opencode-ai@latest

# --- non-root agent user ---
RUN useradd -m -u 1000 agent
USER agent
WORKDIR /workspace

# Validation-Toolchain vorinstallieren (deterministische Checks, siehe Pre-Commit Guidelines)
RUN pip install --user --no-cache-dir \
        pytest pytest-cov ruff mypy pre-commit interrogate \
        dirty-equals inline-snapshot

ENV PATH="/home/agent/.local/bin:${PATH}"
# pre-commit cache + ollama base url werden zur Laufzeit vom Wrapper gesetzt
ENV PRE_COMMIT_HOME="/workspace/.cache/pre-commit"

# Kein ENTRYPOINT — der Wrapper uebergibt das konkrete Kommando (opencode run ...).
