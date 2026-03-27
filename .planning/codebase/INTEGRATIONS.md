# External Integrations

**Analysis Date:** 2026-03-27

## Overview

Integrations are primarily environment-variable driven and activated through HOCON registry entries plus coded tools. The repository supports multiple LLM providers, optional observability backends, MCP servers, Slack, and API-backed retrieval/generation tools.

Primary integration control points:
- Provider/tool registry toggles: `registries/tools/manifest.hocon`
- LLM defaults/config vars: `registries/llm_config.hocon`
- MCP server endpoints and auth headers: `mcp/mcp_info.hocon`
- Runtime env assembly: `run.py`, `deploy/Dockerfile`, `deploy/run.sh`

## External Providers, Services, and APIs

### LLM Providers

- OpenAI
  - Used by openai-coded tools and default API-key flow.
  - Evidence: `coded_tools/openai_tool.py`, `coded_tools/tools/openai_video_generation.py`, `plugins/env_validator/env_validator.py`.
  - Config points: `OPENAI_API_KEY` in `deploy/Dockerfile`, `.env` via `run.py`, and provider requirements in `registries/tools/manifest.hocon`.

- Anthropic
  - Used by anthropic-coded tools and validation middleware.
  - Evidence: `coded_tools/anthropic_tool.py`, `plugins/env_validator/env_validator.py`, anthropic tool entries in `registries/tools/manifest.hocon`.
  - Config points: `ANTHROPIC_API_KEY` in `deploy/Dockerfile` and runtime env.

- Azure OpenAI
  - Configurable LLM backend in HOCON defaults.
  - Evidence: `registries/llm_config.hocon` (`class: "azure-openai"`, deployment/api-version fields).
  - Config points: `AZURE_OPENAI_API_KEY`, `AZURE_OPENAI_ENDPOINT` (also validated in `plugins/env_validator/env_validator.py`).

- Google (Gemini + Search)
  - Gemini and Google Search integrations are available as registry tool networks/coded tools.
  - Evidence: `registries/tools/manifest.hocon`, `coded_tools/tools/google_search.py`.
  - Config points: `GOOGLE_API_KEY`, `GOOGLE_SEARCH_API_KEY`, `GOOGLE_SEARCH_CSE_ID`, optional `GOOGLE_SEARCH_URL`, `GOOGLE_SEARCH_TIMEOUT`.

- AWS Bedrock and related AWS credentials
  - Supported as LLM/provider option in config docs and env validation.
  - Evidence: provider list in `registries/llm_config.hocon`, env checks in `plugins/env_validator/env_validator.py`.
  - Config points: `AWS_ACCESS_KEY_ID`, `AWS_SECRET_ACCESS_KEY`.

### Protocol and Agent-Ecosystem Integrations

- MCP (Model Context Protocol)
  - Client/server integration for loading remote tools.
  - Evidence: `coded_tools/agent_network_editor/get_mcp_tool.py`, `mcp/mcp_info.hocon`, `servers/mcp/bmi_server.py`.
  - Current configured server: `https://mcp.deepwiki.com/mcp` in `mcp/mcp_info.hocon`.
  - Optional auth-capable entries are shown (GitHub Copilot MCP, Google Maps MCP) in comments in `mcp/mcp_info.hocon`.

- A2A (Agent-to-Agent)
  - Example A2A server/client integration path.
  - Evidence: `servers/a2a/server.py`, `coded_tools/tools/a2a_research_report/a2a_research_report.py`, `registries/tools/manifest.hocon`.

### Application Integrations

- Slack
  - Socket mode Slack app using Neuro SAN backend API calls.
  - Evidence: `apps/slack/main.py`, `apps/slack/config.py`, `apps/slack/requirements.txt`.
  - Config points: `SLACK_BOT_TOKEN`, `SLACK_APP_TOKEN`, `NEURO_SAN_SERVER_HTTP_PORT`.

### Observability and Tracing

- Phoenix (OpenTelemetry/OpenInference)
  - Optional tracing init/autostart and instrumentation for OpenAI/Anthropic/LangChain/MCP.
  - Evidence: `plugins/phoenix/phoenix_plugin.py`, `plugins/phoenix/requirements.txt`, `servers/neuro_san/neuro_san_server_wrapper.py`.
  - Config points: `PHOENIX_ENABLED`, `PHOENIX_HOST`, `PHOENIX_PORT`, `OTEL_EXPORTER_OTLP_*`, `PHOENIX_PROJECT_NAME`.

- Langfuse
  - Optional callback/tracing integration.
  - Evidence: `plugins/langfuse/langfuse_plugin.py`, `plugins/langfuse/requirements.txt`, `servers/neuro_san/neuro_san_server_wrapper.py`.
  - Config points: `LANGFUSE_ENABLED`, `LANGFUSE_PUBLIC_KEY`, `LANGFUSE_SECRET_KEY`, `LANGFUSE_HOST`.

## Key Components

- Manifest-driven integration enable/disable: `registries/tools/manifest.hocon` toggles networks per integration.
- Env-driven runtime plumbing: `run.py` loads `.env`, then exports config to process env before startup.
- Containerized integration defaults: `deploy/Dockerfile` defines key provider env placeholders and runtime agent env vars.
- Plugin-first observability init: `servers/neuro_san/neuro_san_server_wrapper.py` initializes Phoenix/Langfuse before server loop.

## Runtime and Deployment Notes

- `.env` and `.env.example` are present at repo root; `run.py` auto-loads `.env` if available.
- Docker run script forwards only a subset of integration env vars by default (`deploy/run.sh`), so additional provider keys require explicit runtime injection.
- MCP server list can be overridden via `MCP_SERVERS_INFO_FILE` env var (`run.py`, `coded_tools/agent_network_editor/get_mcp_tool.py`).
- Many integrations are optional and disabled by default in `registries/tools/manifest.hocon`.

## Risks and Gaps

- Secret exposure risk: `registries/llm_config.hocon` contains inline credential-like provider values; this should be externalized to environment or secret manager.
- Partial env forwarding risk: `deploy/run.sh` exports only select provider variables, which can cause non-obvious failures for other enabled integrations.
- Optional dependency drift risk: plugin/tool-specific requirements are split (`plugins/*/requirements.txt`, app-specific requirements), so missing installs can break integrations at runtime.
- Integration readiness ambiguity: registry entries include many disabled integrations with extra prerequisites; enabling them requires manual package and credential setup not enforced by base install.

---

*Integration audit: 2026-03-27*