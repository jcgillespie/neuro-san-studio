# Codebase Concerns

**Analysis Date:** 2026-03-27

## Tech Debt

**Cross-cutting error handling (silent failure paths):**
- Issue: Broad exception handling with `pass` or `None` fallback masks production failures and complicates incident triage.
- Files: `plugins/log_bridge/process_log_bridge.py`, `middleware/agent_skills_middleware.py`, `plugins/phoenix/phoenix_plugin.py`, `run.py`
- Severity: High
- Likelihood: High
- Impact: Data loss in logs, suppressed operational faults, hard-to-debug non-deterministic behavior.
- Fix approach: Replace broad catches with typed exceptions, emit structured error events with correlation IDs, and fail fast on initialization-critical paths.
- Follow-up investigations:
  - Instrument counters for swallowed exceptions in `plugins/log_bridge/process_log_bridge.py`.
  - Add regression tests for error paths in `middleware/agent_skills_middleware.py` and `plugins/phoenix/phoenix_plugin.py`.

**Large, multipurpose modules (high change blast radius):**
- Issue: Single files aggregate orchestration, process lifecycle, and I/O behaviors.
- Files: `plugins/log_bridge/process_log_bridge.py` (~722 LOC), `middleware/agent_skills_middleware.py` (~667 LOC), `apps/wwaw/build_wwaw.py` (~650 LOC), `run.py` (~602 LOC)
- Severity: Medium
- Likelihood: High
- Impact: Higher regression risk and slower onboarding due to implicit coupling.
- Fix approach: Extract bounded submodules (process management, parsing, transport, formatting) and add contract tests before refactor.
- Follow-up investigations:
  - Generate dependency/call graph for `run.py` and `plugins/log_bridge/process_log_bridge.py` before decomposition.

**Configuration fragmentation for test tooling:**
- Issue: Test options exist in both `pytest.ini` and `pyproject.toml`, increasing risk of drift and confusion.
- Files: `pytest.ini`, `pyproject.toml`
- Severity: Medium
- Likelihood: Medium
- Impact: Inconsistent local vs CI behavior and subtle marker/config mismatch.
- Fix approach: Consolidate pytest configuration into a single source of truth and enforce via CI check.
- Follow-up investigations:
  - Compare effective `pytest --help`/`pytest --markers` outputs in CI and local env to detect drift.

## Known Bugs

**Google API key format validator is logically permissive:**
- Symptoms: Invalid short keys containing `-` or `_` can pass tier-2 format checks.
- Files: `plugins/env_validator/env_validator.py`
- Severity: High
- Likelihood: High
- Trigger: Expression precedence in `GOOGLE_API_KEY` validator allows `( "-" in v or "_" in v )` to satisfy validation regardless of length.
- Workaround: Rely on tier-3 live validation (`--validate-keys 3`) when possible.
- Fix approach: Parenthesize conditions: `len(v) >= 20 and (v.isalnum() or "-" in v or "_" in v)` and add unit tests for short-key false positives.

## Security Considerations

**Remote skill content supply-chain and prompt-injection surface:**
- Risk: `SKILL.md` and referenced remote resources can influence model behavior; trusted-source boundary is path-prefix based, not content integrity based.
- Files: `middleware/agent_skills_middleware.py`
- Severity: Critical
- Likelihood: Medium
- Current mitigation: URL/path allowlisting to configured skill sources and local path resolution checks.
- Recommendations: Require HTTPS for remote skill sources, add checksum/signature verification, and enforce allowlisted domains with immutable refs.
- Follow-up investigations:
  - Audit all configured skill sources from runtime configs (`registries/*.hocon`, runtime env) for trust level and ownership.

**Potential sensitive data exposure in logs/console:**
- Risk: Extensive debug/print output and raw process log mirroring can leak request/user metadata and operational internals.
- Files: `plugins/log_bridge/process_log_bridge.py`, `run.py`, `plugins/phoenix/phoenix_plugin.py`, `plugins/langfuse/langfuse_plugin.py`
- Severity: High
- Likelihood: Medium
- Current mitigation: Some key masking exists in env validation output.
- Recommendations: Centralize redaction for secrets/PII, reduce stdout `print` in favor of structured logging, and classify log fields.
- Follow-up investigations:
  - Run synthetic-secret canary tests through startup and log bridge paths to verify redaction efficacy.

**Insecure default process/user posture in container image:**
- Risk: Container user password is set to a static value (`pw`), creating avoidable hardening risk if shell access is enabled.
- Files: `deploy/Dockerfile`
- Severity: Medium
- Likelihood: Medium
- Current mitigation: Non-root user is used for runtime.
- Recommendations: Remove password assignment entirely, disable interactive login where not needed, and document runtime hardening baseline.

## Performance Bottlenecks

**Synchronous external calls in latency-sensitive paths:**
- Problem: Multiple tools/apps use blocking HTTP calls and long timeouts, which can stall worker throughput under network degradation.
- Files: `apps/slack/api_client.py`, `apps/slack/network_handler.py`, `coded_tools/tools/agentforce/agentforce_adapter.py`, `coded_tools/tools/brave_search.py`, `coded_tools/tools/google_search.py`
- Severity: Medium
- Likelihood: Medium
- Cause: Blocking requests in request-processing paths with limited circuit-breaker/retry strategy.
- Improvement path: Introduce bounded retries with backoff, explicit timeout tiers, and async/non-blocking clients where throughput matters.
- Follow-up investigations:
  - Capture p95/p99 latency for Slack message handling and identify blocking call contributions.

**Heavy log parsing/pretty-printing in bridge loop:**
- Problem: Rich formatting plus traceback normalization and JSON reconstruction run per-line in streaming threads.
- Files: `plugins/log_bridge/process_log_bridge.py`
- Severity: Medium
- Likelihood: Medium
- Cause: CPU-heavy parsing and formatting in hot path.
- Improvement path: Add backpressure-safe queue, move heavy formatting to worker pool, and add fast path for plain lines.

## Fragile Areas

**Process lifecycle management and hard kills:**
- Files: `run.py`, `plugins/phoenix/phoenix_plugin.py`
- Why fragile: Startup/shutdown and port-conflict logic spans interactive prompts, subprocess groups, and forced `SIGKILL` paths.
- Severity: High
- Likelihood: Medium
- Safe modification: Add integration tests around startup conflict handling and graceful shutdown ordering before modifying kill/restart logic.
- Test coverage: No direct tests found for `run.py` and `plugins/phoenix/phoenix_plugin.py` under `tests/`.

**Skill loading and prompt injection of dynamic content:**
- Files: `middleware/agent_skills_middleware.py`
- Why fragile: Runtime behavior depends on mutable external/local `SKILL.md` contents and auxiliary resources.
- Severity: High
- Likelihood: Medium
- Safe modification: Introduce immutable skill manifests and deterministic cache semantics; add policy tests for allowed/denied sources.
- Test coverage: No direct tests found for `middleware/agent_skills_middleware.py` under `tests/`.

## Scaling Limits

**Test coverage breadth vs source footprint:**
- Current capacity: ~75 test files for ~221 source files in `apps/`, `coded_tools/`, `plugins/`, `middleware/`, `servers/`.
- Limit: High-growth modules can outpace tests, increasing defect escape probability.
- Severity: Medium
- Likelihood: High
- Scaling path: Add risk-based coverage goals per hotspot module, and enforce minimum new-test requirements for changed high-risk files.

**Operational coupling to localhost endpoints and local process model:**
- Current capacity: Several integrations assume localhost and single-host process orchestration.
- Files: `apps/slack/api_client.py`, `plugins/phoenix/phoenix_plugin.py`, `run.py`
- Limit: Multi-host/containerized distributed topologies require explicit service discovery, health orchestration, and secure transport.
- Scaling path: Externalize endpoints and health orchestration contracts; define deployment profiles for local vs distributed modes.

## Dependencies at Risk

**Unpinned or loosely pinned runtime dependencies:**
- Risk: Version drift can introduce breaking behavior or security regressions between builds.
- Files: `requirements.txt`
- Severity: Medium
- Likelihood: Medium
- Impact: Non-reproducible environments and intermittent runtime failures.
- Migration plan: Pin critical runtime packages with compatible ranges + lockfile process; add periodic dependency audit.

**Dynamic optional instrumentation dependencies:**
- Risk: Runtime auto-install/import behavior for instrumentation can fail variably by environment.
- Files: `plugins/phoenix/phoenix_plugin.py`
- Severity: Medium
- Likelihood: Medium
- Impact: Inconsistent observability and hidden production blind spots.
- Migration plan: Declare explicit optional extras and validate availability at startup with clear status health output.

## Missing Critical Features

**No explicit security policy enforcement for runtime config sources:**
- Problem: There is no centralized enforcement layer for trusted remote skill source policies or integrity constraints.
- Files: `middleware/agent_skills_middleware.py`, `registries/`, `mcp/`
- Blocks: Hard guarantees around safe dynamic skill ingestion.

**No documented SLO/error-budget instrumentation for core orchestration paths:**
- Problem: Core startup/process lifecycle and skill-loading reliability lacks explicit SLO monitoring definitions.
- Files: `run.py`, `plugins/log_bridge/process_log_bridge.py`, `middleware/agent_skills_middleware.py`
- Blocks: Measurable reliability governance and proactive operations.

## Test Coverage Gaps

**Startup/process orchestration paths are under-tested:**
- What's not tested: Port conflict remediation, kill/restart behavior, signal handling, graceful teardown ordering.
- Files: `run.py`, `plugins/phoenix/phoenix_plugin.py`
- Risk: Platform-specific regressions and shutdown data loss.
- Priority: High
- Follow-up investigations: Add Linux/macOS matrix integration tests for process and signal semantics.

**Log bridge correctness under malformed/partial streams:**
- What's not tested: Brace-balanced multiline JSON reconstruction, traceback normalization edge cases, tee write failures.
- Files: `plugins/log_bridge/process_log_bridge.py`
- Risk: Dropped/misclassified logs during incidents.
- Priority: High
- Follow-up investigations: Add fuzz and property-style tests for parser robustness.

**Skill middleware trust and boundary tests:**
- What's not tested: URL allowlist edge cases, remote content tampering, context-injection behavior under `keep_skill_in_context` modes.
- Files: `middleware/agent_skills_middleware.py`
- Risk: Security bypass and deterministic behavior drift.
- Priority: High
- Follow-up investigations: Build security-focused unit/integration suite with malicious fixture skills.

## Unknowns

**Unverified runtime trust boundaries for skill sources and MCP endpoints:**
- Unknown: Which environments permit external/untrusted skill URLs and how those are governed.
- Files: `middleware/agent_skills_middleware.py`, `mcp/mcp_info.hocon`, `registries/*.hocon`
- Severity if misconfigured: Critical
- Investigation: Inventory production/staging configs and map ownership/approval flow.

**Unverified production log retention/redaction policy:**
- Unknown: Whether current logs include sensitive user/request payloads under real workloads and how long they persist.
- Files: `logging.hocon`, `deploy/logging.hocon`, `plugins/log_bridge/process_log_bridge.py`
- Severity if unmitigated: High
- Investigation: Perform red-team style log review with synthetic secrets and PII labels.

---

*Concerns audit: 2026-03-27*
