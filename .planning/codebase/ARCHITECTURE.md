# Architecture

**Analysis Date:** 2026-03-27

## Pattern Overview

**Overall:** Configuration-driven multi-agent orchestration with process-level adapters and plugin/middleware extension layers.

**Key Characteristics:**
- Runtime orchestration is centralized in `run.py`, which sets env, validates keys, and launches process boundaries.
- Agent behavior is declared in HOCON network files under `registries/` and resolved by the Neuro SAN runtime.
- Behavior customization is split between coded tools (`coded_tools/`), middleware (`middleware/`), and plugins (`plugins/`).

## Runtime Boundaries

**Orchestrator Process:**
- Purpose: Bootstrap and coordinate local services.
- Location: `run.py`
- Owns: env variable setup, optional key validation, process start/stop, port conflict handling.

**Core Neuro SAN Server Process:**
- Purpose: Host agent networks and execute tool/agent graph turns.
- Location: `servers/neuro_san/neuro_san_server_wrapper.py`
- Boundary: Wrapper initializes observability plugins in-process, then delegates to `neuro_san.service.main_loop.server_main_loop.ServerMainLoop` (external package runtime).

**Client Surface Processes (optional):**
- NSFlow UI backend: started from `run.py` as `uvicorn nsflow.backend.main:app`.
- Flask web client: started from `run.py` as `neuro_san_web_client.app`.
- Boundary note: both are treated as separate subprocesses controlled by `NeuroSanRunner`.

**Auxiliary App Runtimes:**
- Slack adapter: `apps/slack/main.py` (SocketMode Slack bot).
- Conscious assistant UI: `apps/conscious_assistant/interface_flask.py`.
- Cruse assistant UI: `apps/cruse/interface_flask.py`.
- Log analyzer assistant: `apps/log_analyzer/log_analyzer.py`.

## Layers

**Configuration Layer:**
- Purpose: Define what networks/tools are available and how they compose.
- Location: `registries/manifest.hocon`, `registries/*.hocon`, `toolbox/toolbox_info.hocon`, `mcp/mcp_info.hocon`
- Contains: network topology, tool declarations, includes/overlays, MCP source definitions.
- Depends on: Neuro SAN config parser/runtime.
- Used by: server runtime and coded tools (for dynamic lookup/update).

**Runtime Bootstrap Layer:**
- Purpose: Translate environment/CLI into running processes.
- Location: `run.py`, `deploy/entrypoint.sh`, `deploy/run.sh`
- Contains: process lifecycle management, signal handling, port checks, startup sequencing.
- Depends on: Python subprocess, OS signals, optional plugins.
- Used by: local development and container startup.

**Network Logic Layer:**
- Purpose: Define per-network behavior contracts and orchestration rules.
- Location: `registries/agent_network_designer.hocon` and other registry files in `registries/basic/`, `registries/tools/`, `registries/industry/`, `registries/experimental/`, `registries/generated/`
- Contains: front agent functions, tool chains, allowed sly_data flow contracts, metadata.
- Depends on: toolbox registrations and coded tool classes.
- Used by: Neuro SAN server main loop.

**Coded Tool Extension Layer:**
- Purpose: Implement concrete side-effectful or computational tools.
- Location: `coded_tools/` (especially `coded_tools/tools/`, `coded_tools/agent_network_designer/`, `coded_tools/agent_network_editor/`)
- Contains: network mutation helpers, search/RAG tools, provider adapters.
- Depends on: declared `AGENT_TOOL_PATH` and toolbox metadata.
- Used by: agent network tool invocations.

**Middleware Guardrail Layer:**
- Purpose: Intercept and shape agent loop behavior.
- Location: `middleware/agent_network_validation_middleware.py`, `middleware/agent_network_structure_validation_middleware.py`, `middleware/agent_network_instructions_validation_middleware.py`, `middleware/agent_skills_middleware.py`
- Contains: post-turn validation with model jump-back control, progressive skill loading and system-prompt injection.
- Depends on: LangChain/LangGraph middleware interfaces and Neuro SAN validators.
- Used by: agent network designer/editor flows.

**Observability and Runtime Plugin Layer:**
- Purpose: Optional tracing/logging/environment checks.
- Location: `plugins/phoenix/phoenix_plugin.py`, `plugins/langfuse/langfuse_plugin.py`, `plugins/log_bridge/process_log_bridge.py`, `plugins/env_validator/env_validator.py`
- Contains: OpenTelemetry instrumentation, process log bridging, key validation.
- Depends on: environment toggles and optional package availability.
- Used by: bootstrap layer and server wrapper.

## Data and Control Flow

**Primary Local Run Flow (`python run.py`):**
1. `run.py` loads `.env` if present, merges defaults and CLI options, then sets env variables such as `AGENT_MANIFEST_FILE`, `AGENT_TOOL_PATH`, `MCP_SERVERS_INFO_FILE`.
2. Optional API key validation runs through `plugins/env_validator/env_validator.py`.
3. Runner checks port conflicts and optionally terminates existing processes.
4. Runner starts Phoenix (optional), then UI surface (`nsflow` or Flask), then Neuro SAN server wrapper.
5. `servers/neuro_san/neuro_san_server_wrapper.py` initializes Phoenix/Langfuse and starts `ServerMainLoop`.
6. Agent requests are executed per HOCON network specs, which call toolbox or coded tools as needed.

**Slack Interaction Flow:**
1. Slack events enter via `apps/slack/main.py` and `apps/slack/event_handler.py`.
2. `ConversationManager` resolves thread-to-network mapping.
3. `NetworkHandler` routes command/text to Neuro SAN server through `APIClient`.
4. Responses are posted back to Slack thread context.

**Network Authoring Flow (Designer family):**
1. User invokes `agent_network_designer` network (`registries/agent_network_designer.hocon`).
2. Network calls editor/instructions/query sub-agents and tools (for example `persist_agent_network`, `get_agent_network_definition`).
3. Middleware validates structure/instructions after turns and may jump back to model for self-correction.
4. Persistor tool writes resulting network definition into `registries/generated/` and updates manifest references.

## Key Abstractions

**Agent Network Definition (HOCON):**
- Purpose: Canonical declarative contract for an agent network.
- Examples: `registries/agent_network_designer.hocon`, `registries/aaosa.hocon`, `registries/basic/manifest.hocon`
- Pattern: data-first orchestration; runtime reads config rather than hardcoding graph topology.

**Sly Data Channel:**
- Purpose: Pass non-chat private state between agents/tools.
- Examples: `middleware/agent_network_validation_middleware.py`, `registries/agent_network_designer.hocon`
- Pattern: explicit allowlists for downstream/upstream sly_data movement.

**Tool Registry + Tool Path:**
- Purpose: Resolve toolbox names to class implementations.
- Examples: `toolbox/toolbox_info.hocon`, `run.py` env setup (`AGENT_TOOL_PATH`), `coded_tools/tools/*`
- Pattern: indirection between declarative tool references and Python classes.

## Extension Points

**New Agent Networks:**
- Add HOCON under `registries/` (or grouped subfolder) and include/enable in `registries/manifest.hocon`.

**New Tools:**
- Implement class under `coded_tools/` and register metadata in `toolbox/toolbox_info.hocon`.

**New Middleware/Guardrails:**
- Add middleware module in `middleware/` and wire into network/runtime that consumes it.

**New Integrations:**
- Add plugin module under `plugins/` and initialize from `run.py` or `servers/neuro_san/neuro_san_server_wrapper.py` via env flags.

**New Transport Adapters:**
- Add app wrapper under `apps/` (similar to Slack/Flask assistants) that translates external I/O to Neuro SAN requests.

## Error Handling

**Strategy:** Fail fast on startup misconfiguration, continue-with-warning for optional instrumentation.

**Patterns:**
- CLI and mutually exclusive option checks in `run.py`.
- Optional plugin init wrapped with broad exception handling in `servers/neuro_san/neuro_san_server_wrapper.py`.
- Middleware-driven corrective loops via `jump_to: "model"` in `middleware/agent_network_validation_middleware.py`.
- Adapter-level exception logging in `apps/slack/event_handler.py`.

## Cross-Cutting Concerns

**Logging:**
- Runner-level process logs in `logs/*.log` via `plugins/log_bridge/process_log_bridge.py` or direct stream capture in `run.py`.

**Validation:**
- Environment/API key validation in `plugins/env_validator/env_validator.py`.
- Agent network structure and instruction validation in `middleware/*validation_middleware.py`.

**Observability:**
- Phoenix setup and SDK instrumentation in `plugins/phoenix/phoenix_plugin.py`.
- Optional Langfuse initialization from server wrapper.

## Unknowns and Assumptions

- `ServerMainLoop` internals are in the external `neuro-san` package and are treated as a black-box execution engine from this repository boundary.
- `nsflow.backend.main:app` and `neuro_san_web_client.app` are started by this repo, but their internal architecture is not present here.
- Some registry and toolbox HOCON snippets contain syntax anomalies in sampled files (for example missing commas); this document assumes runtime-validated files are the active source of truth during normal execution.
- Infrastructure in `infra/tofu/` is deployment-oriented and not part of the local runtime call graph initiated by `run.py`.

---

*Architecture analysis: 2026-03-27*