// learnings-and-guards.ts — OpenCode-Plugin.
// Speicherort (im echten Home): ~/.config/opencode/plugin/learnings-and-guards.ts
// OpenCode entdeckt Plugins in diesem Ordner automatisch — kein Eintrag in opencode.json nötig.
//
// Bündelt drei Hooks, die zuvor offene _todo-Punkte waren:
//   1. session.idle      → halbautomatische Learning-Capture (Inbox-Pattern)
//   2. tool.execute.after → PostWrite ruff-format (Pendant zum Claude-Code PostToolUse-Hook)
//   3. tool.execute.before→ PreBash-Guard (Belt-and-Suspenders zu permissions.deny)
//
// Status: 🧪 emerging — Plugin-API + Event-Payload gegen die aktuelle Doku verifizieren:
//   https://opencode.ai/docs/plugins/   (API bewegt sich schnell).
//
// import type { Plugin } from "@opencode-ai/plugin"

import { appendFileSync } from "node:fs"
import { homedir } from "node:os"
import { join } from "node:path"

const INBOX = join(homedir(), ".config", "opencode", "LEARNINGS.inbox.md")

// Belt-and-Suspenders: dieselben Muster wie permissions.deny, hier als zweite Schicht.
const DANGEROUS = [
  /rm\s+-rf\s+\//,
  /sudo\s+rm\s+-rf/,
  /curl\s+.*\|\s*(bash|sh)/,
  /wget\s+.*\|\s*(bash|sh)/,
  /\bDROP\s+TABLE\b/i,
  /\bTRUNCATE\b/i,
]

export const LearningsAndGuards = async ({ client, $ }: any) => {
  return {
    // 1) Learning-Capture beim Idle-Werden der Session.
    //    session.idle ≈ "Agent fertig" → feuert mehrfach pro Session. DEDUP ist Pflicht.
    //    Für DSGVO-Profile small_model auf ein lokales Ollama-Modell zeigen lassen,
    //    damit kein Transkript in die Cloud geht.
    event: async ({ event }: any) => {
      if (event.type !== "session.idle") return
      try {
        // TODO(verify): Session-Messages/Transkript über `client` holen und an small_model
        // geben. Prompt = /capture-Regeln (eine Zeile, handlungsrelevant, nicht einmalig).
        // Leere Antwort ⇒ nichts schreiben. Vor dem Append per Hash gegen Doppel prüfen.
        const today = new Date().toISOString().slice(0, 10)
        const suggestion = "" // <- Modell-Ausgabe einsetzen
        if (suggestion.trim().length > 0) {
          appendFileSync(INBOX, `\n<!-- ${today} | inbox -->\n- [ ] proposed: ${suggestion}\n`)
        }
      } catch {
        /* Hook darf die Session nie crashen */
      }
    },

    // 2) ruff format nach jedem Write/Edit auf .py-Dateien.
    "tool.execute.after": async (input: any, output: any) => {
      if (input?.tool !== "write" && input?.tool !== "edit") return
      const path = output?.args?.filePath ?? output?.args?.path
      if (typeof path === "string" && path.endsWith(".py")) {
        try {
          await $`ruff format ${path}`
        } catch {
          /* ruff nicht installiert / kein .py — ignorieren */
        }
      }
    },

    // 3) PreBash-Guard: gefährliche Kommandos hart blocken (zweite Schicht zu permissions.deny).
    "tool.execute.before": async (input: any, output: any) => {
      if (input?.tool !== "bash") return
      const cmd: string = output?.args?.command ?? ""
      if (DANGEROUS.some((re) => re.test(cmd))) {
        throw new Error(`Blocked by PreBash-Guard: dangerous command pattern in: ${cmd}`)
      }
    },
  }
}
