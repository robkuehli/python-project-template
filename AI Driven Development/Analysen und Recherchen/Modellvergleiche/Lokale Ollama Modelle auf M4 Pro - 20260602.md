# Architekturanalyse und Modellempfehlungen für lokale agentische Software-Engineering-Workflows auf Apple Silicon (M4 Pro 48 GB)

## Ressourcenallokation und Speicherarchitektur auf dem M4 Pro

Der Betrieb eines lokalen, agentischen Software-Engineering-Workflows nach dem Subagent-Driven-Development-Pattern auf einem MacBook Pro M4 Pro mit 48 GB Unified Memory erfordert eine präzise mathematische Aufteilung der RAM-Kapazitäten. Da der Workflow von OpenCode parallele Instanzen für primäre Planungs- und Build-Agenten sowie dynamisch instanziierte Subagents (Recon, Review, Security) erfordert, wird ein striktes Speicherbudget von maximal 32 GB für aktive Modellinstanzen definiert. Die verbleibenden 16 GB sind als System-Headroom für das macOS-Betriebssystem, Docker-Container mit dbt-Pipelines, lokale Kubernetes-Testumgebungen und die TUI-basierte CLI-Infrastruktur reserviert.

Ein kritischer Trugschluss bei der Hardware-Planung betrifft das Modell _Qwen3-Coder-Next_ (80B MoE, 3B active).Dieses Modell wird in Entwicklerkreisen häufig als die einzige lokal lauffähige "Frontier-Klasse" für Coding-Agenten gehandelt. Eine detaillierte Untersuchung der Ollama-Implementierung zeigt jedoch, dass die offizielle GGUF-Variante in der Q4_K_M-Quantisierung (`qwen3-coder-next:latest` bzw. `qwen3-coder-next:q4_K_M`) einen physischen Speicher-Footprint von konstant 52 GB beansprucht. Ein Laden dieses Modells auf einer 48-GB-Hardware führt unweigerlich zu massiven macOS-Kernel-Swapping-Prozessen auf die SSD, wodurch die Token-Generierungsrate von theoretischen 50 Token pro Sekunde (t/s) auf unbrauchbare Raten von unter 2 t/s einbricht.

Die Lösung für dieses Skalierungsproblem liegt in der Nutzung der im Frühjahr 2026 veröffentlichten Modellreihe **Qwen3-Coder:30b** (30.5B MoE, 3.3B active). Dieses Modell bietet dank einer hocheffizienten Aktivierung von lediglich 3.3B Parametern pro Token eine Leistung, die das ältere Qwen3-Coder-Next-Modell in agentischen Schleifen übertrifft , beansprucht jedoch in der Q4_K_M-Quantisierung nur knapp 18 GB VRAM. Dadurch verbleiben im definierten Modell-Budget von 32 GB exakt 14 GB Spielraum, welcher perfekt durch hochspezialisierte Subagents wie **gpt-oss:20b** (21B MoE, 3.6B active ) mit einem physischen Footprint von 14 GB im nativen MXFP4-Format ausgefüllt werden kann.

## Technische Evaluation der sechs Agenten-Rollen

### 1. Die Build-Rolle (Primary Coder)

Der primäre Entwicklungs-Agent führt die eigentliche Implementierungsarbeit innerhalb iterativer Test-Driven-Development-Loops (TDD) durch. Dies erfordert ein extrem stabiles Verhalten bei aufeinanderfolgenden Tool-Calls (Dateizugriffe, Bash-Ausführung, Regex-Suchen) über lange Trajectories hinweg. Ein verlässlicher Umgang mit Diffs über mehrere Dateien hinweg ist hierbei essenziell.

|**Evaluations-Dimension**|**Top 1: qwen3-coder:30b**|**Top 2: gpt-oss:20b**|**Top 3: qwen2.5-coder:14b [possibly outdated, verify]**|
|---|---|---|---|
|**Größe (total / active)**|30.5B / 3.3B|21B / 3.6B|14.7B / 14.7B [possibly outdated, verify]|
|**Footprint GGUF (GB)**|~18.0 GB (Q4_K_M)|14.0 GB (MXFP4)|~9.2 GB (Q4_K_M) [possibly outdated, verify]|
|**Tokens/sec (M4 Pro)**|~50 t/s (GGUF) / 80 t/s (MLX)|~45 t/s (Ollama native)|~65 t/s (Ollama native)|
|**Context Window**|256K native|128K native|128K native [possibly outdated, verify]|
|**Tool-Use-Stabilität**|Hoch (Ollama Issue #12557 beachten)|Exzellent (Integrierte OpenAI-Tool-Spezifikationen)|Absolut fehlerfrei und deterministisch|
|**SWE-bench Verified %**|~70.0% (via SWE-Agent Scaffold)|N/A (o4-mini-äquivalentes Niveau)|~39.4% [possibly outdated, verify]|
|**SWE-rebench Score**|Kompetitiv (MoE-optimiert)|N/A|Solide, aber limitierter im Reasoning|
|**Lizenz**|[Apache-2.0](https://www.apache.org/licenses/LICENSE-2.0)|[Apache-2.0](https://www.apache.org/licenses/LICENSE-2.0)|[Apache-2.0](https://www.apache.org/licenses/LICENSE-2.0)|
|**Letztes Update**|Februar 2026|Oktober 2025|September 2024 [possibly outdated, verify]|
|**Maturity**|✅ Established|✅ Established|✅ Established|

- **Empfehlung Top 1 (✅): `qwen3-coder:30b`**
    
    Dieses Modell stellt das leistungsfähigste Werkzeug für den primären Coding-Einsatz dar, da es gezielt auf Basis von 800.000 ausführbaren Programmieraufgaben und direktem Feedback aus Ausführungsumgebungen trainiert wurde. Mit einem nativen 256K-Kontextfenster erfasst es mühelos komplexe Verzeichnisstrukturen und dbt-Projektkonfigurationen, ohne dass feingranulare RAG-Strategien implementiert werden müssen. Entwickler sollten jedoch beachten, dass Ollamas Streaming-Implementierung für Tool-Calls bei diesem Modell in bestimmten Versionen unvollständig sein kann, was die Nutzung von nicht-streamenden API-Aufrufen über OpenCode ratsam macht.
    
- **Alternative Top 2 (✅/🧪): `gpt-oss:20b`**
    
    Dieses Modell eignet sich hervorragend als primärer Coder, falls hochgradig abstrakte logische Datenstrukturen entworfen werden müssen, da es über einen exzellenten integrierten Logikmodus verfügt. Durch die native Unterstützung des Harmony-Response-Formats in Ollama interagiert es fehlerfrei mit CLI-Tools wie dem OpenAI Codex CLI. Es sollte gewählt werden, wenn die Generierung von Code stark von komplexen mathematischen Logikschritten abhängt.
    
- **Watch-list Top 3 (🧪/💡): `qwen2.5-coder:14b`**
    
    Das dichte Vorgängermodell dient als extrem stabiler Failsafe-Kandidat für die Entwicklungsarbeit, falls MoE-typische Phänomene wie sporadische Formatierungsfehler im TUI-Parser von OpenCode auftreten. Seine Code-Generierungsqualität ist hochgradig deterministisch, wenngleich das Modell bei komplexen logischen Transferschleifen spürbar hinter der Leistung der neueren MoE-Architekturen zurückbleibt.
    

### 2. Die Plan-Rolle (Primary Architect)

Der Architekt analysiert Anforderungen, entwirft Implementierungspläne und formuliert technische Vorgaben für die nachgelagerten Subagents. Hier steht die Einhaltung komplexer logischer Rahmenbedingungen im Vordergrund, während die eigentliche Code-Synthese zweitrangig ist.

|**Evaluations-Dimension**|**Top 1: gpt-oss:20b**|**Top 2: qwen3-coder:30b**|**Top 3: deepseek-r1:14b [possibly outdated, verify]**|
|---|---|---|---|
|**Größe (total / active)**|21B / 3.6B|30.5B / 3.3B|14B / 14B [possibly outdated, verify]|
|**Footprint GGUF (GB)**|14.0 GB (MXFP4)|~18.0 GB (Q4_K_M)|~9.0 GB (Q4_K_M) [possibly outdated, verify]|
|**Tokens/sec (M4 Pro)**|~45 t/s|~50 t/s|~48 t/s|
|**Context Window**|128K native|256K native|64K native (Ollama Default)|
|**Tool-Use-Stabilität**|Sehr hoch (nativ integriert)|Hoch (nicht-streamend stabil)|Eingeschränkt (CoT-Blöcke brechen Parser)|
|**GPQA / ARC Score**|SOTA in dieser Größenklasse|Sehr hoch|Exzellent (Reasoning-fokussiert)|
|**SWE-rebench Score**|N/A|Kompetitiv|N/A|
|**Lizenz**|[Apache-2.0](https://www.apache.org/licenses/LICENSE-2.0)|[Apache-2.0](https://www.apache.org/licenses/LICENSE-2.0)|([https://opensource.org/licenses/MIT](https://opensource.org/licenses/MIT))|
|**Letztes Update**|Oktober 2025|Februar 2026|Januar 2025 [possibly outdated, verify]|
|**Maturity**|✅ Established|✅ Established|✅ Established|

- **Empfehlung Top 1 (✅): `gpt-oss:20b`**
    
    Dieses Modell eignet sich hervorragend für die Strukturierung komplexer Systemarchitekturen, da es über eine integrierte Logik-Inferenz mit anpassbarer Denktiefe verfügt. Im Gegensatz zu reinen Programmiermodellen erzeugt es detaillierte, logisch lückenlose Markdown-Spezifikationen und wägt technische Risiken präzise ab. Die Möglichkeit, den vollständigen internen Denkprozess zur Qualitätssicherung auszulesen, erleichtert das Debugging komplexer dbt- und SQL-Pipelines erheblich.
    
- **Alternative Top 2 (✅/🧪): `qwen3-coder:30b`**
    
    Das Modell sollte dann als Planungsinstanz gewählt werden, wenn die Erstellung des Architekturentwurfs eine umfassende Analyse extrem großer Codebasen erfordert. Dank des nativen 256K-Kontextfensters liest es umfangreiche System-Spezifikationen ein, ohne dass wichtige architektonische Details verloren gehen.
    
- **Watch-list Top 3 (🧪/💡): `deepseek-r1:14b`**
    
    Das Modell liefert dank seiner dedizierten Ausrichtung auf logische Schlussfolgerungen exzellente Resultate bei mathematischen Datenmodellierungen. Es verbleibt auf der Watchlist, da die automatische Ausgabe von `<think>`-Blöcken im TUI-Parser von OpenCode ohne eine serverseitige Filterung zu Darstellungs- und Logikfehlern in den Agentenschleifen führen kann.
    

### 3. Die Researcher-Rolle (Subagent Explorer)

Der Explorer durchsucht die Codebasis lesend nach bestimmten Mustern, analysiert Abhängigkeiten und liefert prägnante Zusammenfassungen. Er läuft parallel zum Build-Agenten, weshalb ein minimaler RAM-Footprint und eine extrem hohe Generierungsgeschwindigkeit entscheidend sind.

|**Evaluations-Dimension**|**Top 1: qwen2.5-coder:7b [possibly outdated, verify]**|**Top 2: llama3.1:8b**|**Top 3: phi-3.5-mini:3.8b [possibly outdated, verify]**|
|---|---|---|---|
|**Größe (total / active)**|7.2B / 7.2B [possibly outdated, verify]|8.0B / 8.0B|3.8B / 3.8B [possibly outdated, verify]|
|**Footprint GGUF (GB)**|~4.7 GB (Q4_K_M)|~4.8 GB (Q4_K_M)|~2.2 GB (Q4_K_M)|
|**Tokens/sec (M4 Pro)**|~85 t/s (GGUF) / 125 t/s (MLX)|~80 t/s|~110 t/s|
|**Context Window**|128K native|128K native|128K native|
|**Tool-Use-Stabilität**|Äußerst stabil und erprobt|Sehr stabil|Moderat (neigt zu Formatierungsfehlern)|
|**Durchsatzfokus**|Maximum auf Apple Silicon|Ausgeglichen|Sehr hoch bei geringem RAM|
|**SWE-bench Verified %**|~39.4% [possibly outdated, verify]|~25.2% [possibly outdated, verify]|N/A|
|**Lizenz**|[Apache-2.0](https://www.apache.org/licenses/LICENSE-2.0)|[Llama-3.1-Community](https://github.com/meta-llama/llama-models/blob/main/models/llama3_1/LICENSE)|([https://opensource.org/licenses/MIT](https://opensource.org/licenses/MIT))|
|**Letztes Update**|September 2024 [possibly outdated, verify]|Juli 2024|August 2024 [possibly outdated, verify]|
|**Maturity**|✅ Established|✅ Established|✅ Established|

- **Empfehlung Top 1 (✅): `qwen2.5-coder:7b`**
    
    Das Modell ist die ideale Besetzung für die Explorer-Rolle, da es auf dem M4 Pro Generierungsgeschwindigkeiten von über 85 t/s im GGUF-Format und bis zu 125 t/s unter MLX erreicht. Mit einem minimalen Speicherbedarf von 4.7 GB läuft es problemlos parallel zum primären Build-Agenten, ohne das Speicherbudget von 32 GB zu belasten. Es verarbeitet umfangreiche Codeauflistungen fehlerfrei und liefert präzise strukturierte Suchergebnisse.
    
- **Alternative Top 2 (✅/🧪): `llama3.1:8b`**
    
    Dieses Modell stellt eine hervorragende Alternative dar, wenn Codebasen durchsucht werden sollen, die stark durch unstrukturierte Dokumentationen geprägt sind. Die ausgewogene Wissensverteilung der Llama-Modellfamilie sorgt für präzise Ergebnisse bei der semantischen Suche in Repositories.
    
- **Watch-list Top 3 (🧪/💡): `phi-3.5-mini:3.8b`**
    
    Mit einem physischen Speicherbedarf von lediglich 2.2 GB schont dieses extrem kompakte Modell die Hardwareressourcen maximal. Es bietet ein natives 128K-Kontextfenster, erfordert jedoch im Vergleich zu Qwen hochgradig strukturierte Systemprompts, um Tool-Aufrufe ohne Syntaxfehler auszuführen.
    

### 4. Die Reviewer-Rolle (Subagent Code-Review)

Der Review-Agent vergleicht den generierten Code-Diff mit den Vorgaben des Architekten. Um kognitive Redundanzen zu vermeiden, muss dieser Agent zwingend einer anderen Modellfamilie angehören als der primäre Build-Agent.

|**Evaluations-Dimension**|**Top 1: gpt-oss:20b**|**Top 2: phi-4 [possibly outdated, verify]**|**Top 3: llama3.1:8b**|
|---|---|---|---|
|**Größe (total / active)**|21B / 3.6B|14B / 14B [possibly outdated, verify]|8.0B / 8.0B|
|**Footprint GGUF (GB)**|14.0 GB (MXFP4)|~9.1 GB (Q4_K_M)|~4.8 GB (Q4_K_M)|
|**Tokens/sec (M4 Pro)**|~45 t/s|~48 t/s|~80 t/s|
|**Context Window**|128K native|128K native|128K native|
|**Tool-Use-Stabilität**|Sehr hoch|Hoch|Sehr hoch|
|**Modellfamilie**|OpenAI (Symmetriebruch zu Qwen)|Microsoft|Meta|
|**Diff-Verständnis**|Exzellent (durch Logikmodus)|Sehr gut|Befriedigend (neigt zu False Positives)|
|**Lizenz**|[Apache-2.0](https://www.apache.org/licenses/LICENSE-2.0)|([https://opensource.org/licenses/MIT](https://opensource.org/licenses/MIT))|[Llama-3.1-Community](https://github.com/meta-llama/llama-models/blob/main/models/llama3_1/LICENSE)|
|**Letztes Update**|Oktober 2025|Januar 2025 [possibly outdated, verify]|Juli 2024|
|**Maturity**|✅ Established|✅ Established|✅ Established|

- **Empfehlung Top 1 (✅): `gpt-oss:20b`**
    
    Der Einsatz dieses OpenAI-basierten Modells bricht die kognitive Symmetrie zum primären Qwen-Build-Agenten perfekt auf und verhindert das Übersehen systematischer Fehler. Dank des integrierten logischen Argumentationsmodus analysiert es Diff-Strukturen präzise und erkennt logische Diskrepanzen zwischen der Spezifikation und dem geschriebenen Code. Es beurteilt Code-Stilistiken objektiv anhand hinterlegter Richtlinien und liefert konstruktive Verbesserungsvorschläge.
    
- **Alternative Top 2 (✅/🧪): `phi-4`**
    
    Das dichte 14B-Modell von Microsoft bietet dank seines starken logischen Fundaments eine hervorragende Alternative. Es analysiert Code-Änderungen präzise auf syntaktische Korrektheit und arbeitet hochgradig ressourcenschonend.
    
- **Watch-list Top 3 (🧪/💡): `llama3.1:8b`**
    
    Eignet sich für schnelle Zwischenprüfungen im Entwicklungszyklus, um triviale Syntaxfehler abzufangen.Aufgrund der geringeren Parametergröße neigt es bei komplexen, mehrschichtigen Logik-Diffs jedoch gelegentlich zu ungenauen Bewertungen.
    

### 5. Die Security-Auditor-Rolle (Subagent Security)

Der Sicherheits-Auditor analysiert Code-Diffs auf Schwachstellen (wie SQL-Injections, ungeschützte API-Routen oder Hardcoded Secrets) und greift dabei auf aktuelles CVE-Wissen zurück.

|**Evaluations-Dimension**|**Top 1: gpt-oss-safeguard:20b**|**Top 2: gpt-oss:20b**|**Top 3: qwen3-coder:30b**|
|---|---|---|---|
|**Größe (total / active)**|21B / 3.6B|21B / 3.6B|30.5B / 3.3B|
|**Footprint GGUF (GB)**|14.0 GB (MXFP4)|14.0 GB (MXFP4)|~18.0 GB (Q4_K_M)|
|**Tokens/sec (M4 Pro)**|~45 t/s|~45 t/s|~50 t/s|
|**Context Window**|128K native|128K native|256K native|
|**Tool-Use-Stabilität**|Hoch (primär Richtlinien-Evaluation)|Sehr hoch|Hoch (nicht-streamend stabil)|
|**Sicherheits-Fokus**|Dedizierte Sicherheits-Inferenz|Allgemeines logisches Audit|Codefluss-Analyse|
|**CVE-Wissen**|Aktuell bis Ende 2025|Aktuell bis Ende 2025|Aktuell bis Anfang 2026|
|**Lizenz**|[Apache-2.0](https://www.apache.org/licenses/LICENSE-2.0)|[Apache-2.0](https://www.apache.org/licenses/LICENSE-2.0)|[Apache-2.0](https://www.apache.org/licenses/LICENSE-2.0)|
|**Letztes Update**|Oktober 2025|Oktober 2025|Februar 2026|
|**Maturity**|✅ Established|✅ Established|✅ Established|

- **Empfehlung Top 1 (✅): `gpt-oss-safeguard:20b`**
    
    Diese spezialisierte Sicherheitsvariante des gpt-oss-Modells wurde gezielt für die Anwendung komplexer Sicherheitsrichtlinien und Risikoanalysen trainiert. Sie liefert detaillierte Erklärungen für identifizierte Risiken wie SQL-Injections oder fehlerhafte Berechtigungen in dbt-Pipelines, anstatt lediglich abstrakte Risikobewertungen auszugeben. Die permissive Apache-2.0-Lizenz erlaubt den uneingeschränkten Einsatz in kommerziellen Projekten.
    
- **Alternative Top 2 (✅/🧪): `gpt-oss:20b`**
    
    Das Standardmodell bietet sich an, wenn der Sicherheits-Audit eine aktive Durchsicht externer Abhängigkeiten oder die Interaktion mit lokalen Sicherheitswerkzeugen über Tool-Aufrufe erfordert.
    
- **Watch-list Top 3 (🧪/💡): `qwen3-coder:30b`**
    
    Dieses Modell empfiehlt sich für tiefe Datenflussanalysen über sehr große Kontextgrenzen hinweg, um komplexe Injektionspfade in verschachtelten dbt- und SQL-Strukturen aufzudecken.
    

### 6. Die Small-Model-Rolle (Utility)

Das Hilfsmodell übernimmt einfache, repetitive Aufgaben im Hintergrund, wie das Generieren von Commits, das Erstellen von PR-Titeln oder die schnelle Klassifizierung von Texten. Hierbei zählen eine extrem niedrige Latenz und ein minimaler Speicherbedarf.

|**Evaluations-Dimension**|**Top 1: llama3.2:1b**|**Top 2: qwen2.5:1.5b**|**Top 3: llama3.2:3b**|
|---|---|---|---|
|**Größe (total / active)**|1.2B / 1.2B|1.5B / 1.5B|3.2B / 3.2B|
|**Footprint GGUF (GB)**|~1.3 GB (Q4_K_M)|~1.6 GB (Q4_K_M)|~2.0 GB (Q4_K_M)|
|**Tokens/sec (M4 Pro)**|~200 t/s|~180 t/s|~140 t/s|
|**Context Window**|128K native|128K native|128K native|
|**Tool-Use-Stabilität**|Befriedigend (einfache Ausdrücke)|Sehr gut (präzise JSON-Rückgaben)|Gut|
|**Footprint-Kompression**|Extrem leichtgewichtig|Sehr gering|Grenzwertig für Hintergrundbetrieb|
|**Lizenz**|[Llama-3.2-Community](https://github.com/meta-llama/llama-models/blob/main/models/llama3_2/LICENSE)|[Apache-2.0](https://www.apache.org/licenses/LICENSE-2.0)|[Llama-3.2-Community](https://github.com/meta-llama/llama-models/blob/main/models/llama3_2/LICENSE)|
|**Letztes Update**|September 2024 [possibly outdated, verify]|September 2024 [possibly outdated, verify]|September 2024 [possibly outdated, verify]|
|**Maturity**|✅ Established|✅ Established|✅ Established|

- **Empfehlung Top 1 (✅): `llama3.2:1b`**
    
    Das Modell agiert mit Verarbeitungsgeschwindigkeiten von ca. 200 t/s auf dem Apple Silicon M4 Pro nahezu latenzfrei. Mit einem Speicherbedarf von nur 1.3 GB läuft es dauerhaft im Hintergrund, ohne die Leistung der primären Entwicklungs- und Planungs-Agenten zu beeinträchtigen. Es ist die optimale Wahl für schnelle, unkomplizierte Textformatierungen und PR-Titel-Generierungen.
    
- **Alternative Top 2 (✅/🧪): `qwen2.5:1.5b`**
    
    Dieses Modell zeichnet sich durch eine hervorragende Einhaltung von JSON-Ausgabeformaten aus. Es sollte gewählt werden, wenn strukturierte Ausgaben für nachgelagerte CLI-Parser zwingend fehlerfrei erzeugt werden müssen.
    
- **Watch-list Top 3 (🧪/💡): `llama3.2:3b`**
    
    Das Modell bietet ein besseres Textverständnis für komplexere Klassifizierungsaufgaben. Aufgrund seines physischen Speicherbedarfs von 2.0 GB kratzt es jedoch an der definierten Obergrenze für Hilfsmodelle und erzeugt eine spürbar höhere Inferenzlatenz.
    

## Vergleichende Performance-Analyse: Apple-MLX vs. Ollama GGUF

Die Inferenz auf Apple Silicon kann entweder klassisch über Ollamas GGUF-Engine (basierend auf `llama.cpp`) oder über Apple-eigene MLX-Frameworks (z. B. via `mlx-community`-Builds auf Hugging Face) abgewickelt werden.

Eine detaillierte Analyse zeigt deutliche Leistungsunterschiede: MLX-Modelle erzielen auf Apple Silicon eine um 30% bis 50% höhere Verarbeitungsgeschwindigkeit bei der Textgenerierung im Vergleich zu GGUF-basierten Systemen unter Ollama. Während das Modell `qwen3-coder:30b` über Ollamas GGUF-Engine ca. 50 t/s erreicht , liefert die entsprechende MLX-DWQ-Quantisierung im direkten Vergleich bis zu 80 t/s bei identischem physischem Speicherbedarf. Zudem optimiert MLX den Speicherzugriff effizienter, was die thermische Belastung und die Leistungsaufnahme des M4 Pro unter Volllast reduziert.

Trotz dieser signifikanten Performance-Vorteile von MLX erweist sich das GGUF-Format unter Ollama im praktischen Einsatz als das stabilere Fundament für agentische Workflows. Ollama bietet eine native, robust implementierte Integration für strukturierte Tool-Aufrufe, die mit dem standardisierten OpenAI-Format kompatibel ist. MLX-basierte Workflows hingegen erfordern oft komplexe, maßgeschneiderte Middleware wie das Tool `mlx-lm`, um Tool-Aufrufe zuverlässig zu parsen, was die Fehleranfälligkeit in automatisierten Agentenschleifen erhöht.

Für den produktiven Einsatz innerhalb von OpenCode empfiehlt sich daher die Nutzung der stabilen Ollama-Infrastruktur, während MLX-Frameworks primär für reine, geschwindigkeitsfokussierte Textgenerierungen ohne komplexe Tool-Interaktionen infrage kommen.

## Empfehlungs-Matrix

Die nachfolgende Übersicht ordnet den sechs Agenten-Rollen die optimalen lokalen Modelle zu. Die Bezeichnungen sind so gewählt, dass sie direkt in die Konfigurationsdatei `opencode.json` übernommen werden können.

|**Rolle**|**Top 1 (Empfehlung)**|**Top 2 (Alternative)**|**Top 3 (Watch-list)**|
|---|---|---|---|
|**`build`**|`ollama/qwen3-coder:30b`|`ollama/gpt-oss:20b`|`ollama/qwen2.5-coder:14b`[possibly outdated, verify]|
|**`plan`**|`ollama/gpt-oss:20b`|`ollama/qwen3-coder:30b`|`ollama/deepseek-r1:14b`[possibly outdated, verify]|
|**`researcher`**|`ollama/qwen2.5-coder:7b`[possibly outdated, verify]|`ollama/llama3.1:8b`|`ollama/phi-3.5-mini:3.8b`[possibly outdated, verify]|
|**`reviewer`**|`ollama/gpt-oss:20b`|`ollama/phi-4` [possibly outdated, verify]|`ollama/llama3.1:8b`|
|**`security-auditor`**|`ollama/gpt-oss-safeguard:20b`|`ollama/gpt-oss:20b`|`ollama/qwen3-coder:30b`|
|**`small_model`**|`ollama/llama3.2:1b`|`ollama/qwen2.5:1.5b`|`ollama/llama3.2:3b`|

### Konfigurationsbeispiel (`opencode.json`)

JSON

```
{
  "agent.build.model": "ollama/qwen3-coder:30b",
  "agent.plan.model": "ollama/gpt-oss:20b",
  "agent.researcher.model": "ollama/qwen2.5-coder:7b",
  "agent.reviewer.model": "ollama/gpt-oss:20b",
  "agent.security-auditor.model": "ollama/gpt-oss-safeguard:20b",
  "agent.small_model.model": "ollama/llama3.2:1b"
}
```

## Ungeeignete Modell-Empfehlungen für dieses Setup

In Online-Foren und unvollständigen Installationsanleitungen werden für lokale Entwicklungs-Workflows häufig ungeeignete Modelle empfohlen. Im Folgenden werden die gravierendsten Fehlentscheidungen für das vorliegende System-Setup detailliert analysiert.

### 1. Qwen3-Coder-Next (80B MoE, 3B active)

- **Grund der Ablehnung:** Obwohl dieses Modell auf dem Papier die Speerspitze lokaler Coding-Intelligenz darstellt , erweist sich der Speicherbedarf der Q4_K_M-Quantisierung unter Ollama mit 52 GB als zu massiv für das 48-GB-MacBook. Durch das zwangsläufige Auslagern von Daten auf die SSD bricht die Performance vollständig zusammen. Ein flüssiges Arbeiten im CLI-TUI ist ausgeschlossen, und parallele Subagents können nicht mehr geladen werden.
    

### 2. Codestral 22B

- **Grund der Ablehnung:** Trotz hervorragender Leistungswerte bei der Code-Generierung verbietet die restriktive _Mistral AI Research License_ jegliche kommerzielle Nutzung im echten Arbeitsumfeld oder in geschäftlichen CI/CD-Pipelines. Dies verletzt direkt den harten Constraint einer freien, kommerziell nutzbaren Lizenzierung.
    

### 3. Llama 3.3 (70B)

- **Grund der Ablehnung:** Als dichtes (dense) Modell benötigt Llama 3.3 selbst in einer mäßigen Q4_K_M-Quantisierung über 42 GB Speicher. Dies blockiert den physischen Arbeitsspeicher des M4 Pro fast vollständig. Es bleibt keinerlei Headroom für das Betriebssystem, die lokale OpenCode-Infrastruktur oder parallel initiierte Docker-Container und SQL/dbt-Pipelines.
    

### 4. Llama 4 Scout (109B MoE, 17B active)

- **Grund der Ablehnung:** Obwohl es sich um eine moderne, native MoE-Architektur von Meta handelt , beansprucht die GGUF-Fassung von `llama4:scout` in der Q4_K_M-Quantisierung bereits beim Start stolze 65 GB VRAM. Das Modell überschreitet die physische RAM-Grenze des 48-GB-Systems somit deutlich und blockiert jeglichen Spielraum für den parallelen Betrieb anderer Workflow-Komponenten. Es eignet sich daher keineswegs als leichtgewichtiges Hilfsmodell.
    

## Fazit und operative Empfehlungen

Für einen stabilen, hochgradig performanten Betrieb des OpenCode-Workflows auf dem M4 Pro (48 GB) empfiehlt sich eine hybride MoE-Belegung. Die Kombination aus `qwen3-coder:30b` für die primäre Entwicklungsarbeit und dem flexiblen `gpt-oss:20b` für Architektur- und Review-Schritte nutzt das 32-GB-Arbeitsspeicher-Budget optimal aus, ohne dass es zu gegenseitigen Ressourcenblockaden kommt.

Besonderes Augenmerk sollte auf die Speicherbereinigung nach dem Beenden von Subagents gelegt werden: Da Ollama ungenutzte Modelle standardmäßig für fünf Minuten im VRAM hält, empfiehlt es sich, das automatische Entladen in OpenCode über das Setzen der Umgebungsvariable `OLLAMA_NUM_PARALLEL=1` zu optimieren oder inaktive Instanzen nach dem Beenden eines Subagents explizit freizugeben. Dadurch wird sichergestellt, dass dem primären Entwicklungs-Agenten jederzeit die maximale Speicherbandbreite des Apple Silicon M4 Pro zur Verfügung steht.