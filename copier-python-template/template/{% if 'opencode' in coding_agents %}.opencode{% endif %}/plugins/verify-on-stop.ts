// verify-on-stop.ts — OpenCode plugin. Reminds the agent about the "Verify"
// stage of Plan-Execute-Verify when a session ends with uncommitted changes.
// Mirrors the .claude/hooks/verify-on-stop.sh pattern.
//
// Default: SOFT-WARN (logs a reminder to stderr).
// Opt-in HARD-BLOCK: `export OPENCODE_VERIFY_HARD_BLOCK=1` — then `session.idle`
// throws until `just qa` passes.
//
// Reference: https://opencode.ai/docs/plugins/ (event: session.idle)

import type { Plugin } from "@opencode-ai/plugin"
import { execSync } from "node:child_process"

export const VerifyOnStop: Plugin = async ({ project }) => {
  const cwd = project.worktree ?? project.path ?? process.cwd()

  const hasDiff = (): boolean => {
    try {
      const out = execSync("git status --porcelain", { cwd, encoding: "utf-8" })
      return out.trim().length > 0
    } catch {
      return false // not a git repo → nothing to verify
    }
  }

  return {
    "session.idle": async () => {
      if (!hasDiff()) return

      if (process.env.OPENCODE_VERIFY_HARD_BLOCK === "1") {
        try {
          execSync("just qa", { cwd, stdio: "pipe" })
        } catch {
          throw new Error(
            "Stop blocked: `just qa` failed. Fix the errors, then continue.",
          )
        }
        return
      }

      // Soft warning — does not block the turn from ending.
      console.error(
        "Uncommitted changes detected. Run `just qa` and verify with evidence before declaring done.",
      )
    },
  }
}
