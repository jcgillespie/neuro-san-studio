# Codebase Structure

**Analysis Date:** 2026-03-27

## Directory Layout

```text
neuro-san-studio/
├── apps/                  # User-facing adapters and assistant interfaces
├── coded_tools/           # Python tool implementations referenced by toolbox/HOCON
├── middleware/            # Agent loop guardrails and validation middleware
├── plugins/               # Optional runtime plugins (observability, auth, logging, env validation)
├── registries/            # Agent network HOCON definitions and manifests
├── servers/               # Server wrappers and protocol examples (neuro_san, A2A, MCP)
├── toolbox/               # Toolbox metadata mapping names to tool classes
├── tests/                 # Unit/integration tests and fixtures
├── docs/                  # User/dev documentation and examples
├── deploy/                # Docker and startup scripts
├── infra/tofu/            # OpenTofu infrastructure definitions
├── mcp/                   # MCP server connection definitions
├── logs/                  # Runtime logs and thinking artifacts
└── run.py                 # Main local orchestrator entrypoint
```

## Directory Purposes

**`apps/`:**
- Purpose: Thin adapters from external interfaces to Neuro SAN sessions or server APIs.
- Contains: Slack bot modules, Flask + SocketIO UIs, log analysis helper app.
- Key files: `apps/slack/main.py`, `apps/conscious_assistant/interface_flask.py`, `apps/cruse/interface_flask.py`, `apps/log_analyzer/log_analyzer.py`.

**`coded_tools/`:**
- Purpose: Executable tool implementations used by agent networks.
- Contains: generic tools (`coded_tools/tools/`), network designer/editor helpers, domain-specific examples (`basic/`, `industry/`, `experimental/`).
- Key files: `coded_tools/get_agent_network_definition.py`, `coded_tools/agent_network_designer/persist_agent_network.py`, `coded_tools/agent_network_editor/*.py`.

**`middleware/`:**
- Purpose: Agent middleware for validation and skill-loading behaviors.
- Contains: structure/instruction validators and skills progressive-disclosure middleware.
- Key files: `middleware/agent_network_validation_middleware.py`, `middleware/agent_skills_middleware.py`.

**`plugins/`:**
- Purpose: Optional runtime modules wired by env flags/startup path.
- Contains: Phoenix, Langfuse, log bridge, environment key validation, authorization providers.
- Key files: `plugins/phoenix/phoenix_plugin.py`, `plugins/log_bridge/process_log_bridge.py`, `plugins/env_validator/env_validator.py`.

**`registries/`:**
- Purpose: Declarative network inventory and grouped manifests.
- Contains: root `manifest.hocon`, per-family manifests (`basic/`, `tools/`, `industry/`, `experimental/`, `generated/`), core network files.
- Key files: `registries/manifest.hocon`, `registries/agent_network_designer.hocon`, `registries/llm_config.hocon`.

**`servers/`:**
- Purpose: Server wrappers and protocol adapters.
- Contains: Neuro SAN wrapper, A2A example server, MCP example server.
- Key files: `servers/neuro_san/neuro_san_server_wrapper.py`, `servers/a2a/server.py`, `servers/mcp/bmi_server.py`.

**`toolbox/`:**
- Purpose: Metadata registry for available base/coded tools.
- Contains: default toolbox and designer-specific toolbox definitions.
- Key files: `toolbox/toolbox_info.hocon`, `toolbox/agent_network_designer_toolbox_info.hocon`.

**`deploy/`:**
- Purpose: Containerization and deployment startup wiring.
- Contains: multi-stage Dockerfile and startup scripts.
- Key files: `deploy/Dockerfile`, `deploy/entrypoint.sh`, `deploy/run.sh`, `deploy/build.sh`.

**`infra/tofu/`:**
- Purpose: Infrastructure-as-code for environment provisioning.
- Contains: OpenTofu state/config/scripts and provider artifacts.
- Key files: `infra/tofu/*.tf`, `infra/tofu/scripts/`.

**`tests/`:**
- Purpose: Repository test suite and fixtures.
- Contains: tests for apps/coded tools/integration plus HOCON fixtures.
- Key files: `tests/integration/test_integration_test_hocons.py`, `tests/coded_tools/**`, `tests/fixtures/**`.

## Key File Locations

**Entry Points:**
- `run.py`: Primary local runtime orchestrator for server/client subprocesses.
- `apps/slack/main.py`: Slack bot process entrypoint.
- `apps/conscious_assistant/interface_flask.py`: Conscious assistant Flask/SocketIO entrypoint.
- `apps/cruse/interface_flask.py`: Cruse assistant Flask/SocketIO entrypoint.
- `servers/a2a/server.py`: Example A2A server entrypoint.
- `servers/mcp/bmi_server.py`: Example MCP tool server entrypoint.

**Configuration:**
- `registries/manifest.hocon`: Root network manifest and includes.
- `registries/llm_config.hocon`: Shared model configuration for registry networks.
- `toolbox/toolbox_info.hocon`: Tool definitions and class bindings.
- `mcp/mcp_info.hocon`: Remote MCP servers and tool filters.
- `pyproject.toml`: lint/test/tooling settings.
- `pytest.ini`: pytest marker and ignore configuration.

**Core Logic:**
- `servers/neuro_san/neuro_san_server_wrapper.py`: Plugin-aware server handoff.
- `middleware/agent_network_validation_middleware.py`: validation hook abstraction.
- `middleware/agent_skills_middleware.py`: skills discovery/injection/resource loading.
- `coded_tools/agent_network_designer/`: network assembly/persistence flow.
- `coded_tools/agent_network_editor/`: graph mutation and inspection tools.

**Testing:**
- `tests/coded_tools/`: tool-focused unit/integration coverage.
- `tests/integration/`: cross-component integration tests.
- `tests/fixtures/`: reusable HOCON and fixture scenarios.

## Naming Conventions

**Files:**
- Python modules use snake_case filenames (example: `agent_network_structure_validation_middleware.py`).
- HOCON network descriptors use `.hocon` with snake_case or grouped paths (example: `agent_network_designer.hocon`, `basic/music_nerd.hocon`).

**Directories:**
- Responsibility-based grouping by domain or runtime role (example: `coded_tools/industry/`, `registries/experimental/`, `plugins/authorization/`).

## Where to Add New Code

**New Feature (agent-driven behavior):**
- Primary code: implement tools in `coded_tools/` and expose in `toolbox/toolbox_info.hocon`.
- Network wiring: add/update HOCON in `registries/` and enable in `registries/manifest.hocon`.
- Tests: add behavior tests in `tests/coded_tools/` and fixture data in `tests/fixtures/`.

**New Component/Module:**
- Runtime adapter (new UI/channel): place in `apps/<channel_or_feature>/` with explicit entrypoint file.
- Middleware guardrail: place in `middleware/` and integrate through network/runtime config.
- Runtime plugin: place in `plugins/<plugin_name>/` and initialize from `run.py` or server wrapper.

**Utilities:**
- Shared helper logic for tool execution should live under the nearest cohesive tool domain inside `coded_tools/`.
- Cross-cutting launch/deployment helpers belong in `deploy/` (runtime scripts) or `build_scripts/` (repo build utilities).

## Runtime and Project Boundaries

**Local Runtime Boundary:**
- `run.py` orchestrates local process startup and uses project-root-relative defaults for manifest/toolbox/mcp files.

**Container Runtime Boundary:**
- `deploy/Dockerfile` sets container env defaults and starts Neuro SAN server loop through `deploy/entrypoint.sh`.

**Protocol Examples Boundary:**
- `servers/a2a/` and `servers/mcp/` are standalone protocol examples; they are not required for default `run.py` startup.

## Important Config Locations

- `logging.hocon`: root logging configuration used by local runner paths.
- `deploy/logging.hocon`: container logging config referenced by `AGENT_SERVICE_LOG_JSON`.
- `registries/manifest_multiuser_overlay.hocon`: overlay for multi-user serving constraints.
- `registries/generated/manifest.hocon`: generated network registrations.
- `toolbox/agent_network_designer_toolbox_info.hocon`: designer-focused toolbox metadata.

## Special Directories

**`.planning/codebase/`:**
- Purpose: Generated mapping documents for GSD planning/execution.
- Generated: Yes.
- Committed: repository-dependent; currently present in workspace.

**`logs/`:**
- Purpose: Runtime process logs and agent thinking artifacts.
- Generated: Yes.
- Committed: generally no for log artifacts.

**`registries/generated/`:**
- Purpose: Persisted generated agent network configs.
- Generated: Yes (by network designer tool flow).
- Committed: expected when generated networks should be shared.

## Unknowns and Assumptions

- `nsflow.backend.main:app` and `neuro_san_web_client.app` modules are referenced as runnable surfaces but their source trees are not part of this repository layout.
- The Neuro SAN core implementation (`neuro_san.*`) is a dependency package boundary; this structure document covers only integration points visible in this repo.
- `infra/tofu/.terraform/` provider directories are local tool artifacts and not authored project source.

---

*Structure analysis: 2026-03-27*