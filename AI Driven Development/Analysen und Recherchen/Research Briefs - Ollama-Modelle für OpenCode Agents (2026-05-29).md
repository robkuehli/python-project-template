---
title: "Research Briefs — Ollama-Modelle für OpenCode-Agents (lokal + Cloud)"
created: 2026-05-29
purpose: Kopierfertige Deep-Research-Aufträge für Modellauswahl pro Agent-Rolle
target_engines:
  - Claude Deep Research
  - OpenAI Deep Research (o-Series)
  - Perplexity Deep Research
tags:
  - research-brief
  - opencode
  - ollama
  - subagent-driven-development
---

# Research Briefs — Ollama-Modelle für OpenCode-Agents

Zwei voneinander unabhängige Deep-Research-Aufträge. Beide sind so geschrieben, dass sie ohne meinen Vorab-Kontext funktionieren — wenn du sie an eine Deep-Research-Engine gibst, soll das Ergebnis direkt in die OpenCode-Profil-Configs einfließen können.

**Wie nutzen:**

1. Wähle einen Brief (lokal oder cloud), kopiere den **gesamten Block** (zwischen den `---START---` / `---END---`-Markern).
2. In Claude Deep Research bzw. dem o-Series-Pendant als Initial-Prompt einfügen.
3. Folge-Frage anhängen falls nötig: *„Konzentriere dich bei Bedarfskonflikten auf Python/SQL/dbt/Docker/K8s als Stack."*
4. Ergebnisse in [[Review - Workflow-Refactoring (2026-05-29)]] §7 zurückfließen lassen.

**Was die Briefs gemeinsam haben:**

- Sie definieren die OpenCode-Agent-Rollen aus meinem Workflow als Selektionsschablonen.
- Sie verlangen pro Rolle eine Top-3-Empfehlung mit Pro/Contra und Quellen.
- Sie schließen Modelle aus, die nicht über Ollama bezogen werden können.
- Sie geben Maturity-Labels (✅/🧪/💡) als Pflicht-Output vor.

---

## Brief 1 — Lokale Modelle (M4 Pro 48 GB)

Für das `local`-Profil von OpenCode. Komplett offline-fähig, keine Cloud-Calls jeglicher Art.

```
---START---
# Deep-Research-Auftrag: Lokale Ollama-Modelle für agentic SWE-Workflow auf M4 Pro 48 GB

## Kontext

Ich bin Software-Engineer (Data Engineering, Data Science, AI Engineering) und betreibe
einen agentic Software-Engineering-Workflow auf Basis von OpenCode (https://opencode.ai).
OpenCode ist ein TUI-basiertes agentic CLI mit Provider-agnostischer Konfiguration —
ähnlich zu Claude Code, aber Open Source.

Mein Workflow folgt dem Subagent-Driven-Development-Pattern (siehe
https://github.com/obra/superpowers/blob/main/skills/subagent-driven-development/SKILL.md):
ein Primary Agent plant, dispatched fresh Subagents pro atomarer Task, Two-Stage Review
(Spec-Compliance → Code Quality), synthetisiert am Ende.

Stack: Python, SQL, dbt, Docker, Kubernetes, Bash, Makefile. Hauptmotive sind Pipelines,
RAG-Systeme, LLM-Evals und Datenmodellierung.

## Ziel

Empfiehl mir pro OpenCode-Agent-Rolle die TOP 3 lokalen Modelle (Ollama Library, https://ollama.com/library),
die auf einem MacBook Pro M4 Pro 48 GB unified memory laufen. Realistisches Budget für
Modelle: ~32 GB (16 GB für OS + Tools + parallele Subagent-Instanzen reservieren).

## Harte Constraints

1. Modell MUSS via `ollama pull <name>` verfügbar sein (offizielle Ollama Library oder
   bekanntes Community-Mirror mit nachweislich stabilen Tool-Calls).
2. Q4_K_M-Quantisierung (oder besser) MUSS auf 48 GB unified memory laufen, inkl.
   ausreichend Headroom für gleichzeitig laufenden 3B small_model und OS.
3. Tool Calling (Function Calling, OpenAI-Format) MUSS in der Ollama-Implementierung
   stabil funktionieren — nicht nur in der Referenz-Implementierung (vLLM/SGLang).
   Verifiziere über aktuelle Ollama-Issues und Community-Berichte.
4. Lizenz: kommerzielle Nutzung erlaubt, idealerweise MIT/Apache/permissive. Keine
   restriktiven Custom-Lizenzen mit User-Count-Limits.
5. Modell-Release oder letztes Major-Update innerhalb der letzten 6 Monate (Stand: Mai 2026).

## Sechs Agent-Rollen mit Anforderungen

### 1. `build` (Primary, Coder)

Implementiert nach freigegebener Spec. Macht die meiste Arbeit der Session.

- Anforderungen: starkes Tool-Use (Read, Write, Edit, Bash, Grep, Glob jeweils mehrfach
  pro Turn), Iterative TDD-Loops (Test schreiben → Code schreiben → Test laufen lassen
  → reagieren), Diff-aware Editing über mehrere Files, lange Trajectories (mehrere
  Stunden Session-Länge).
- Wichtig: SWE-bench Verified / SWE-rebench-Score, Stabilität in agentic Loops
  (nicht nur Single-Turn-Coding), Output ohne übermäßigen Chain-of-Thought-Lärm.
- Anti-Pattern: Modelle die Tool-Calls halluzinieren oder Parameter-Schema droppen.

### 2. `plan` (Primary, Architect)

Schreibt Specs, Pläne, Architekturentscheidungen, Reviews. Hauptsächlich Reasoning,
weniger Tool-Use.

- Anforderungen: structured output (Markdown mit klaren Headings, Trade-off-Listen),
  Multi-Constraint-Reasoning (gleichzeitig auf Spec, Constraints, Risks denken), längere
  Antworten ohne Qualitätsabfall.
- Wichtig: Reasoning-Benchmark-Performance (z.B. GPQA, ARC, oder ein Coding-Reasoning-Benchmark
  wie LiveCodeBench), nicht primär SWE-bench.
- Optional: explizites Thinking/Reasoning-Modus (à la Claude/o-Series), falls verfügbar.

### 3. `researcher` (Subagent, Explorer)

Read-only Codebase-Recon. Kontext-isoliert, gibt nur strukturierte Summary zurück.

- Anforderungen: HOHE Token-Throughput-Geschwindigkeit (schnell Files lesen,
  Patterns erkennen), niedriger Footprint (parallel zu `build` aktiv, also unter
  ~12 GB), zuverlässiges Grep/Glob-Tool-Use, präzise Output-Formatierung.
- Wichtig: Tokens/sec auf Apple Silicon (MLX-Backend bevorzugt), Context Window ≥32K.
- Modell-Tier kann deutlich unter `build` liegen — Recon braucht kein Frontier-Reasoning.
- Anti-Pattern: Modelle die bei längeren Listings den Faden verlieren.

### 4. `reviewer` (Subagent, Code-Review gegen Spec)

Read-only Diff-Review. Bekommt Spec + Diff, gibt Verdict (ship / fix / rework).

- Anforderungen: Logikfehler-Erkennung im Diff-Kontext, Verständnis von „Spec sagt X,
  Code macht Y", Bewusstsein für stilistische Conventions (aus AGENTS.md).
- Wichtig: möglichst ANDERES Modell-Familien als `build` (Diversity reduziert blind spots
  — wenn build z.B. Qwen ist, sollte reviewer aus einer anderen Modellfamilie kommen).
- Modell-Tier mittel — Reasoning notwendig, aber keine Frontier-Größe.

### 5. `security-auditor` (Subagent, Security-Pass)

Read-only. Sucht Secrets im Code, Injection-Pfade, AuthZ-Misconfigurations,
fehlerhafte Permission-Checks, race conditions in async/concurrent code.

- Anforderungen: Pattern-Erkennung über mehrere Files, Wissen über klassische CVEs und
  Anti-Patterns (SQL Injection, Path Traversal, SSRF, Insecure Deserialization),
  Reasoning > Code-Generation.
- Wichtig: Trainings-Datum nach 2024 (CVE-Wissen muss aktuell sein), strukturierte
  Findings (Severity, Location, Recommendation).

### 6. `small_model` (OpenCode-intern)

Title-Generierung, Klassifikation, andere triviale Aufrufe.

- Anforderungen: Sub-Sekunde Latenz, Sub-2-GB-Footprint, Tool-Call optional.
- Hier zählt einzig „läuft schnell und stabil im Hintergrund".

## Evaluations-Dimensionen pro Modell

Liefere für jeden Top-3-Kandidaten:

| Dimension | Was du recherchieren sollst |
|---|---|
| Größe (params total / active) | Bei MoE beide angeben |
| Footprint Q4_K_M (GB) | Konkrete GGUF/MLX-Größe von Hugging Face oder Ollama |
| Tokens/sec auf M4 Pro | Aus Community-Benchmarks (LocalLLaMA, Unsloth, Ollama Discord) |
| Context Window | Native (nicht extrapoliert) |
| Tool-Use-Stabilität in Ollama | Konkrete Issue-/Bericht-Verweise, nicht „sollte funktionieren" |
| SWE-bench Verified % | Mit Quelle und Datum |
| SWE-rebench Score | Falls verfügbar |
| Lizenz | Exakter Name + URL |
| Letztes Update | Datum |
| Maturity | ✅ Established / 🧪 Emerging / 💡 Experimental |

## Speziell prüfen

- **Qwen3-Coder-Next** (80B MoE, 3B active) — gilt aktuell als der einzige
  „Frontier-Klasse"-Coder, der auf 48 GB lokal läuft. Verifiziere ob das Stand
  jetzt noch zutrifft, oder ob neuere kleinere Modelle (z.B. eine kleinere
  GLM-/Kimi-Variante) das verdrängt haben.
- **gpt-oss:20b** als plan/reviewer/security-Modell — verifiziere die Tool-Use-Reife
  und ob es nicht überholt wurde.
- **Apple-MLX-Builds** (z.B. via `mlx-community` auf Hugging Face) vs. GGUF-via-Ollama —
  prüfe ob es signifikante Performance-Unterschiede gibt, die einen MLX-only-Workflow
  rechtfertigen würden (Ollama unterstützt MLX inzwischen nativ).
- **Llama 3.2 / 3.3** vs. **Llama 4** als small_model — was ist aktuell der beste
  Sub-2-GB-Tool-User?

## Quellen-Priorität (hoch → niedrig)

1. Offizielle Modell-Karten auf Hugging Face (`mlx-community`, `unsloth`, Hersteller-Org)
2. Ollama-Library-Einträge mit aktuellen Tags (`ollama.com/library/<name>`)
3. SWE-rebench Leaderboard (swe-rebench.com), Aider Polyglot Leaderboard,
   LiveCodeBench, Terminal-Bench
4. Unsloth-Tutorials (https://docs.unsloth.ai) — sehr verlässliche Quantisierungs-
   und Hardware-Daten
5. localaimaster.com, InsiderLLM, Morph LLM Reviews (mit Datum prüfen)
6. r/LocalLLaMA Posts der letzten 90 Tage mit nachvollziehbarer Benchmark-Methodik

## Aktiv meiden

- Generische „Top 10 LLMs 2026"-Listen ohne Benchmark-Methodik
- Medium-Artikel ohne Erscheinungsdatum
- Marketing-Posts der Modell-Hersteller ohne unabhängige Bestätigung
- Tutorials zur reinen Chat-Nutzung (irrelevant für Agentic Tool-Use)

## Output-Format

Pro Agent-Rolle (1–6) liefere:

1. **Empfehlung Top 1** (✅) — Modellname, Footprint, Begründung in 3 Sätzen, Quellen.
2. **Alternative Top 2** (✅/🧪) — wie oben, Begründung wann statt Top 1 zu nutzen.
3. **Watch-list Top 3** (🧪/💡) — wie oben, was die Reife noch hochziehen muss.

Am Ende eine **Empfehlungs-Matrix** als Markdown-Tabelle mit Zeilen=Rollen,
Spalten=Top1/Top2/Top3, sodass ich sie direkt in eine `opencode.json`
mit `agent.<name>.model = "ollama/<name>"` übersetzen kann.

Plus ein kurzer Abschnitt **„Was ich nicht empfehle und warum"** mit den 3–5
populärsten Falschempfehlungen für mein Setup (z.B. Modelle die SWE-bench-stark sind,
aber lokal nicht laufen oder in Ollama instabiles Tool-Use haben).

## Aktualität

Stand: Mai 2026. Wenn du Material von vor Februar 2026 zitierst, markiere es
explizit als „possibly outdated, verify". Wenn ein neuer Release in den letzten
30 Tagen erfolgt ist, der die Empfehlung verändern würde, weise explizit darauf hin.
---END---
```

---

## Brief 2 v1 (archiviert 2026-06-02) — Cloud-Modelle (Ollama Cloud)

> ⚠️ **Archiviert.** v1 hat zu BWL-Drift geführt (TCO-Vergleiche, Hardware-Self-Hosting, Enterprise-Strategie) statt zu rollen-spezifischen Modell-Pins. Lessons Learned: harte Anti-Scope-Regeln und ausgefüllte Output-Schablone fehlten. Siehe **Brief 2 v2** unten — der ist der aktive Brief. v1 bleibt zur Nachvollziehbarkeit hier stehen.

Für das `cloud+local`-Profil von OpenCode. Open-Weight-Modelle via Ollama Cloud (Pro/Max-Plan), keine proprietären Anbieter — die deckt mein Claude-Code- und Codex-CLI-Setup separat ab.

```
---START---
# Deep-Research-Auftrag: Ollama-Cloud-Modelle für agentic SWE-Workflow

## Kontext

Ich bin Software-Engineer (Data Engineering, Data Science, AI Engineering) und betreibe
einen agentic Software-Engineering-Workflow auf Basis von OpenCode (https://opencode.ai).

Für mein `cloud+local`-Profil suche ich die besten Open-Weight-Modelle, die ich über
Ollama Cloud (https://ollama.com/blog/cloud-models) beziehen kann — also via lokalem
Ollama-Daemon mit `:cloud`-Suffix gegen die Cloud-GPUs von Ollama.

WARUM Open-Weight via Ollama Cloud und nicht proprietäre Anbieter: Ich nutze parallel
Claude Code (Anthropic-Modelle via LiteLLM) und Codex CLI (OpenAI-Modelle via LiteLLM)
für die proprietären Stacks. OpenCode ist mein „Open-Weight-Lane" — Vendor-Frei,
unabhängig von Anthropic/OpenAI-Roadmaps, plus die Option, bei API-Outages weiterarbeiten
zu können.

Mein Workflow folgt dem Subagent-Driven-Development-Pattern (siehe
https://github.com/obra/superpowers/blob/main/skills/subagent-driven-development/SKILL.md):
Primary Agent plant, dispatched fresh Subagents pro Task, Two-Stage Review.

Stack: Python, SQL, dbt, Docker, Kubernetes, Bash, Makefile. Hauptmotive: Pipelines,
RAG-Systeme, LLM-Evals, Datenmodellierung.

## Ziel

Empfiehl mir pro OpenCode-Agent-Rolle die TOP 3 Modelle aus dem Ollama-Cloud-Katalog
(https://ollama.com/search?c=cloud), inkl. einer Begründung, warum welches Modell
welcher Rolle am besten passt.

Berücksichtige bei der Auswahl die **drei Ollama-Cloud-Pläne** (Free / Pro 20$/Monat
/ Max 100$/Monat — Stand Mai 2026, https://note.com/zephel01/n/n250a7ecd880c?hl=en-US),
die unterschiedliche GPU-Time-Budgets haben. Gehe von Pro aus, kommentiere wo Max sich
lohnen würde.

## Harte Constraints

1. Modell MUSS im Ollama-Cloud-Katalog gelistet sein (verifiziere auf
   https://ollama.com/search?c=cloud zum Recherche-Zeitpunkt).
2. Aufrufbar via `ollama/<name>:cloud` als OpenAI-kompatibles Endpoint
   (das nutzt OpenCode via Provider-Block).
3. Tool Calling (Function Calling, OpenAI-Format) muss im Ollama-Cloud-Wrapper
   STABIL sein — nicht nur auf vLLM/SGLang in der Referenz-Implementierung.
   Prüfe Issues und Community-Berichte.
4. Lizenz: kommerzielle Nutzung erlaubt (für mich ggf. auch in Kundenprojekten,
   solange Daten nicht in DSGVO-relevant fallen — DSGVO-Pfad läuft separat
   über Anthropic via Bedrock EU).
5. Release/Update der letzten 6 Monate.

## Sechs Agent-Rollen mit Anforderungen

### 1. `build` (Primary, Coder)

Implementiert nach freigegebener Spec. Trägt die meiste Last.

- Anforderungen: starkes Tool-Use, iterative TDD-Loops, Diff-aware Editing,
  Mehrstunden-Trajectories OHNE „goldfish memory" (vergisst frühere
  Plan-Entscheidungen mitten in der Implementierung).
- Wichtig: SWE-bench Verified / SWE-rebench / Aider Polyglot, Stabilität in
  agentic Loops, GPU-Time-Footprint pro Trajectory (Cloud-Kosten).
- Bevorzugt: Modelle die als „agentic coding optimized" trainiert wurden
  (nicht nur generelle Code-Models).

### 2. `plan` (Primary, Architect)

Specs, Pläne, Architekturentscheidungen, Trade-off-Analyse.

- Anforderungen: starkes Reasoning, structured output, lange Kontext-
  Verarbeitung (bei großen Codebases mit vielen relevanten Files), Multi-
  Constraint-Reasoning.
- Wichtig: Reasoning-Benchmarks (GPQA Diamond, MMLU-Pro, ARC-AGI), Long-
  Context-Performance (1M-Token-fähige Modelle wie DeepSeek V4 berücksichtigen),
  Native Thinking/Reasoning-Modus (wo verfügbar).
- DIVERSITY: muss sich von `build`-Modell unterscheiden — wenn build z.B.
  Qwen-Familie ist, soll plan aus einer anderen Familie kommen.

### 3. `researcher` (Subagent, Explorer)

Read-only Codebase-Recon, kontext-isoliert.

- Anforderungen: HOHE Token-Throughput-Geschwindigkeit, präzise Pattern-Detection,
  geringe Cloud-Kosten pro Aufruf (häufig aufgerufen).
- Wichtig: Latenz (Time-to-First-Token), Tokens/sec, Cost-per-Recon-Run.
- HINWEIS: In meinem cloud+local-Profil läuft researcher BEWUSST lokal
  (Qwen3-Coder:30b oder kleiner), weil Recon read-heavy ist und Cloud-Roundtrips
  den Speed-Vorteil kosten. Falls du allerdings ein Cloud-Modell findest, das
  signifikant besser ist (z.B. ein 8B-Modell mit Sonnet-Level Recon-Qualität),
  zeig mir das als Alternative.

### 4. `reviewer` (Subagent, Code-Review gegen Spec)

Read-only Diff-Review.

- Anforderungen: Logikfehler-Erkennung, Spec-Compliance-Bewertung, Style-
  Conventions-Bewusstsein.
- Wichtig: muss aus ANDERER Modellfamilie als `build` und idealerweise als `plan`
  kommen (Diversity → erkennt blind spots beider).
- Mid-Tier Modell ausreichend.

### 5. `security-auditor` (Subagent, Security-Pass)

Read-only. Sucht Secrets, Injection-Pfade, AuthZ-Misconfigs, race conditions.

- Anforderungen: Pattern-Erkennung über mehrere Files, aktuelles CVE-Wissen
  (Trainings-Datum > 2024), strukturierte Findings.
- Wichtig: Reasoning-Tier > Code-Generation-Tier; Modelle die in
  Security-Audit-Benchmarks bewertet wurden (z.B. CyberSecEval) bevorzugt.

### 6. `small_model` (OpenCode-intern)

Bleibt im cloud+local-Profil LOKAL (llama3.2:3b o.ä.), nicht cloud-basiert —
Triviales soll nicht in die Cloud routen. Diese Rolle kann in deinem Output
übersprungen werden, mit einer Notiz.

## Evaluations-Dimensionen pro Modell

Liefere für jeden Top-3-Kandidaten:

| Dimension | Was du recherchieren sollst |
|---|---|
| Modellfamilie + Größe (params total / active) | Bei MoE beide |
| Lizenz | Exakter Name + URL |
| Trainings-Cutoff | Wichtig für CVE-/Library-Wissen |
| SWE-bench Verified % | Mit Quelle + Datum |
| SWE-rebench Score | Falls verfügbar |
| Aider Polyglot / LiveCodeBench | Falls verfügbar |
| Tool-Use-Stabilität in Ollama Cloud | Konkrete Berichte, nicht „sollte" |
| Context Window | Native, nicht extrapoliert |
| Reasoning-Modus | Ja / Nein / Optional |
| Cost-Tier auf Ollama Cloud | Free-tier nutzbar? Pro? Max? |
| Letztes Update | Datum |
| Maturity | ✅ Established / 🧪 Emerging / 💡 Experimental |

## Speziell prüfen

- **MiniMax M2.5 / M2.7** — gilt als bestes Open-Weight auf SWE-bench Verified
  (80.2%). Verifiziere ob Tool-Use über Ollama Cloud mittlerweile stabil ist
  (war im April 2026 noch unreif). Wenn ja: ist es ein guter `build`-Kandidat?
- **GLM-5.1** (Zhipu AI) — 77.8% SWE-bench, SWE-Bench-Pro Leader. Prüfe das
  XML-Envelope-Tool-Calling-Problem in Ollama (war bei GLM-4.6 ein Issue).
- **Kimi K2.6** (Moonshot AI) — MIT-Lizenz, 1T params, native multimodal,
  „swarm-style task orchestration". Spannender Plan-Kandidat?
- **DeepSeek V4 Pro / Flash** — 1M Context Window, sehr effiziente Inference.
  Spannend für `plan` bei großen Codebases?
- **Qwen3-Coder-Next** in Cloud-Variante (`:cloud`) — wenn ich es lokal nutze,
  kann die Cloud-Variante derselbe Pin sein? Welcher Mehrwert?
- **gpt-oss:120b-cloud** — wie steht das aktuell gegen die o.g. neueren Modelle?
- **Hybrid-Empfehlung:** Welche KOMBINATION aus build/plan/reviewer maximiert
  Diversity (verschiedene Trainings-Lineages)? Beispielsweise build=MiniMax,
  plan=Kimi, reviewer=GLM — ist diese Diversity in der Praxis ein meßbarer
  Vorteil oder nur Theorie?

## Quellen-Priorität (hoch → niedrig)

1. Ollama-Cloud-Modell-Liste mit Stand-Datum (https://ollama.com/search?c=cloud)
2. Ollama-Blog-Posts pro Modell (https://ollama.com/blog/<model>)
3. Offizielle Modell-Karten der Hersteller (MiniMax, Zhipu, Moonshot, DeepSeek,
   Alibaba/Qwen)
4. SWE-rebench (swe-rebench.com), SWE-bench Verified Leaderboard,
   Aider Polyglot Leaderboard
5. Unabhängige Reviews mit reproduzierbaren Benchmarks
6. r/LocalLLaMA und Hacker News-Threads der letzten 90 Tage

## Aktiv meiden

- Generische „Best 2026 LLMs"-Listen
- Proprietäre Modelle (Claude, GPT, Gemini) — gehören in mein anderes Profil
- Modelle die nur theoretisch über Ollama Cloud verfügbar wären, aber nicht
  im aktuellen Katalog gelistet sind
- Benchmark-Claims der Hersteller ohne unabhängige Bestätigung

## Output-Format

Pro Agent-Rolle (1–5, kein 6) liefere:

1. **Empfehlung Top 1** (✅) — Modellname `<provider>/<modell>:cloud`, Begründung
   in 3 Sätzen, Cost-Tier (Pro/Max), Quellen.
2. **Alternative Top 2** (✅/🧪) — wann statt Top 1.
3. **Watch-list Top 3** (🧪/💡) — was die Reife noch hochziehen muss.

Am Ende:

1. **Empfehlungs-Matrix** (Markdown-Tabelle, Zeilen=Rollen, Spalten=Top1/Top2/Top3),
   übersetzbar in `agent.<name>.model = "ollama/<name>:cloud"`.
2. **Diversity-Bewertung** der Top-1-Kombination: laufen build/plan/reviewer/
   security-auditor auf unterschiedlichen Trainings-Lineages? (Wichtig für
   reviewer-Subagent-Effektivität.)
3. **Cost-Estimate**: Bei „typischer Coding-Session" (2h, 5 atomare Tasks,
   je 1× build / 2× researcher / 1× reviewer / 1× security-auditor) — welcher
   Ollama-Cloud-Plan reicht? Wie viele Sessions/Tag bei Pro vs Max?
4. **Was ich nicht empfehle und warum** — 3–5 populäre Fehlempfehlungen mit
   Begründung (z.B. „Modell X ist auf SWE-bench stark, hat aber XML-Envelope-
   Tool-Calls, die in Ollama-Cloud aktuell nicht sauber parsen — verifiziert
   in Issue Y.")

## Aktualität

Stand: Mai 2026. Material vor Februar 2026 als „possibly outdated" markieren.
Wenn neuer Release in den letzten 30 Tagen die Empfehlung kippen würde,
explizit darauf hinweisen.
---END---
```

---

---

## Brief 2 v2 (2026-06-02, aktiv) — Cloud-Modelle (Ollama Cloud)

Für das `cloud+local`-Profil von OpenCode. v2 enthält drei strukturelle Härtungen gegenüber v1:

1. **Anti-Scope-Block ganz oben** — explizite „Du sollst NICHT"-Liste, um BWL-Drift zu verhindern.
2. **Output-Schablone als ausgefülltes Dummy-Beispiel** — die Engine pattern-matched besser auf Beispiele als auf Anweisungen.
3. **Verifikationsschritt 0** — Modell muss auf https://ollama.com/search?c=cloud gelistet sein, sonst raus.

Zusätzlich: gezielte Pflicht-Fragen zu **MiniMax M3** (1. Juni 2026 Release, war in v1 noch unbekannt), **Kimi K2.6 Swarm-Architektur**, **GLM-5.1 Long-Loop-Eignung** und **DeepSeek V4 Pro 1M-Context**.

```
---START---
# Deep-Research-Auftrag: Ollama-Cloud-Modelle für OpenCode-Agents (v2)

## ⛔ Was du NICHT tun sollst (lies das ZUERST)

Dieser Auftrag ist **kein**:

- TCO-Vergleich Cloud vs. On-Premises
- Self-Hosting-Strategie mit RTX-/H100-Hardware-Vergleichen
- Enterprise-Beratung nach Team-Größe (5-20 Entwickler etc.)
- generelle Marktübersicht "Open-Weight AI 2026"
- Cost-Break-Even-Berechnung
- Sicherheits-/Compliance-Analyse chinesischer Hosted-APIs
- Energie-, Kühlungs- oder Hardware-Anschaffungs-Diskussion

Wenn dein Output mehr als 5 Sätze für eines dieser Themen aufwendet, hast du das Ziel verfehlt.
Strom, Kühlung, GPU-Anschaffung, "ab wann lohnt sich Self-Hosting", National Intelligence Law,
Klimatisierungskosten — **all das ist Out of Scope**.

## ✅ Was du tun sollst (genau eine Sache)

Pro OpenCode-Agent-Rolle die **TOP 3 Modelle aus dem Ollama-Cloud-Katalog**
empfehlen, die der Nutzer SOFORT in eine `opencode.json` als
`agent.<rolle>.model = "ollama/<name>:cloud"` eintragen kann.

**Output-Längen-Cap:** maximal 6 unterschiedliche Modelle über alle Rollen hinweg
(überlappende Empfehlungen über mehrere Rollen sind erlaubt und erwünscht).

## Kontext (knapp)

Nutzer ist Software-Engineer (Python, SQL, dbt, Docker, Kubernetes, Data Engineering /
Data Science / AI Engineering). Sein OpenCode-Setup hat zwei Profile:

- `local` (M4 Pro 48 GB, nur Ollama lokal) — für offline und datensensitive Arbeit
- `cloud+local` (Ollama Cloud `:cloud`-Suffix + lokaler Daemon) — Ziel dieser Recherche

Parallel nutzt er Claude Code (Anthropic) und Codex CLI (OpenAI) für proprietäre Modelle.
OpenCode ist die "Open-Weight-Lane" — Vendor-Frei, unabhängig von OpenAI-/Anthropic-Roadmaps.

Workflow-Pattern: Subagent-Driven Development
(siehe https://github.com/obra/superpowers/blob/main/skills/subagent-driven-development/SKILL.md):
ein Primary Agent plant, dispatched fresh Subagents pro atomarer Task, Two-Stage Review,
synthetisiert am Ende.

## Schritt 0 (PFLICHT vor jeder Empfehlung): Verfügbarkeitsprüfung

Bevor du ein Modell empfiehlst, **verifiziere auf https://ollama.com/search?c=cloud**, dass
es im aktuellen Ollama-Cloud-Katalog gelistet ist, und welcher exakte Tag-String
(z.B. `glm-5.1:cloud`, `minimax-m3:cloud`) für den Aufruf zu verwenden ist.

Wenn ein Modell technisch existiert (z.B. auf Hugging Face), aber NICHT im Ollama-Cloud-Katalog,
darfst du es **nicht als Top-Pin empfehlen**. Erwähne es im "Nicht empfohlen"-Block am
Schluss mit Begründung "nicht in Ollama Cloud verfügbar (Stand $RECHERCHE_DATUM)".

## Sechs Agent-Rollen (small_model übersprungen)

### 1. `build` — Primary Coder

Implementiert nach freigegebener Spec. Macht die meiste Arbeit der Session (mehrstündig).

- **Kritisch:** stabiles Tool-Use über lange Trajectories (Read, Write, Edit, Bash mehrfach
  pro Turn), Iterative TDD-Loops, Diff-aware Editing über mehrere Files
- **Benchmarks:** SWE-Bench Verified, SWE-Bench Pro, SWE-rebench, Aider Polyglot
- **Anti-Pattern:** Tool-Call-Halluzination, Parameter-Schema-Drops

### 2. `plan` — Primary Architect

Specs, Pläne, Architekturentscheidungen, Trade-off-Analyse. Reasoning > Tool-Use.

- **Kritisch:** Reasoning, structured output (Markdown mit klaren Headings), Multi-Constraint
  über lange Kontexte
- **Benchmarks:** GPQA Diamond, MMLU-Pro, LiveCodeBench Reasoning
- **Diversity-Anforderung:** MUSS andere Modellfamilie als `build` sein

### 3. `researcher` — Read-only Recon (BLEIBT LOKAL)

Hinweis: läuft bewusst lokal (qwen2.5-coder:7b) im cloud+local-Profil — kein Cloud-Roundtrip
für read-heavy Recon. **Übergeh diese Rolle**, ES SEI DENN du findest ein Cloud-Modell mit
Sonnet-Level-Recon-Qualität unter 8B params. Dann zeig es als Alternative.

### 4. `reviewer` — Code-Review gegen Spec

Read-only Diff-Review. Bekommt Spec + Diff, gibt Verdict.

- **Kritisch:** Logikfehler-Erkennung im Diff-Kontext, Spec-Compliance, Conventions-Bewusstsein
- **Diversity-Anforderung:** MUSS andere Modellfamilie als `build` UND `plan` sein
  (drei verschiedene Lineages → maximale Blindspot-Reduktion)

### 5. `security-auditor` — Security-Pass

Read-only. Sucht Secrets, Injection-Pfade, AuthZ-Misconfigs, Race Conditions.

- **Kritisch:** Pattern-Erkennung über mehrere Files, aktuelles CVE-Wissen (Trainings-Cutoff
  möglichst >2025), strukturierte Findings (Severity / Location / Recommendation)
- **Benchmarks:** CyberSecEval falls verfügbar

### 6. `small_model` — übersprungen

Bleibt lokal (llama3.2:1b). Nicht behandeln, nur in einer Zeile bestätigen.

## Pflicht-Fragen (jede einzeln beantworten, NICHT überspringen)

### F1: MiniMax M3 (released 1. Juni 2026)

- Verfügbar in Ollama Cloud? Wenn ja, exakter Tag-String?
- Architektur-Highlights: MiniMax Sparse Attention, 1M Context, 9.7× Prefill-Speedup,
  modifizierte MIT (kommerzielle Einschränkungen).
- Eignung für `build` oder `plan`?
- Tool-Use-Reife in Ollama Cloud (Modell ist <2 Wochen alt zum Recherche-Zeitpunkt —
  daher voraussichtlich noch Reifefenster)?
- Wenn nicht verfügbar: ETA-Stand laut Ollama Blog oder GitHub Issues?

### F2: Kimi K2.6 (released 20. April 2026, Swarm-Architektur)

- Verfügbar in Ollama Cloud? Exakter Tag-String?
- Swarm-Skalierung (bis 300 parallele Sub-Agents, 4000 koordinierte Schritte) — ist das
  in Ollama Cloud nutzbar oder eine Eigenschaft, die nur in proprietären
  Moonshot-Endpoints aktiviert ist?
- Praktischer Mehrwert für `plan` als Master-Orchestrator, der `build`/`reviewer`/
  `security-auditor` dispatched?
- Tool-Use-Stabilität (MLA-Architektur, was sind die Implikationen)?

### F3: GLM-5.1 (released 7. April 2026, MIT-Lizenz, 200K nativ / 1M API)

- Verfügbar in Ollama Cloud? Exakter Tag-String?
- Berichte über "8h autonome Entwicklungsschleifen ohne Drift" — verifiziere oder
  falsifiziere mit konkreten Quellen.
- Geeignet als Cloud-Modell für autonomen Coding Agent (Long-Loop ohne menschliche
  Intervention)?
- XML-Envelope-Tool-Calling-Reife in Ollama Cloud (war bei GLM-4.6 ein Problem —
  konkrete GitHub-Issue-Verweise)?

### F4: DeepSeek V4 Pro (released 24. April 2026, MIT, 1M Context, FP4/FP8)

- Verfügbar in Ollama Cloud? Exakter Tag-String?
- 1M Context — wirklich nutzbar für große Codebases, oder geht Recall ab >256K stark zurück?
- Cost-Tier auf Ollama Cloud — reicht Pro ($20), oder nur in Max ($100) verfügbar?
- Vergleich vs. Kimi K2.6 für `plan` mit großen Codebases?

### F5: Qwen3-Coder-Next:cloud (80B MoE, 3B active)

- 70.6% SWE-bench Verified — lohnt das gegen MiniMax M3 / GLM-5.1 / Kimi K2.6 mit ~80%?
- Wenn `build` auf Qwen3-Coder-Next:cloud läuft (gleiche Familie wie der lokale researcher
  qwen2.5-coder:7b), ist das ein Diversity-Problem oder unproblematisch?
- Praktische Tool-Use-Stabilität in Ollama Cloud heute (vs. lokale Version)?

### F6: gpt-oss:120b-cloud (Apache-2.0, Reasoning-Modus)

- Konkurrenzfähig gegen die chinesischen Frontier-Modelle bei `plan` und `reviewer`?
- Trainings-Cutoff — wie aktuell ist das CVE-Wissen für `security-auditor`-Rolle?
- Gibt es eine `gpt-oss-safeguard`-Variante in Ollama Cloud (analog zum lokalen
  gpt-oss-safeguard:20b für Security-Tasks)?

## Output-Schablone (KOPIERE DIE STRUKTUR EXAKT)

Hier ein **ausgefülltes Dummy-Beispiel mit ERFUNDENEN Daten**. Übernimm die Struktur,
nicht die Inhalte. Jede Top-1-Empfehlung muss genau diese Felder ausgefüllt haben:

```
### Rolle: build

#### Top 1 (✅): ollama/dummy-coder-v3:cloud

| Feld | Wert |
|---|---|
| Verfügbarkeit Ollama Cloud (verifiziert am) | ✅ ja, https://ollama.com/library/dummy-coder-v3 (2026-06-02) |
| Cost-Tier | Pro reicht (Stufe 2 laut Ollama Pricing) |
| SWE-Bench Verified | 75.4% ([Modellkarte HF, 2026-04-15](https://example.com/1)) |
| SWE-Bench Pro | 58.2% ([SWE-Bench Leaderboard, 2026-05-20](https://example.com/2)) |
| Aider Polyglot | 68% ([Aider Leaderboard, 2026-03-20](https://example.com/3)) |
| Tool-Use Stabilität Ollama Cloud | stabil seit Mai 2026 ([Issue #1234 closed](https://example.com/4)) |
| Native Context | 256K |
| Reasoning-Modus | nein |
| Modellfamilie / Lineage | DummyCorp v3-Series |
| Lizenz | Apache-2.0 |
| Trainings-Cutoff | 2026-01 |
| Letztes Update | 2026-04-10 |
| Maturity | ✅ Established |

**Begründung (3 Sätze):** Stabilste Tool-Use-Trajectory unter den Open-Weight-Modellen
mit ~75% SWE-Bench, identifiziert über 6-wöchige Produktiv-Tests im r/LocalLLaMA-Subreddit.
Kein Drift in mehrstündigen Sessions dank explizitem "Long-Horizon"-Training. Gegen
MiniMax M3 (80.5% SWE-Bench, aber 2 Wochen alt) ist es das reifere Werkzeug.

#### Top 2 (✅/🧪): ollama/other-cloud-model:cloud

[gleiche Tabelle, kürzere Begründung]

#### Top 3 (🧪/💡): ollama/watch-model:cloud

[gleiche Tabelle, was muss noch reifen?]
```

**Wiederhole diesen Block** für jede der vier zu behandelnden Rollen
(`build`, `plan`, `reviewer`, `security-auditor`).

## Pflicht-Schluss-Sektionen

### S1: Empfehlungs-Matrix

Markdown-Tabelle, Zeilen = Rollen, Spalten = Top 1 / Top 2 / Top 3,
Zellen = exakte `ollama/<name>:cloud`-Strings. Diese Matrix muss direkt in eine
`opencode.json`-Agent-Map kopierbar sein.

### S2: Diversity-Bewertung

- Liste die Modellfamilien der Top-1-Pins für build / plan / reviewer / security-auditor.
- Sind das mindestens DREI verschiedene Lineages? (build/plan/reviewer)
- Wenn ja: in 2 Sätzen, welche systematischen Fehlerklassen würden dadurch entdeckt,
  die ein gleichfamiliäres Setup übersehen würde?
- Wenn nein: welcher Single-Tausch würde Diversity herstellen?

### S3: Cost-Estimate für typische 2h-Coding-Session

**Annahme-Sessions-Profil:**
- 1× `build`-Trajectory, ca. 1.5h aktive Token-Generierung
- 2× `researcher`-Dispatches (bleiben lokal, GPU-Time = 0)
- 1× `reviewer`-Dispatch, ca. 5 Min
- 1× `security-auditor`-Dispatch, ca. 10 Min

**Antworte:**
- Welcher Ollama-Cloud-Plan reicht — Free / Pro ($20) / Max ($100)?
- Bei Pro: wie viele solcher Sessions/Tag, bevor das Tageslimit greift?
- Bei Max: gleiche Frage.

**Wenn du keine konkreten GPU-Time-Zahlen findest:** sag das **explizit**, gib einen
Best-Estimate mit der zugrundeliegenden Heuristik (z.B. „Ollama dokumentiert keine
Tokens/GPU-Sek-Mapping; basierend auf Community-Berichten X / GPU-Tier-Klassifikation Y
schätze ich Z").

### S4: Was ich NICHT empfehle und warum (genau 3-5 Modelle)

Pro Modell:
- Name
- Konkreter Grund: "nicht in Ollama Cloud verfügbar" / "Tool-Use instabil — Issue #XXX" /
  "Lizenz schließt kommerzielle Nutzung aus" / "auf Benchmark Y stark, aber Tool-Call-Schema
  unzuverlässig — verifiziert in Bericht Z"

## Quellen-Priorität (hoch → niedrig)

1. https://ollama.com/search?c=cloud (Ollama-Cloud-Katalog mit Stand-Datum)
2. https://ollama.com/library/<name> (Modell-spezifische Tags)
3. https://ollama.com/blog/<model> (Ollama-Modell-Announcements)
4. Offizielle Hersteller-Modellkarten (Hugging Face, Hersteller-Blogs: MiniMax, Zhipu/GLM,
   Moonshot/Kimi, DeepSeek, Alibaba/Qwen, OpenAI gpt-oss)
5. https://swe-rebench.com, SWE-Bench-Verified Leaderboard, Aider Polyglot Leaderboard
6. r/LocalLLaMA Posts der letzten 90 Tage mit nachvollziehbarer Benchmark-Methodik
7. GitHub-Issues in `ollama/ollama` und Modell-Repos (für Tool-Use-Bugs)

## Aktualität

Stand: **Juni 2026**. Material vor März 2026 als `[possibly outdated, verify]` markieren.
Wenn ein Release der letzten 30 Tage die Empfehlung kippen würde, **explizit hinweisen**
mit der konkreten URL des Release-Posts.

## Letzte Selbstkontrolle (BEVOR du abschickst)

Vor dem Output prüfe explizit:

- [ ] Schritt 0 (Ollama-Cloud-Verifikation) für jede Top-1-Empfehlung durchgeführt?
- [ ] Genau 6 Modelle insgesamt (oder weniger)?
- [ ] Output-Schablone exakt befolgt für mindestens build / plan / reviewer / security-auditor?
- [ ] Empfehlungs-Matrix vorhanden und kopier-ready?
- [ ] Diversity-Bewertung explizit beantwortet (drei Lineages ja/nein)?
- [ ] Cost-Estimate für 2h-Session konkret beantwortet (auch wenn als Best-Estimate)?
- [ ] "Nicht empfehlen"-Block mit 3-5 Einträgen?
- [ ] Maximal 5 Sätze TCO-/Hardware-/Strategie-Inhalt im Gesamt-Output?
- [ ] Alle Pflicht-Fragen F1-F6 einzeln beantwortet?

Wenn auch nur EIN Kasten unangekreuzt ist, überarbeite vor dem Abschicken.
---END---
```



Wenn beide Briefs zurück sind, hast du zwei Empfehlungs-Matrizen. Damit:

1. **§7 im Review** ([[Review - Workflow-Refactoring (2026-05-29)]]) updaten — die jetzt dort stehenden Tabellen sind meine Best-Guess vom 2026-05-29; die Deep-Research-Ergebnisse sind die nächste Iteration mit besserer Quellenbasis.
2. **`Globals/opencode-local.json`** und **`Globals/opencode-cloud.json`** entsprechend befüllen (oder die Watch-list-Modelle als auskommentierte Optionen drinlassen).
3. **Quarterly-Review-Routine** — Briefs sind so geschrieben, dass du sie quartalsweise neu losschicken kannst. Open-Weight bewegt sich schnell; jede Quartals-Wiederholung wird vermutlich 1–2 Modelle ersetzen.

## Querverweise

- [[Review - Workflow-Refactoring (2026-05-29)]] §7 — aktuelle Modell-Auswahl (Pre-Research)
- [[OpenCode — Profil-Spezifikationen]] — wird durch §7 des Review ersetzt
- [[Subagent Driven Development]] *(zu erstellen, Phase 3)*
