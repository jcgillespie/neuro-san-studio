# Testing Patterns

**Analysis Date:** 2026-03-27

## Test Framework

**Runner:**
- `pytest` `8.3.3` (`requirements-build.txt`).
- Config: `pytest.ini` (active pytest config in repo root) and additional pytest settings in `pyproject.toml` under `[tool.pytest.ini_options]`.

**Assertion Library:**
- Primary style uses `unittest.TestCase` assertions (`self.assertEqual`, `self.assertTrue`, `self.assertDictEqual`) while executed by pytest.

**Run Commands:**
```bash
make test                                           # Lint + unit-focused pytest run (excludes integration marker)
python -m pytest tests/ -v --cov=coded_tools,run.py -m "not integration"  # Unit/default suite
pytest -s -m "integration" --timer-top-n 100        # Integration-marked suite
```

## Test File Organization

**Location:**
- Centralized under `tests/`.
- Hybrid organization:
  - Repo-wide integration matrix: `tests/integration/test_integration_test_hocons.py`
  - Feature/domain unit tests: `tests/coded_tools/**/test_*.py`
  - Service-specific manual integration scripts: `tests/coded_tools/tools/now_agents/integration_tests/`

**Naming:**
- Pytest-discovered test files follow `test_*.py` (configured in both `pytest.ini`/`pyproject.toml`).
- Some integration scripts are named `integration_test_*.py` and are typically executed directly (for example `tests/coded_tools/tools/now_agents/integration_tests/integration_test_full_workflow_e2e.py`).

**Structure:**
```
tests/
├── integration/
│   └── test_integration_test_hocons.py
├── fixtures/
│   ├── basic/
│   ├── industry/
│   └── experimental/
├── coded_tools/
│   ├── basic/
│   ├── tools/agentforce/
│   └── tools/now_agents/
│       ├── unit_tests/
│       └── integration_tests/
└── utils/
    └── fail_fast_param_mixin.py
```

## Test Structure

**Suite Organization:**
```python
class TestIntegrationTestHocons(TestCase, FailFastParamMixin):
    DYNAMIC = DynamicHoconUnitTests(__file__, path_to_basis="../fixtures")

    @parameterized.expand(DynamicHoconUnitTests.from_hocon_list([...]), skip_on_empty=True)
    @pytest.mark.integration
    @pytest.mark.integration_basic
    def test_hocon_basic(self, test_name: str, test_hocon: str):
        self.DYNAMIC.one_test_hocon(self, test_name, test_hocon)
```

**Patterns:**
- Setup pattern: class-level helper objects and `setUp` methods for per-test initialization (`tests/coded_tools/tools/now_agents/unit_tests/test_unit_agent_discovery_mocked.py`).
- Teardown pattern: usually implicit; explicit cleanup where session state is external (for example `close_session(...)` in `tests/coded_tools/tools/agentforce/test_agentforce_api.py`).
- Assertion pattern: explicit field/value assertions and response-shape checks; minimal snapshot-style testing.

## Mocking

**Framework:**
- `unittest.mock` (`patch`, `patch.dict`, `Mock`) with pytest runner.

**Patterns:**
```python
@patch.dict(os.environ, {...})
@patch("coded_tools.tools.now_agents.nowagent_api_get_agents.requests.get")
def test_invoke_success(self, mock_get):
    mock_response = Mock()
    mock_response.status_code = 200
    mock_response.json.return_value = MOCK_AGENTS_RESPONSE
    mock_get.return_value = mock_response
```

**What to Mock:**
- External HTTP calls (`requests.get`, `requests.post`).
- Environment variables and logging side effects.
- Delay/polling calls (`time.sleep`) in retry paths.

**What NOT to Mock:**
- Data-driven HOCON integration flows in `tests/integration/test_integration_test_hocons.py`, where end-to-end behavior is the purpose.

## Fixtures and Factories

**Test Data:**
```python
@parameterized.expand(
    DynamicHoconUnitTests.from_hocon_list([
        "industry/airline_policy/basic_eco_carryon_baggage.hocon",
        "industry/airline_policy/general_baggage_tracker.hocon",
    ])
)
def test_hocon_industry_airline_policy(self, test_name: str, test_hocon: str):
    self.DYNAMIC.one_test_hocon(self, test_name, test_hocon)
```

**Location:**
- Scenario fixtures are file-based HOCON assets in `tests/fixtures/**`.
- No shared `conftest.py` or reusable `@pytest.fixture` blocks were detected; fixture strategy is predominantly data files + in-test setup.

## Coverage

**Requirements:**
- Coverage is collected by default in pytest config (`pyproject.toml` addopts includes `--cov=. --cov-report=term-missing --no-cov-on-fail`).
- `make test` uses `--cov=coded_tools,run.py` for a narrower practical scope.
- No global fail-under threshold is enforced in repository-level pytest config.

**View Coverage:**
```bash
python -m pytest tests/ -v --cov=coded_tools,run.py -m "not integration"
python -m pytest tests/coded_tools/tools/now_agents/unit_tests/ --cov=coded_tools.tools.now_agents --cov-report=term-missing
```

## Test Types

**Unit Tests:**
- Located primarily in `tests/coded_tools/**/test_*.py`.
- Validate deterministic business logic and adapter behavior with mocks and direct assertions.

**Integration Tests:**
- Marker-based, data-driven integration suite in `tests/integration/test_integration_test_hocons.py`.
- Marker taxonomy includes `integration_basic`, `integration_industry`, `integration_experimental`, and scenario-specific markers.

**E2E Tests:**
- E2E-style cases exist inside the integration HOCON suite via marker `integration_basic_coffee_finder_advanced_e2e`.
- Additional ServiceNow end-to-end workflow script exists at `tests/coded_tools/tools/now_agents/integration_tests/integration_test_full_workflow_e2e.py` and is run directly.

## Common Patterns

**Async Testing:**
```python
@pytest.mark.asyncio
async def test_async_invoke(self):
    result = asyncio.run(tool.async_invoke(args, sly_data))
    self.assertEqual(expected, result)
```

**Error Testing:**
```python
result = self.tool.invoke(self.test_args, self.test_sly_data)
self.assertIn("error", result)
self.assertEqual(result["status_code"], 401)
self.assertEqual(result["result"], [])
```

## Observed Gaps (Actionable)

- **Pytest configuration drift:** pytest options exist in both `pytest.ini` and `pyproject.toml` with different marker declarations. Consolidate to one source of truth to avoid confusion about active markers and addopts.
- **Discovery mismatch for integration scripts:** files under `tests/coded_tools/tools/now_agents/integration_tests/` use `integration_test_*.py`, which does not match the configured discovery pattern `test_*.py`. Either rename to `test_integration_*.py` or explicitly document/direct-run them as non-pytest-suite diagnostics.
- **Fixture reuse gap:** no shared pytest fixtures (`conftest.py`) detected, leading to repeated environment setup and mocks across files. Introduce scoped fixtures for env payloads, mock responses, and tool construction.
- **Coverage policy gap:** coverage is reported but no repository-wide minimum threshold is enforced. Add `--cov-fail-under=<target>` in CI or pytest config to prevent silent regression.
- **Inconsistent execution path for e2e/integration:** `make test` excludes all `integration` marker tests by design and no default make target runs both unit + integration gates. Add a CI/developer target such as `make test-all` that runs both suites with explicit prerequisites.

---

*Testing analysis: 2026-03-27*
