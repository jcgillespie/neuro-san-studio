# Technology Stack

**Analysis Date:** 2026-03-27

## Overview

Neuro SAN Studio is a Python-first multi-agent orchestration workspace built around the `neuro-san` and `nsflow` packages, configured via HOCON registries and extensible coded tools. The repo mixes a server/runtime path (`run.py`, Docker) with optional app surfaces (Slack bot, Flask UI) and observability plugins (Phoenix, Langfuse).

Primary evidence:
- Runtime/deps: `requirements.txt`, `requirements-build.txt`
- Lint/test config: `pyproject.toml`, `pytest.ini`, `Makefile`
- Deployment: `deploy/Dockerfile`, `deploy/build.sh`, `deploy/run.sh`
- Runtime bootstrap/config wiring: `run.py`

## Key Components

### Languages and Runtime

- Python is the primary language across `apps/`, `coded_tools/`, `plugins/`, `servers/`, `middleware/`.
- Target lint/runtime baseline is Python 3.12 in `pyproject.toml` (`ruff target-version = "py312"`), while container images use `python:3.13-slim` in `deploy/Dockerfile`.
- Package management is `pip` + requirements files (`requirements.txt`, `requirements-build.txt`); no lockfile is present.

### Core Framework and Orchestration

- Core orchestration library: `neuro-san==0.6.42` in `requirements.txt`.
- Client/workbench flow package: `nsflow==0.6.11` in `requirements.txt`.
- Declarative network/tool setup through HOCON registries in `registries/` (for example `registries/manifest.hocon`, `registries/llm_config.hocon`).
- Runtime entrypoint and env wiring in `run.py` sets `AGENT_MANIFEST_FILE`, `AGENT_TOOL_PATH`, `AGENT_TOOLBOX_INFO_FILE`, and `MCP_SERVERS_INFO_FILE`.

### App and Protocol Surfaces

- Slack app integration via `slack_bolt` (`apps/slack/requirements.txt`, `apps/slack/main.py`).
- Flask + Socket.IO example UI in `apps/conscious_assistant/interface_flask.py`.
- MCP support via `langchain-mcp-adapters` in `requirements.txt` and MCP server config in `mcp/mcp_info.hocon`.
- A2A example server/client path under `servers/a2a/` and `coded_tools/tools/a2a_research_report/`.

### Quality and Build Tooling

- Lint/format: Ruff + Pylint in `pyproject.toml`; enforced through `Makefile` targets.
- Testing: Pytest + coverage + async/integration helpers in `requirements-build.txt`, configured in `pyproject.toml` and `pytest.ini`.

## Notable Dependencies

- `neuro-san==0.6.42` and `nsflow==0.6.11` (`requirements.txt`) for multi-agent runtime and UI flow.
- `langchain-anthropic>=1.0.0,<2.0` and `langchain-mcp-adapters>=0.1.7,<1.0` (`requirements.txt`) for provider/MCP integration.
- `python-dotenv==1.0.1` (`requirements.txt`) used by `run.py` and `apps/slack/config.py`.
- `requests`/`aiohttp` usage in coded tools (for example `coded_tools/tools/google_search.py`, `coded_tools/tools/openai_video_generation.py`).
- Optional observability stacks:
  - `langfuse==3.14.2` in `plugins/langfuse/requirements.txt`
  - Phoenix/OpenInference stack in `plugins/phoenix/requirements.txt`
- Optional app dep: `slack_bolt>=1.27.0` in `apps/slack/requirements.txt`.

## Runtime and Deployment Notes

- Local dev path: create venv and install with `make install` (`Makefile`); `run.py` loads `.env` when present.
- Container build path: `deploy/build.sh` builds `neuro-san/neuro-san-studio:${SERVICE_VERSION}` using `deploy/Dockerfile`.
- Container runtime path: `deploy/run.sh` runs container and forwards selected env vars (`OPENAI_API_KEY`, `ANTHROPIC_API_KEY`, and storage flags).
- Service defaults:
  - HTTP port `8080` from `deploy/Dockerfile` (`EXPOSE 8080`) and runner defaults in `run.py`.
  - Manifest/toolbox/mcp defaults are resolved to local repo paths in `run.py`.

## Risks and Gaps

- Version skew risk: lint target is Python 3.12 (`pyproject.toml`) while Docker runtime is Python 3.13 (`deploy/Dockerfile`), which can hide runtime-only issues.
- Secret management risk: provider credentials are expected via env vars, but `registries/llm_config.hocon` currently includes inline provider secret material and endpoint values.
- Dependency reproducibility gap: no lockfile for transitive pinning; builds can drift over time.
- Optional integration fragility: many tool networks in `registries/tools/manifest.hocon` depend on extra packages/env vars that are not part of base install.
- Integration test scope risk: default `make test` excludes integration tests (`-m "not integration"`), so external-provider breakages can pass CI if integration jobs are skipped.

---

*Stack analysis: 2026-03-27*