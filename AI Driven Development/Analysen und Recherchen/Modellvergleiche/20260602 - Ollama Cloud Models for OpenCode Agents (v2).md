# Technical Report: Ollama Cloud Models for OpenCode Agents (v2)

## Infrastructure Topologies and Dynamic Offloading

The rapid evolution of autonomous developer agents requires substantial compute parameters to process multi-file context windows, coordinate tool executions, and run continuous code-repair loops. Historically, local developer workstations lacked the memory bandwidth and GPU capacity required to host frontier-grade models. The introduction of Ollama Cloud models resolves this system constraint by establishing a hybrid architecture that seamlessly blends local workstation tools with datacenter-grade hardware offloading.

Under the hybrid paradigm, the local Ollama daemon intercepts model execution requests and routes the processing load to Ollama’s cloud infrastructure. This architecture preserves user privacy and enterprise compliance by enforcing a strict zero-data-retention policy on the US-based hosting nodes. Software engineering tools can interface with these cloud resources through three primary network configurations:

- **Cloud-Only Direct Route**: Client applications bypass the local daemon entirely, establishing direct connections to the remote endpoint `https://ollama.com`. Authentication is achieved by passing the global `OLLAMA_API_KEY`token within the authorization headers of standard HTTP requests.
    
- **Cloud + Local Proxy Route**: Developer tools communicate with the standard local port (`http://localhost:11434`).The local daemon, once authenticated via `ollama signin`, identifies specific cloud model identifiers and proxies the execution payloads to the cloud cluster.
    
- **Local-Only Route**: Workstations process inference entirely within local hardware limits, using local model weights without remote network dependencies.
    

A crucial operational distinction lies in model referencing syntax depending on the routing topology. When coordinating with a signed-in local host daemon, client applications must invoke the model using a suffix identifier, such as `gpt-oss:120b-cloud` or `minimax-m3:cloud`. This suffix instructs the local host to offload the mathematical execution to the remote platform. Conversely, when establishing direct, client-to-cloud connections targeting `https://ollama.com`, the suffix is omitted, and the bare model identifier (such as `gpt-oss:120b`) is utilized in conjunction with authorization headers.

## Client Orchestration and Catalog Discovery

To leverage these high-parameter cloud models, open-source agent frameworks implement automated catalog discovery and capability assessment. Systems such as OpenClaw and Mastra orchestrate these APIs using distinct design patterns, trading static routing speed for dynamic system metadata discovery.

OpenClaw leverages native `/api/chat` and `/api/show` endpoints to construct its runtime model index. The framework executes live queries against `/api/tags`, retrieving a list of active hosted models capped at 500 entries. For signed-in environments, OpenClaw validates missing model definitions directly by querying `/api/show`. This lookup reads configuration files to determine the exact context window size (`num_ctx`), tool-calling schemas, and vision capabilities of the cloud target. If vision capabilities are reported, the framework automatically structures its prompt pipeline to inject image assets into the token stream.

OpenClaw also addresses the security challenges of multi-host networks. During remote memory database embedding lookups, bearer authentication tokens are tightly scoped to their designated destination hosts. This prevent local or self-hosted servers from intercepting global cloud tokens like the `OLLAMA_API_KEY` during agentic processing loops.

In contrast, Mastra implements a highly optimized model router using the OpenAI-compatible `/chat/completions` endpoint pointing directly to `https://ollama.com/v1`. This router bypasses local discovery to provide rapid access to up to 39 cloud-hosted models. It manages credentials globally using the `OLLAMA_API_KEY` environment variable and utilizes ternary routing files (such as `src/mastra/agents/my-agent.ts`) to dynamically toggle between models based on task complexity.

|**Runtime Feature**|**OpenClaw Integration Platform**|**Mastra Orchestration Router**|
|---|---|---|
|**Core Connection Target**|Local daemon proxy or direct `https://ollama.com` endpoints.|OpenAI-compatible `/chat/completions` at `https://ollama.com/v1`.|
|**Authentication Flow**|Session-validated local sign-in or direct token configuration.|Automated authorization mapping via the `OLLAMA_API_KEY` environment variable.|
|**Discovery Mechanism**|Live polling of `/api/tags` with metadata verification via `/api/show`.|Static path mapping across 39 available cloud models.|
|**Token Safety Boundaries**|Scopes bearer tokens strictly to their target hosts to prevent leakage during multi-host search.|Global environmental key exposure across the active router context.|
|**Multimodal Handling**|Automated image injection triggered by vision capability detection.|Standard structured schema mapping over compatible endpoints.|

## Analyzing the OpenCode-to-Cloud Socket Bottleneck

In practical software engineering deployments, developers integrating IDE tools like OpenCode with Ollama Cloud have reported recurring network failures, specifically manifesting as abrupt connection closures. This operational issue represents a significant infrastructure bottleneck that emerges when long-horizon agent loops interact with ultra-large context models, such as `minimax-m3:cloud`.

The MiniMax M3 model features a massive context window of 1 million tokens, guaranteeing a minimum of 512K tokens on the Ollama Cloud platform. When an agentic tool like OpenCode attempts to digest entire codebases, parse massive log directories, or process multi-turn troubleshooting cycles, the input payload and the resulting output stream grow extremely large.

Standard client-side HTTP libraries, proxy servers, and IDE network layers are configured with strict default TCP socket and idle timeout windows, often limited to 30 or 60 seconds. However, processing a massive token payload and executing autonomous web navigation—such as the workflows where MiniMax M3 scores 83.5 on the BrowseComp benchmark—demands extended processing times from remote datacenter nodes. During this intensive deliberation phase, the cloud service may not immediately send downstream tokens. The client-side connection layer interprets this temporary transmission silence as an inactive host, terminating the TCP socket and causing the "connection closed" errors experienced by developers.

To resolve this issue within OpenCode and allied agent configurations, systems engineers must implement three architectural changes:

- Configure aggressive TCP Keep-Alive parameters at the client transport layer to prevent intermediate network switches and firewalls from dropping idle sockets.
    
- Override default connection and read timeout values in the client HTTP client, expanding the idle socket threshold to accommodate long-running cloud deliberation steps.
    
- Implement aggressive prompt-pruning and semantic chunking strategies to minimize token payloads, ensuring that context windows contain only the files immediately relevant to the current execution step.
    

## Architectural Evaluation of Cloud-Hosted Development Models

The Ollama Cloud catalog hosts several highly specialized models optimized for software engineering, system operations, and multi-agent coordination. These models range from high-capacity Mixture-of-Experts systems to highly efficient task-execution models.

|**Model Identifier**|**Architectural Topology**|**Context Window**|**Primary Benchmark Standing**|**Core Functional Focus**|
|---|---|---|---|---|
|**`kimi-k2.6:cloud`**|1T Parameter MoE; 32B Active; 61 Layers; MLA Attention with 7168 Hidden Dimension.|256K Tokens.|80.2% SWE-Bench Verified; 86.3% BrowseComp Agent Swarm.|Swarm scaling to 300 sub-agents, 4000 coordinated steps, and visual-to-code design pipeline.|
|**`minimax-m3:cloud`**|MiniMax Sparse Attention (MSA) Architecture.|512K - 1M Tokens.|83.5 on BrowseComp (outperforming Opus 4.7 at 79.3).|Native multimodal pretraining, codebase ingestion, and autonomous web navigation.|
|**`glm-5.1:cloud`**|Flagship logical execution model.|202K Tokens.|State-of-the-art positioning on SWE-Bench Pro.|Sustains an 8-hour autonomous execution loop for continuous repo-level debugging.|
|**`minimax-m2.7:cloud`**|Collaborative Agent Optimization Series.|262K / 197K Tokens.|56.22% on SWE-Pro (matching GPT-5.3-Codex); ELO 1495.|Professional software engineering, multi-round office file editing, and 97% adherence to complex skill profiles.|
|**`minimax-m2:cloud`**|230B Total Parameter MoE; 10B Active Parameters.|205K Tokens.|69.4% SWE-Bench Verified; 36.2% Multi-SWE-Bench.|Highly cost-efficient developer workflows, terminal control, and code-run-fix cycles.|
|**`kimi-dev-72b`**|Fine-tuned logical software execution model.|128K Tokens.|60.4% on SWE-bench Verified.|Reinforcement learning optimization applying real repository patches and validating via full test suite execution.|
|**`gpt-oss:120b-cloud`**|High-parameter open cognitive foundation.|131K Tokens.|Prominent general coding and multi-step orchestration standard.|Versatile developer tasks, pipeline integration, and safety baseline evaluation.|

### Kimi K2.6: Massive Swarm Scaling and Attention Optimization

The architectural design of Kimi K2.6 is specifically optimized for long-horizon software development and high-concurrency multi-agent orchestration. It is built on a Mixture-of-Experts transformer network comprising 1 trillion total parameters, with 32 billion active parameters per forward pass across 61 layers (including 1 dense layer). The expert routing system features 384 distinct experts, with 8 experts dynamically selected per token, augmented by 1 shared expert to stabilize representation learning.

To handle the immense memory demands of its 256K token context window, Kimi K2.6 utilizes Multi-head Latent Attention (MLA). MLA compresses the key-value (KV) cache by projecting keys and values into a low-dimensional latent space. Compressing the attention hidden dimension to 7,168 dramatically reduces KV cache overhead, enabling high-concurrency swarm scaling.

Specifically, Kimi K2.6 supports scaling to 300 parallel sub-agents executing up to 4,000 coordinated steps in a single, autonomous background run. Within this swarm, the model serves as an adaptive coordinator, mapping tasks to specific agents based on their skill profiles, monitoring execution flow, and automatically reassigning tasks or regenerating subtasks upon detecting failures or stalls. Visual inputs are processed natively via the MoonViT (400M) vision encoder, enabling visual-to-code workflows that transform UI mockups into production-ready Rust, Go, or Python codebases.

Other models in this series include Kimi Dev 72B, which leverages reinforcement learning to apply code patches in real repositories and validate them via full test suite executions, scoring 60.4% on SWE-bench Verified. For lighter tasks, Moonlight-16B-A3B-Instruct activates 3B parameters per forward pass, outperforming standard models like Llama3-3B while maintaining efficient deployment footprints.

### GLM-5.1: Continuous Engineering and the 8-Hour Autonomous Loop

Designed to address the limitations of short-context, single-turn code generation, GLM-5.1 serves as a high-capacity agentic engine capable of sustaining an 8-hour autonomous execution loop. Operating over a 202K token context window, this flagship model excels at complex systems engineering, such as navigating deep codebases, parsing multi-repo dependencies, and executing test-validated code repair workflows.

On SWE-Bench Pro, GLM-5.1 achieves state-of-the-art performance by demonstrating deep understanding of multi-language environments. During long-horizon tasks, agentic pipelines often fail due to cascading logic errors. GLM-5.1 mitigates this by maintaining a rigorous state representation of the workspace and utilizing specialized tool-calling parsers to prevent structural command errors. This allows the agent to iteratively write code, execute test suites via terminal interfaces, analyze log stack traces, and apply sequential fixes until zero errors are reported. In contrast, experimental variants like `frob/glm-5.1` that lack an integrated Ollama parser struggle to parse structured tool commands, resulting in high tool-call failure rates.

### MiniMax M3 and M2.7: Sparse Attention and High-Fidelity Skill Adherence

MiniMax M3 leverages a proprietary MiniMax Sparse Attention (MSA) architecture to support a context window of up to 1M tokens, with a guaranteed minimum of 512K tokens on the Ollama Cloud platform. MSA optimizes the quadratic scaling of standard self-attention, maintaining low latency and high throughput even at extreme sequence lengths. This massive memory buffer serves as a global workspace for agentic tasks, allowing complete repositories to reside directly within the context window, bypassing the retrieval errors common in vector-database-driven architectures. The entire data pipeline has been scaled to over 100 trillion tokens, achieving deep alignment between textual and visual semantic spaces.M3 scores 83.5 on the BrowseComp benchmark, reflecting superior autonomous information retrieval and web browsing capabilities.

For structured enterprise tasks, MiniMax M2.7 demonstrates outstanding professional engineering performance, matching the capabilities of GPT-5.3-Codex on the SWE-Pro benchmark with a score of 56.22%. The model maintains a 97% skill adherence rate across 40 complex office and engineering skills, each exceeding 2,000 tokens in structural definition. This structural fidelity ensures that collaborative agent teams can perform multi-round revisions of documents, generate high-fidelity codebases, and complete system-level configurations without deviating from system instructions.

## Safe Tool Execution and Deliberative Alignment

Deploying autonomous developer agents with write access to terminal interfaces and local file systems presents severe security risks, including prompt injection vulnerabilities that can lead to malicious command execution. Traditional safety mechanisms rely on hardcoded guardrails or system-prompt constraints, which suffer from high over-refusal rates and fail to scale across complex, multi-step agent loops.

To address these vulnerabilities, OpenAI’s GPT-OSS Safeguard models implement a specialized safety evaluation framework under a permissive Apache 2.0 license. Available in both a high-capacity 120B version (117B parameters, 5.1B active) and a lightweight 20B version (21B parameters, 3.6B active) , these models are specifically fine-tuned to execute deliberative policy alignment.

|**Model Variant**|**Total Parameters**|**Active Parameters**|**Hardware VRAM Requirement**|**Policy Enforcement Mechanism**|
|---|---|---|---|---|
|**`gpt-oss-safeguard-20b`**|21 Billion.|3.6 Billion.|~16GB VRAM (Consumer-grade desktop execution).|Ingests custom policy at inference; generates step-by-step logic trace via Harmony format.|
|**`gpt-oss-safeguard-120b`**|117 Billion.|5.1 Billion.|Datacenter-grade GPU cluster allocation.|Deliberative policy evaluation across broad multi-policy categories, outperforming GPT-5 on safety benchmarks.|

Deliberative alignment allows developers to provide custom, written Markdown safety policies directly in the inference payload, rather than baking the rules into the model during pretraining. During operation, the Safeguard model ingests both the policy document and the proposed agent tool call or command, generating a structured compliance judgment alongside a complete step-by-step logical trace of its evaluation. Because the evaluation policy is provided dynamically, developers can iterate on and refine security boundaries instantly without retraining.

The lightweight 20B variant fits comfortably within a standard 16GB VRAM local GPU, making it highly suitable as a fast, synchronous, edge-based security gateway that intercepts and validates agent actions before they execute on workstation hardware. These models require the Harmony response format to ensure structured, predictable outputs. They also support configurable deliberation effort levels (low, medium, high), allowing systems architects to balance validation latency against the complexity of the evaluation task.

## Architectural Recommendations for OpenCode Implementations

The integration of Ollama Cloud models into autonomous development agents presents clear design paths for optimizing performance, scalability, and security:

First, to resolve the "connection closed" socket timeouts observed during massive context executions, systems architects should configure client-side HTTP connections with custom timeouts exceeding 300 seconds. Implementing TCP Keep-Alive signals and utilizing streaming parsers at the local daemon boundary ensures that sockets remain open during long-running cloud offloading operations.

Second, agentic platforms should leverage Mixture-of-Experts architectures like Kimi K2.6 for complex, multi-agent operations. By utilizing Multi-head Latent Attention (MLA) to compress KV cache footprints, developers can scale agent swarms to hundreds of parallel sub-agents without exhausting local workstation memory.

Third, local-to-cloud workflows must be protected using deliberative edge safety gateways. Deploying a lightweight model like `gpt-oss-safeguard-20b` on local workstation hardware allows developer tools to intercept, analyze, and validate proposed shell commands and file-system edits against dynamic, human-readable safety policies before execution, mitigating the risk of system compromise.