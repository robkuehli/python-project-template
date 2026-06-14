# Architecture Decision Records: Autonomer lokaler Coding-Agent

**Status:** Accepted v1
**Datum:** 2026-05-18
**Kontext:** Tool-Auswahl für autonomes Coding-Setup gemäß `01-project-brief.md`

---

## ADR-001: Hybride Aufteilung – Frontier-Modell für Spec, lokales Modell für Code

### Status
Accepted

### Kontext
Vollständig lokale Setups scheitern oft daran, dass die Spec-Phase reasoning-intensiv ist und lokale Modelle hier deutlich schwächer abschneiden als Frontier-Modelle. Gleichzeitig wäre eine vollständig API-basierte Code-Generierung über Nacht teuer (zweistellig pro Nacht bei realistischem Volumen).

### Entscheidung
- **Spec-Phase** (Specification, Plan, Tasks-Decomposition): Frontier-Modell via Web-UI (Claude.ai oder ChatGPT)
- **Implementation-Phase** (Code, Tests, Iterationen): Lokales Modell

### Konsequenzen
**Positiv:**
- Kognitive Last (Architektur, Test-Design) liegt beim besten verfügbaren Modell
- Code-Generierungs-Volumen (millionenfach Tokens über Iterationen) verursacht keine API-Kosten
- Spec-Phase kostet < 1 € pro PoC

**Negativ:**
- Zwei separate Workflows, leicht erhöhte Komplexität
- Spec wird als Markdown-Artefakt zwischen den Systemen übertragen (manueller Schritt)

### Verworfene Alternativen
- **Vollständig lokal (auch Spec):** Spec-Qualität lokaler Modelle ist deutlich schlechter; führt zu vagen Specs und damit zu schlechten Implementierungen. Abgelehnt.
- **Vollständig per API:** Kosten skalieren mit Code-Iterationen; widerspricht F1 und N1 aus dem Brief. Abgelehnt.

---

## ADR-002: OpenCode als primärer Coding-Agent (gegen Hermes Agent als Haupt-Layer)

### Status
Accepted

### Kontext
Mehrere Coding-Agenten kommen in Frage: Hermes Agent (Nous Research), OpenCode (provider-agnostisch), Claude Code (Anthropic), Codex CLI (OpenAI). Die letzten beiden setzen Frontier-APIs voraus und scheiden für unseren Use-Case aus.

### Entscheidung
**OpenCode** als Haupt-Agent. Hermes Agent wird **nicht** als primärer Layer eingesetzt, kann aber optional als Scheduling-/Notification-Layer obendrauf laufen.

### Begründung
- OpenCode ist provider-agnostisch und versteht Spec-Kit-kompatible Slash-Commands (ADR-004)
- OpenCode arbeitet nativ mit OpenAI-kompatiblen Endpoints, also direkt mit Ollama
- Hermes Agent bringt für unseren Use-Case zu viel Overhead mit (Telegram/Discord-Gateway, Cross-Session-Memory, Skill-Marketplace), das wir nicht brauchen
- Die Hermes-Community selbst dokumentiert: Lokale Modelle sind für Hermes' Multi-Step-Tool-Calling-Workflow weniger zuverlässig; Hermes ist primär für Frontier-Modelle optimiert

### Konsequenzen
**Positiv:**
- Schlankere Architektur, weniger bewegliche Teile
- Direkter Code-Pfad: Spec-Kit → OpenCode → Ollama → Disk
- Einfacheres Debugging bei Fehlern

**Negativ:**
- Keine eingebauten Memory/Learning-Features (für unseren Stateless-Use-Case egal)
- Keine Messenger-Integration (durch einfachen curl-Hook im Orchestrator ersetzbar)

### Verworfene Alternativen
- **Hermes Agent als Haupt-Layer:** Overkill, nicht für lokale Modelle optimiert, mehr Komplexität als Nutzen.
- **Claude Code:** Setzt Frontier-API voraus, widerspricht N1.
- **Aider:** Solider Coding-Agent, aber schwächere Spec-Kit-Integration als OpenCode.
- **OpenHands (ehem. OpenDevin):** Mehr auf SWE-bench-Style Issue-Resolution ausgelegt, weniger auf Greenfield-PoCs.

---

## ADR-003: Qwen3-Coder 30B-A3B als primäres lokales Modell

### Status
Accepted

### Kontext
Wir brauchen ein lokales Modell, das auf 48 GB Unified Memory komfortabel läuft, gutes Tool-Calling beherrscht und für Code-Generierung trainiert ist.

### Entscheidung
**Qwen3-Coder 30B-A3B** in Q4_K_M-Quantisierung als Standardmodell. Fallback bei Tool-Calling-Problemen: **Carnice MOE 35B A3B**.

### Begründung
- MoE-Architektur (30B total, 3.3B aktiv): schnelle Inferenz (~30–35 tok/s auf M4 Pro)
- Speicherbedarf bei Q4_K_M: ~17 GB → reichlich Puffer für KV-Cache, Docker, System
- Speziell für agentische Coding-Workflows trainiert (Long-Horizon RL auf SWE-Bench)
- Natives 256K Context Window (auf 64K beschränkt für Performance)
- Apache 2.0 Lizenz

### Konsequenzen
**Positiv:**
- Schnell genug für sinnvolle nächtliche Iteration
- 31 GB Headroom für Docker/System
- Gute SWE-bench-Performance unter den lokal lauffähigen Modellen

**Negativ:**
- Tool-Calling-Zuverlässigkeit unter Frontier-Niveau (durch TDD-Gates kompensiert, ADR-005)
- Quantisierungs-bedingte gelegentliche Codegenerierungs-Fehler (akzeptiert im PoC-Kontext)

### Verworfene Alternativen
- **Gemma 4 31B Dense:** Höhere benchmarked Coding-Performance laut Hersteller, aber Reports über Tool-Calling-Probleme auf Macs und langsamere Inferenz (Dense-Architektur). Als Sekundär-Option offen.
- **Qwen 3.6 27B:** Stärker auf reiner Benchmark-Performance, aber primär als General-Purpose-Modell trainiert; Qwen3-Coder ist auf den Agent-Use-Case zugeschnitten.
- **Llama 4 Maverick:** Solide, aber schwächeres Tool-Calling-Profil als Qwen3-Coder.
- **Höhere Quantisierungen (Q6_K, Q8_0):** Kein messbarer Qualitätsgewinn für Coding-Tasks, aber deutlich mehr Speicher und langsamere Inferenz. Abgelehnt.

---

## ADR-004: Spec-Kit als Spec-Driven-Development-Framework

### Status
Accepted

### Kontext
Autonome Agenten brauchen klare, dekomponierte Aufgaben mit Erfolgskriterien. Ohne strukturierte Spec driftet der Agent oder produziert nicht-prüfbaren Code.

### Entscheidung
**GitHub Spec-Kit** als Framework für die Spec-Phase.

### Begründung
- Strukturierte Pipeline: `/speckit.specify` → `/speckit.plan` → `/speckit.tasks` → `/speckit.implement`
- Erzwingt Test-First-Vorgehen im generierten Workflow (siehe ADR-005)
- Erzeugt Markdown-Artefakte (`spec.md`, `plan.md`, `tasks.md`), die zwischen Frontier-UI und lokalem Agent portierbar sind
- Constitution-Konzept (`.specify/memory/constitution.md`) erlaubt projekt-spezifische Regeln
- Modell-agnostisch: Slash-Commands sind generische Markdown-Prompts

### Konsequenzen
**Positiv:**
- Klare Trennung Spec-Phase (Frontier) / Implementation-Phase (lokal)
- Eingebaute Quality-Gates (Checkpoint-Validierung pro User Story)
- Eingebaute TDD-Erzwingung

**Negativ:**
- Manueller Schritt: Spec-Output aus Web-UI ins Repo committen
- Lernkurve für die Workflow-Commands

### Verworfene Alternativen
- **Eigenes Prompt-Template ohne Framework:** Funktioniert, aber wir bauen ein gelöstes Problem nach. Abgelehnt.
- **OpenSpec, SDD-Pilot, etc.:** Kleinere Communities, weniger Toolchain-Integration. Vorerst abgelehnt, neu evaluierbar.

---

## ADR-005: TDD-Erzwingung als Erfolgskriterium

### Status
Accepted

### Kontext
Autonome Runs brauchen ein objektives Stopp-Kriterium. Ohne dieses deklariert das Modell irgendwann selbst "fertig", auch wenn nichts funktioniert.

### Entscheidung
Strikte Test-Driven-Development-Erzwingung durch Spec-Kit-Workflow: Tests werden vor Implementierung geschrieben und müssen initial rot sein. "Alle Tests grün" ist das einzige akzeptierte Done-Kriterium.

### Konsequenzen
**Positiv:**
- Objektives, automatisch prüfbares Done-Kriterium
- Lokales Modell kann selbst entscheiden, wann es fertig ist
- Quality-Gate gegen Halluzinations-Code

**Negativ:**
- Gelegentlich "fake green" Tests (Tests existieren, prüfen aber nicht das Richtige) → mitigiert durch manuelles Test-Review am Morgen
- Tests müssen vor Implementation existieren → erhöht initial die Iterationen

### Verworfene Alternativen
- **Time-Boxing als Stopp-Kriterium:** Liefert keine Qualitäts-Garantie.
- **LLM-as-Judge:** Lokales Modell ist nicht zuverlässig genug für Self-Evaluation auf eigenen Code.

---

## ADR-006: Docker-Sandboxing für autonome Runs

### Status
Accepted — **Netzwerkklausel (`--network none`) superseded by ADR-010** (offener Egress). Sandboxing (non-root, Mounts, Limits) bleibt gültig.

### Kontext
Ein autonom laufender Agent mit Shell-Zugriff ist ein Sicherheitsrisiko. Er könnte versehentlich oder durch fehlerhafte Logik wichtige Dateien überschreiben, Secrets exfiltrieren oder schädliche Netzwerk-Calls machen.

### Entscheidung
Alle Agent-Aktivitäten laufen in einem Docker-Container mit folgenden Restriktionen:
- Nur das aktuelle Projekt-Verzeichnis als Read-Write-Mount
- Read-only-Mount für ggf. nötige Referenz-Daten
- Kein Mount von `~/.ssh`, `~/.aws`, `~/.config`, persönlichen `.env`-Dateien außerhalb des Projekts
- Netzwerk-Restriktion: nach initialem `npm install` / `pip install` Wechsel auf `--network none`
- CPU-Limit: 70% der verfügbaren Cores (thermisches Throttling vermeiden)
- Disk-Quota: 5 GB pro Worktree

### Konsequenzen
**Positiv:**
- Kontrollierter Blast-Radius bei Fehlverhalten
- Reproduzierbare Umgebung
- Erfüllt N2 und N3

**Negativ:**
- Zusätzliche Setup-Komplexität
- Geringfügiger Performance-Overhead

### Verworfene Alternativen
- **macOS-natives Sandboxing (`sandbox-exec`):** Weniger gut dokumentiert, weniger Tooling-Support.
- **Kein Sandboxing:** Verletzt N2/N3. Inakzeptabel.

---

## ADR-007: Git-Worktrees + Bash-Orchestrator statt Multi-Agent-Framework

### Status
Accepted

### Kontext
Bei realistisch 40–60% Erfolg pro Einzelversuch brauchen wir Parallelität, um auf zuverlässige Gesamt-Erfolgsraten zu kommen. Multi-Agent-Frameworks (LangGraph, AutoGen, CrewAI) lösen dieses Problem, bringen aber erhebliche Komplexität mit.

### Entscheidung
Drei parallele `git worktree`-Instanzen, jeder mit eigener OpenCode-Session, koordiniert durch ein einfaches Bash-Skript. Keine zusätzliche Multi-Agent-Orchestrierung.

### Begründung
- Worktrees sind ein natives Git-Feature, voll isoliert
- Bash + `wait` reicht für parallele Koordination völlig aus
- Jeder Versuch ist unabhängig debuggbar (eigenes Verzeichnis, eigenes Log)
- Beim Aufräumen morgens: drei Branches im Repo, eine `git worktree remove`-Operation

### Konsequenzen
**Positiv:**
- Transparente, debuggbare Architektur
- Keine Framework-Abhängigkeiten, keine Versions-Drift
- Jeder Versuch komplett isoliert (kein Cross-Contamination)

**Negativ:**
- Keine eingebaute Inter-Agent-Kommunikation (für unseren Use-Case nicht nötig)
- Bash-Skript-Komplexität wächst, wenn wir später erweitern wollen

### Verworfene Alternativen
- **LangGraph / AutoGen:** Lösen ein Problem, das wir nicht haben (Inter-Agent-Coordination).
- **Sequenzielle Versuche statt parallel:** Verschwendet die ohnehin verfügbare Nacht-Zeit.

---

## ADR-008: Pushover (oder Telegram) für Notifications

### Status
Accepted (Pushover als Default, Telegram als Alternative)

### Kontext
Morgens will ich auf einen Blick sehen, was die Nacht produziert hat – ohne erst den Laptop hochzuklappen.

### Entscheidung
Einfacher `curl`-Call aus dem Orchestrator-Skript am Ende jedes Runs. Default-Provider: Pushover (One-Time-Fee, simpel). Alternative: Telegram-Bot.

### Konsequenzen
**Positiv:**
- Minimale Abhängigkeit, ein Shell-Befehl
- Kein zusätzlicher Agent / Daemon nötig

**Negativ:**
- Pushover kostet einmalig ~5 € (einmalig, nicht recurring)

### Verworfene Alternativen
- **macOS Notifications:** Funktionieren nur am Gerät selbst, nicht mobil.
- **Email:** Mehr Aufwand, mehr Spam-Risiko.
- **Hermes-Gateway:** Würde Hermes-Layer rechtfertigen, der laut ADR-002 zu schwer ist.

---

> **Nachtrag 2026-05-21 (v2).** ADRs 009–014 ergänzen/korrigieren den Stand vom 18.05. nach geänderten Anforderungen: Eskalation explizit auf Ollama Cloud, Internetzugriff in der Sandbox erlaubt (kehrt N3 / ADR-006-Netzwerkklausel um), optionale Planner/Reviewer-Schicht, Budget-Modell, sowie eine Tooling-Korrektur (`opencode --max-turns` existiert nicht). Konkrete Umsetzung im `scaffold/` und in `05-orchestrator.md`.

---

## ADR-009: Cloud-Eskalation via Ollama Cloud

### Status
Accepted (2026-05-21; formalisiert den Vorschlag aus `04-escalation.md`)

### Kontext
Lokale Modelle scheitern in ~25 % der Nächte bei kleineren MVPs (5–7 Dateien) auch über drei parallele Versuche. Diese Nächte sollen automatisch gerettet werden, ohne den Architekturstil aus ADR-002/003 zu verlassen.

### Entscheidung
Nach Scheitern aller lokalen Versuche startet der Orchestrator budget-gated (ADR-012) einen weiteren Versuch mit einem größeren Open-Weight-Modell via **Ollama Cloud** (`:cloud`/`-cloud`-Tag). Gleicher OpenAI-kompatibler Endpoint, gleicher OpenCode-Code-Pfad, nur anderer Modellname. Eskalation auf Frontier-APIs (Claude/GPT) bleibt bewusst **nicht** Standard.

### Konsequenzen
**Positiv:** strukturell minimaler Eingriff (eine Verzweigung im Orchestrator); keine Frontier-API-Kosten als Default; Open-Weight bleibt Standard, Datenfluss bleibt vergleichbar transparent.
**Negativ:** zusätzliche Auth (`OLLAMA_API_KEY`); Ollama-Cloud-Verfügbarkeit ist eine neue externe Abhängigkeit; Cloud-Modell-Katalog bewegt sich (Mai 2026: `qwen3-coder-next`, `glm-5.1`, `kimi-k2.6`, `deepseek-v4-pro/flash` statt der älteren `gpt-oss`/`qwen3-coder:480b`-Namen) → Tags am Setup-Tag verifizieren.

### Verworfene Alternativen
- **Frontier-API als Default-Eskalation:** höhere Erfolgswahrscheinlichkeit, aber Bruch mit ADR-002 und höhere Kosten. Bleibt als optionale zweite Stufe offen.
- **Sequenzielle lokale Re-Tries mit anderem lokalen Modell:** wenn das primäre lokale Modell strukturell versagt, schafft es ein anderes 30B-Modell meist auch nicht.

---

## ADR-010: Offener Internet-Egress in der Sandbox (supersedes Netzwerkklausel ADR-006 / N3)

### Status
Accepted (2026-05-21) — **supersedes** die `--network none`-Klausel aus ADR-006 und N3 aus dem Brief.

### Kontext
Der frühere Brief verbot Netzwerkzugriff nach dem Initial-Install (N3). Realität: der Worker braucht **aktuelle** Doku (APIs ändern sich, Trainingswissen veraltet), und genau das war als harte Anforderung gewünscht — der Agent *soll* Doku ziehen, und zwar immer. Eine reine No-Network-Sandbox verhindert das.

### Entscheidung
Die Sandbox hat **offenen Egress**. `webfetch` im OpenCode-Profil steht auf `allow` (statt `ask`), native Web-Suche (Exa) ist via `OPENCODE_ENABLE_EXA=true` aktiv. Sicherheit kommt **nicht** mehr aus Netzwerk-Abschottung, sondern aus einem verschobenen Threat-Model:
- non-root Container-User, **einzige** beschreibbare Host-Bind-Mount ist der Worktree
- **keine** Mounts von `~/.ssh`, `~/.aws`, `~/.config`, persönlichen `.env` → nichts Wertvolles zum Exfiltrieren erreichbar
- Secrets-Read-Deny im Profil; `read`-deny-Globs auf `.env`/`*.pem`/`id_rsa*`
- Egress-**Audit-Log** jeder `webfetch`-URL (`autonomous-guards.ts`)
- gefetchte Inhalte gelten als **Daten, nicht Instruktionen** (Prompt-Injection-Schutz in AGENTS.md + `security-auditor`)

### Konsequenzen
**Positiv:** Worker arbeitet mit aktueller Doku; deutlich höhere Trefferquote bei jungen Libraries; erfüllt die explizite Anforderung.
**Negativ:** Exfiltrations- und Prompt-Injection-Oberfläche steigt. Mitigiert (nicht eliminiert) durch „nichts Wertvolles gemountet" + Audit-Log + read-deny. Bewusst akzeptiertes Restrisiko im PoC-Kontext.

### Verworfene Alternativen
- **Egress-Allowlist via Proxy** (nur Docs + Registries + Ollama Cloud): sicherer, aber Pflegelast und bricht „der Agent soll *immer* ziehen können". Bewusst zugunsten Einfachheit verworfen — als Härtungs-Option dokumentiert, falls je sensible Daten in einen PoC geraten.
- **No-Network (Status quo ante):** widerspricht der Kern-Anforderung. Abgelehnt.

---

## ADR-011: Optionale Planner/Reviewer-Schicht auf günstigem Open-Weight-Cloud-Modell

### Status
Accepted (2026-05-21) — **default off**, per Flag aktivierbar.

### Kontext
Plan-Dekomposition und unabhängiges Review sind reasoning-lastig — genau dort sind lokale 30B-Modelle am schwächsten, während die Token-intensive Implementierung lokal gut genug läuft. Idee: kognitive Last auf ein stärkeres (aber günstiges) Cloud-Open-Weight verschieben, Implementierung lokal lassen.

### Entscheidung
Ein Overlay-Profil (`opencode-autonomous-planreview.json`) mappt `plan` + `reviewer` + `security-auditor` auf ein günstiges Cloud-Modell (Default `gpt-oss:20b-cloud`), `build` (Worker) bleibt lokal. Aktivierung über `PLANNER_REVIEWER=on`; der Orchestrator setzt dann dieses Profil als `OPENCODE_CONFIG`. Default ist **off** (alles lokal), bis empirisch gezeigt ist, dass die Schicht den Cloud-Verbrauch wert ist.

### Konsequenzen
**Positiv:** bessere Pläne/Reviews ohne den Worker-Token-Strom in die Cloud zu schieben; ein Schalter, kein Architektur-Umbau.
**Negativ:** jeder Plan-/Review-Call zählt aufs Cloud-Budget (ADR-012); zwei Profile synchron zu halten (OpenCode kennt kein `$extends`).

### Verworfene Alternativen
- **Planner/Reviewer immer an:** verbrennt Budget auch dort, wo lokal gereicht hätte.
- **Frontier-Modell als Planner:** stärker, aber Kosten + Bruch mit der Open-Weight-Linie.

---

## ADR-012: Budget als selbst gesetztes Eskalations-Kontingent (kein Euro-Meter)

### Status
Accepted (2026-05-21)

### Kontext
„Bis das Ollama-Cloud-Budget aufgebraucht ist" braucht einen messbaren Stopp. Stand Mai 2026 ist Ollama Cloud **subscription-basiert** (Free/$0, Pro $20, Max $100) mit Session-Limits (Reset alle 5 h) + Weekly-Limits — ein per-Token/€-Meter ist angekündigt, aber **nicht GA** ([ollama.com/pricing](https://ollama.com/pricing)).

### Entscheidung
Budget = lokal geführtes **Kontingent an Cloud-Eskalationen** (jq-Ledger, `MAX_CLOUD_PER_DAY` / `MAX_CLOUD_PER_WEEK`). Jede Eskalation wird verbucht; vor jeder weiteren prüft `budget_can_escalate`. Kein €-Betrag, solange Ollama nicht metered abrechnet. Sobald metered GA ist: zusätzlich `opencode stats` gegen ein €-Cap (TODO in `budget.sh`).

### Konsequenzen
**Positiv:** harte, deterministische Obergrenze ohne externe Abhängigkeit; passt zum Subscription-Modell.
**Negativ:** Kontingent ≠ exakte GPU-Kosten; grobe Näherung. Bei metered Pricing nachzuschärfen.

### Verworfene Alternativen
- **€-Cap via API-Kostenabfrage:** mangels metered Pricing nicht möglich.
- **Kein Cap, nur Plan-Limits:** Plan-Limit-Reset (5 h) ist intransparent als Stopp-Signal; eigenes Ledger ist nachvollziehbarer.

---

## ADR-013: Iterations-Bounding ohne `--max-turns` (timeout + äußere Loop + Budget)

### Status
Accepted (2026-05-21) — **Korrektur** zu `03-setup-manual.md`/`04-escalation.md`.

### Kontext
Frühere Drafts setzten `opencode run --max-turns 20` voraus. Dieses Flag **existiert nicht** in der OpenCode-CLI (verifiziert gegen [opencode.ai/docs/cli](https://opencode.ai/docs/cli/), Stand 2026-05-21). Der Run braucht trotzdem harte Grenzen, sonst läuft ein Modell im Kreis bis morgens.

### Entscheidung
Dreifaches Bounding statt eines CLI-Flags:
1. **Pro Versuch:** OS-`timeout` um `opencode run` (Wall-Clock, `ATTEMPT_TIMEOUT`).
2. **Versuchszahl:** äußere Orchestrator-Loop (N parallele lokale + benannte Cloud-Eskalationen), nicht unbegrenzt.
3. **Cloud-Verbrauch:** Budget-Kontingent (ADR-012).
Autonomie-Schalter ist `--dangerously-skip-permissions` (kein Mensch beantwortet „ask"); die `permissions.deny`-Liste + das Plugin sind dann das eigentliche Gate.

### Konsequenzen
**Positiv:** robust gegen Endlos-Loops; unabhängig von CLI-Flag-Drift.
**Negativ:** `timeout` schneidet ggf. mitten in einer Iteration ab → der Verify-Schritt fängt das ab (kein `.green` → gilt als Fehlversuch).

### Verworfene Alternativen
- **Auf ein künftiges `--max-turns` warten:** spekulativ.
- **`OPENCODE_EXPERIMENTAL_OUTPUT_TOKEN_MAX` als einziges Limit:** begrenzt Output-Token pro Antwort, nicht die Gesamtdauer/Iterationen.

---

## ADR-014: Spec-Framework — Spec-Kit für Greenfield, Lite-Spec für Mini-PoCs

### Status
Accepted (2026-05-21) — präzisiert ADR-004.

### Kontext
Der Agent baut **Greenfield**-PoCs/MVPs. Die projekteigene SDD-Analyse (`Spec Driven Development/SDD - Tool-Empfehlungen.md`) ordnet Greenfield klar **Spec-Kit** zu, OpenSpec dem Brownfield. Gleichzeitig warnt dieselbe Quelle (Hashrocket, 2026): Spec-Kit ist für *kleine* Prototypen Overkill (~800-Zeilen-Kaskade vs. ~250 bei OpenSpec).

### Entscheidung
**Gestuft:** voller Spec-Kit-Flow (`constitution → specify → clarify → plan → tasks → implement`) ab mittlerem MVP (≈4+ Dateien, Architektur-Sorgfalt nötig). Für 1–3-Datei-PoCs eine **Lite-Spec** (`templates/spec.lite.md`: Ziel, Constraints, funktionale Anforderungen, test-bare Akzeptanzkriterien, Out-of-Scope, I/O-Beispiel) — genug Struktur gegen Drift, ohne Kaskaden-Overhead. OpenSpec bleibt dem Brownfield-Alltag vorbehalten (nicht Sache dieses autonomen Greenfield-Agenten).

### Konsequenzen
**Positiv:** Spec-Aufwand skaliert mit Projektgröße; kein 800-Zeilen-Dokument für einen 2-Datei-PoC.
**Negativ:** Schwellen-Entscheidung „lite vs. voll" liegt beim Menschen — bewusst, da du die Spec ohnehin schreibst.

### Verworfene Alternativen
- **Immer voller Spec-Kit-Flow:** Overhead > Nutzen bei Mini-PoCs (Quelle: Hashrocket/Spec-Kit-Discussion #1536).
- **Immer nur Lite-Spec:** zu wenig Architektur-Sorgfalt für mittlere MVPs.
- **OpenSpec als Default:** brownfield-optimiert, passt nicht zum Greenfield-Kern dieses Agenten.
