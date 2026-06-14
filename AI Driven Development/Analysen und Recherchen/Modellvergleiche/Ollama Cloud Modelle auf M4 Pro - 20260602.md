
> Infrastruktur-Ökonomie, architektonische Innovationen und strategische Bereitstellungskonzepte für Unternehmen

#KI #Open-Weight #Infrastruktur #LLM #On-Premises #Enterprise

---

## Überblick

Im **Q1 2026** überschritt die Ollama-Runtime **52 Millionen monatliche Downloads**. Die Unternehmensdebatte hat sich verschoben: nicht mehr *ob* lokale KI einsatzfähig ist, sondern *ab wann* sich Self-Hosting gegenüber Cloud-Lösungen rechnet.

---

## Wirtschaftliche Analyse: Cloud vs. On-Premises

### Ollama Cloud – Tarifübersicht

| Plan | Preis/Monat | Gleichzeitige Modelle | Nutzungsmodell | Zielgruppe |
|---|---|---|---|---|
| **Free** | $0 | 1 | Stündliche/tägliche Caps, Session-Reset alle 5h | Prototyping, Modell-Evaluierung |
| **Pro** | ~$20 ($200/Jahr) | 3 | 50× Free-Kapazität, erweitertes Kontextfenster | Tägliche Entwickler-Workflows |
| **Max / Pro Max** | $100–$200 | 10 | 250× Free (5× Pro), höchste Priorität | Multi-Agenten-Pipelines, Produktion |

> [!NOTE] Abrechnungsmodell
> Statt Token-Abrechnung wird **GPU-Zeitnutzung** berechnet → kein finanzielles Risiko durch Token-Explosionen bei rekursiven Agenten-Sitzungen.

**Laststufen-Einteilung:**
- Stufe 1 (leicht): z. B. `gpt-oss:20b`
- Stufe 4 (schwer): z. B. `deepseek-v4-pro` (MoE-Strukturen)

---

### On-Premises Hardware

| GPU / System | VRAM | MSRP | Straßenpreis 2026 | Max. Modellgröße (Q4) |
|---|---|---|---|---|
| NVIDIA RTX 5080 | 16 GB GDDR7 | $999 | $999–$1.500 | ~22B Parameter |
| NVIDIA RTX 4090 | 24 GB GDDR6X | eingestellt | $2.755–$3.999 | ~34B Parameter |
| NVIDIA RTX 5090 | 32 GB GDDR7 | $1.999 | $3.700–$5.800 | ~45B Parameter |
| NVIDIA A100 | 80 GB HBM2 | – | $8.000–$15.000 | 70B+ Parameter |
| NVIDIA H100 | 80 GB HBM3 | – | $25.000–$40.000 | Enterprise-Cluster |

---

### Break-Even-Formel

$$R > 40P$$

- $R$ = tägliches Anfragevolumen
- $P$ = Modellparameter in Milliarden

> [!TIP] Faustregeln
> - **RTX 4090** amortisiert sich auf ~$70/Monat → Break-Even ab **~25.000 Anfragen/Tag**
> - **Apple Mac Studio M4 Max** → ~$155/Monat → Break-Even ab **~40.000 Anfragen/Tag** (+ kann 70B-Modelle laden, RTX 4090 nicht)

---

### Kosten pro 1 Mio. Output-Tokens

| Bereitstellung | Kosten/1M Tokens | Durchsatz / Anmerkung |
|---|---|---|
| Self-hosted vLLM (RTX 5090) | ~$0,36 | 480 t/s bei 50% Auslastung |
| Self-hosted Ollama (RTX 5090) | ~$0,93 | 185 t/s, vereinfachtes Setup |
| DeepSeek V4-Flash (API) | $0,28 | Aggressive Bepreisung |
| OpenAI GPT-5.4 mini (API) | $4,50 | Proprietär |
| OpenAI GPT-5.4 (API) | $15,00 | Proprietär |
| Anthropic Claude Opus 4.8 (API) | $25,00 | Höchste Qualitätsstufe |

---

### Sekundäre Betriebskosten

| Kostenfaktor | RTX 5090 System | Apple M4 Max |
|---|---|---|
| Stromverbrauch (Volllast) | ~900W → **~$91/Monat** | **$16–$20/Monat** |
| Kühlungskosten | $86–$130/Monat | gering |
| Einmalige Klimatisierung | $2.000–$8.000 | entfällt |

---

## Architektonische Innovationen 2026

### Z.ai GLM-5.1

- **Veröffentlicht:** 7. April 2026 | **Lizenz:** MIT
- **Finanzierung:** Börsengang Hongkong, 4,35 Mrd. HKD
- **Architektur:** GlmMoeDSA-Hybrid
  - 754B Gesamtparameter, **40B aktiv pro Token**
  - 256 geroutete + 1 gemeinsamer Experte (MoE)
  - DeepSeek Sparse Attention (DSA) + Gated DeltaNet Linear Attention
- **Kontext:** 200.000 Tokens nativ (bis 1M via API-Router)
- **Tokenizer:** Tekken (131.072 Vokabulargröße)
- **Stärke:** Reduzierung von strategischem Drift bei bis zu **8h autonomen Entwicklungsschleifen**

---

### MiniMax M3

- **Veröffentlicht:** 1. Juni 2026 | **Lizenz:** Modifizierte MIT (kommerzielle Einschränkungen)
- **Herkunft:** Shanghai
- **Architektur:** MiniMax Sparse Attention (MSA)
  - **Unkomprimierter KV-Cache** (kein Präzisionsverlust wie bei anderen Methoden)
  - Sparse Aktivierungsmuster → **1/20 Rechenaufwand** bei max. Kontextlänge
  - **9,7× Prefill-Beschleunigung**, **15,6× Decode-Beschleunigung**
- **Kontext:** 1 Million Tokens nativ
- **Modalität:** Text, Bild, Video + direkte Desktop-Steuerung

> [!WARNING] Lizenz-Hinweis
> Modifizierte MIT-Lizenz mit kommerziellen Einschränkungen – Diskussion über echte Quelloffenheit in der Community.

---

### Moonshot Kimi K2.6

- **Veröffentlicht:** 20. April 2026
- **Architektur:** MoE + Multi-head Latent Attention (MLA)
  - 1,04 Billionen Gesamtparameter, **32B aktiv**
- **Swarm-Skalierung:** Bis zu **300 parallele Sub-Agenten**, bis zu **4.000 koordinierte Schritte**
- **Quantisierung:** Quantization-Aware Training (QAT) → native INT4
  - VRAM-Reduktion: ~2 TB (FP16) → **~594 GB (INT4)**
  - Betrieb auf **4× NVIDIA H100 (80GB)** möglich
  - Infrastrukturkosten **halbiert** vs. FP16

---

### DeepSeek V4 Pro

- **Veröffentlicht:** 24. April 2026 | **Lizenz:** MIT
- **Architektur:** Hybride Attention (Compressed Sparse + Heavily Compressed)
  - 1,6 Billionen Gesamtparameter, **49B aktiv pro Forward Pass**
  - KV-Cache bei 1M Kontext: nur **10% vs. Vorgänger**
  - Nur **27% FLOPs** für Single-Token-Inferenz vs. V3.2
- **Training:** Muon-Optimierer, gemischtes FP4/FP8-Präzisionsformat
- **Optimiert für:** Hopper- & Blackwell-Tensor-Kerne

---

## Benchmark-Vergleich

| Benchmark | GLM-5.1 | MiniMax M3 | Kimi K2.6 | GPT-5.4 / 5.5 | Claude Opus 4.6 / 4.7 |
|---|---|---|---|---|---|
| **SWE-Bench Pro** | 58,4% | 59,0% | 58,6% | 57,7% / 58,6% | 53,4% / **64,3%** |
| **SWE-Bench Verified** | 80,2% | 80,5% | 80,2% | n/a | 80,8% / **93,9%** |
| **Terminal-Bench 2.1** | führend | 66,0% | 66,7% | 65,4% | 66,1% |
| **GPQA Diamond** | kompetitiv | niedrig (abstrakt) | 90,5% | **92,8%** | 91,3% |

> [!NOTE] Wichtige Beobachtungen
> - Chinesische Modelle zeigen **Schwächen bei abstrakter Logik** (ARC-AGI), überzeugen aber bei multimodaler Code-Generierung
> - Kimi K2.6 glänzt auf **BrowseComp** (Agentic-Benchmark) dank Swarm-Architektur
> - Die Leistungslücke zu proprietären Systemen ist **weitgehend geschlossen**

---

## Sicherheit & Datenhoheit

### Risiken chinesischer Hosted-APIs

> [!DANGER] National Intelligence Law (VR China)
> Inländische Technologiekonzerne sind gesetzlich verpflichtet, staatlichen Stellen auf Anfrage **Zugriff auf Datenbestände zu gewähren**.
>
> Betroffen bei API-Nutzung von MiniMax, DeepSeek, Moonshot AI:
> - Quellcode
> - Geschäftsberichte & Verträge
> - Interne Systemarchitekturen

### Lösung: Open-Weight + Self-Hosting

Modelle unter **MIT-Lizenz** (GLM-5.1, DeepSeek V4 Pro) können vollständig lokal betrieben werden:

- ✅ Keine Datenübertragung nach außen
- ✅ Kompatibel mit DSGVO, HIPAA, regulierten Branchen
- ✅ Geeignet für: Finanzsektor, Gesundheitswesen, öffentliche Verwaltung

---

## Strategische Handlungsempfehlungen

### Szenario 1: Agile Teams / MVP-Phase

**Empfehlung:** Ollama Cloud Pro (~$20/Monat)
- Sofortiger Zugriff auf alle Modelle
- Minimaler Betriebsaufwand
- Kalkulierbare Flatrate

### Szenario 2: Wachsendes Team mit sensiblen Daten (5–20 Entwickler)

**Empfehlung:** Dedizierte lokale Hardware
- NVIDIA RTX 5090 Workstation, **oder**
- Apple Mac Studio M4 Max (Leasing)
- Amortisierung innerhalb weniger Monate vs. teure API-Lizenzen
- Vollständige Datenhoheit

### Szenario 3: Großunternehmen / kontinuierliche Multi-Agenten-Workloads

**Empfehlung:** Private Multi-GPU-Cluster
- Kimi K2.6 (INT4) auf **4× NVIDIA H100**
- Koordination komplexer autonomer Agenten-Swarms
- Volle Compliance mit strengsten Sicherheitsvorgaben

---

## Modell-Schnellreferenz

| Modell | Parameter (aktiv) | Kontext | Lizenz | Stärke |
|---|---|---|---|---|
| GLM-5.1 | 754B (40B) | 200K–1M | MIT | Lange Agenten-Loops |
| MiniMax M3 | – | 1M | Mod. MIT | Multimodal, Desktop-Control |
| Kimi K2.6 | 1,04B (32B) | – | – | Swarm (300 Agenten) |
| DeepSeek V4 Pro | 1,6B (49B) | 1M | MIT | Effizienz, FP4/FP8 |

---

*Basierend auf einem Bericht zu Open-Weight-KI-Infrastruktur, Stand Q2 2026*
