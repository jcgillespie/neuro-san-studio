# Coding Conventions

**Analysis Date:** 2026-03-27

## Naming Patterns

**Files:**
- Use `snake_case.py` for Python modules and `test_*.py` for pytest-discovered tests (see `coded_tools/basic/accountant.py`, `tests/coded_tools/basic/test_accountant.py`).
- Use descriptive suffixes for special-purpose scripts that are executed directly (for example `integration_test_full_workflow_e2e.py` in `tests/coded_tools/tools/now_agents/integration_tests/`).

**Functions:**
- Use `snake_case` for functions and methods, including async methods (for example `async_invoke`, `load_environment`, `run_hocon_group_fail_fast_case`).
- Keep helper methods prefixed with `_` for internal behavior (for example `_get_env_variable` in `coded_tools/tools/now_agents/nowagent_api_get_agents.py`).

**Variables:**
- Use `snake_case` for local variables and parameters.
- Use uppercase names for module-level constants (for example `MOCK_AGENTS_RESPONSE`, `INSTANCE_URL`).

**Types:**
- Use `PascalCase` for classes (for example `NeuroSanRunner`, `NowAgentAPIGetAgents`, `FailFastParamMixin`).
- Prefer explicit typing from `typing` for dict-like payloads (`Dict[str, Any]`, `Union[...]`) in tool and runner code.

## Code Style

**Formatting:**
- Tool used: `ruff` (`pyproject.toml`, `[tool.ruff]`).
- Key settings:
  - Line length: `119`
  - Target version: `py312`
  - Source roots: `apps`, `coded_tools`, `plugins`, `tests`
- Apply both import sorting and formatting via Make targets in `Makefile`:
  - `ruff check --select I --fix`
  - `ruff format`

**Linting:**
- Tools used: `ruff` + `pylint` (`pyproject.toml`, `Makefile`).
- Key rules:
  - Ruff checks enabled: `E`, `F`, `I`, `W`
  - Pylint naming style enforces snake_case/PascalCase conventions
  - Pylint quality gate uses `fail-under = 10.0`
- Markdown linting is also part of quality checks via `pymarkdown` with `.pymarkdownlint.yaml`.

## Import Organization

**Order:**
1. Standard library imports
2. Third-party imports
3. First-party/project imports

**Path Aliases:**
- No alias system detected.
- Use direct module paths (for example `from coded_tools.tools.now_agents.nowagent_api_get_agents import NowAgentAPIGetAgents`).
- Runtime import resolution relies on `PYTHONPATH` initialization in `run.py` and test commands in `Makefile`.

## Error Handling

**Patterns:**
- For coded tools that wrap external APIs, return structured error payloads instead of raising immediately (for example `{"result": [], "error": ..., "status_code": ...}` in `coded_tools/tools/now_agents/nowagent_api_get_agents.py`).
- For script-style integration diagnostics, catch and print actionable errors, then return status booleans or exit codes (for example `tests/coded_tools/tools/now_agents/integration_tests/integration_test_full_workflow_e2e.py`).
- If broad exceptions are needed in diagnostic scripts, pair with explicit pylint suppressions and user-facing context.

## Logging

**Framework:**
- Python `logging` module (`logging.getLogger(...)`, `logger.debug(...)`, `logger.warning(...)`).

**Patterns:**
- Log call boundaries and high-level state changes in tools (`========== Calling ... ==========` patterns).
- Never log secret values; log only presence/absence of env vars (documented and implemented in `coded_tools/tools/now_agents/nowagent_api_get_agents.py`).
- Use direct `print(...)` in CLI/bootstrap scripts when immediate user feedback is expected (`run.py`).

## Comments

**When to Comment:**
- Add comments for non-obvious control flow (for example fail-fast parameterized grouping in `tests/utils/fail_fast_param_mixin.py`).
- Keep legal/copyright header and license block at top of source/test files.

**JSDoc/TSDoc:**
- Not applicable in this Python-focused codebase.
- Python docstrings are used extensively on classes and methods (see `run.py`, `coded_tools/basic/accountant.py`, `tests/integration/test_integration_test_hocons.py`).

## Function Design

**Size:**
- Keep coded-tool methods focused on one action (validate/load inputs -> call dependency -> normalize output), as seen in `coded_tools/tools/now_agents/nowagent_api_get_agents.py`.
- Split script workflows into small helper functions (`load_environment`, `test_basic_connectivity`, `test_agent_discovery`, etc.).

**Parameters:**
- Tool interfaces consistently accept `args` and `sly_data` dictionaries.
- Integration scripts pass simple scalar arguments and build payload dicts near call sites.

**Return Values:**
- Coded tools commonly return dict payloads for both success and failure paths.
- Test methods assert explicit values and response structure rather than truthy/falsy behavior.

## Module Design

**Exports:**
- Use direct imports from concrete modules; no centralized export/barrel module pattern is evident in Python packages.
- Keep one primary class or cohesive utility per module in `coded_tools/` and `tests/`.

**Barrel Files:**
- Not used as a pattern for Python modules in this repository.

## Actionable Quality Guidance

- Keep Ruff import style compliant with single-line imports (`force-single-line = true`), even when importing many names from the same module.
- Follow `snake_case` for methods/variables and `PascalCase` for classes to satisfy both convention and pylint naming gates.
- Add docstrings to new classes/functions to stay aligned with contributor guidance in `docs/dev_guide.md`.
- For new external-integration tools, return structured error dicts and avoid leaking credentials in logs.

---

*Convention analysis: 2026-03-27*
