// autonomous-guards.ts — OpenCode-Plugin fuer den AUTONOMEN Modus.
// Platzierung: im PoC-Repo unter .opencode/plugin/autonomous-guards.ts, damit es ueber den
// Worktree-Mount in die Sandbox gelangt (OpenCode entdeckt Plugins automatisch).
//
// Drei Guards — unter `--dangerously-skip-permissions` ist das die EIGENTLICHE Sicherheitsschicht,
// weil ask->allow wird und nur deny + diese Hooks bleiben:
//   1. tool.execute.before (bash)     -> gefaehrliche Kommandos hart blocken
//   2. tool.execute.before (webfetch) -> jede URL ins Egress-Audit-Log (offener Egress, ADR-010)
//   3. tool.execute.after  (write/edit)-> ruff format auf .py (deterministische Hygiene)
//
// Status: 🧪 emerging — Plugin-API + Event-Payload gegen https://opencode.ai/docs/plugins/ verifizieren.
// import type { Plugin } from "@opencode-ai/plugin"

import { appendFileSync } from "node:fs"

const AUDIT = "/workspace/.agent-egress-audit.log"

// Dieselben Muster wie permissions.deny — hier als harte zweite Schicht.
const DANGEROUS = [
  /rm\s+-rf\s+(\/|~)/,
  /sudo\s+/,
  /curl\s+.*\|\s*(bash|sh)/,
  /wget\s+.*\|\s*(bash|sh)/,
  /\bDROP\s+TABLE\b/i,
  /\bTRUNCATE\b/i,
  /\bgit\s+push\b/,
  /\bdd\s+if=/,
  /:\(\)\s*\{\s*:\|:&\s*\};:/, // fork bomb
]

export const AutonomousGuards = async ({ $ }: any) => {
  return {
    "tool.execute.before": async (input: any, output: any) => {
      const tool = input?.tool
      if (tool === "bash") {
        const cmd: string = output?.args?.command ?? ""
        if (DANGEROUS.some((re) => re.test(cmd))) {
          throw new Error(`Blocked by autonomous-guard: dangerous command: ${cmd}`)
        }
      }
      if (tool === "webfetch") {
        // Offener Egress -> wir blocken nicht, aber wir protokollieren jede URL.
        const url: string = output?.args?.url ?? output?.args?.query ?? "?"
        try {
          appendFileSync(AUDIT, `${new Date().toISOString()}\tfetch\t${url}\n`)
        } catch {
          /* never crash the session */
        }
      }
    },

    "tool.execute.after": async (input: any, output: any) => {
      if (input?.tool !== "write" && input?.tool !== "edit") return
      const path = output?.args?.filePath ?? output?.args?.path
      if (typeof path === "string" && path.endsWith(".py")) {
        try {
          await $`ruff format ${path}`
        } catch {
          /* ruff fehlt / kein .py — ignorieren */
        }
      }
    },
  }
}
