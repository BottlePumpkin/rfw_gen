# rfw_gen

A code generator that converts Flutter Widget code into RFW (Remote Flutter Widgets) format.

## Architecture

Monorepo structure:
- `packages/rfw_gen/` — Core: annotations (@RfwWidget) + conversion engine (RfwConverter) + widget mapping (WidgetRegistry)
- `packages/rfw_gen_builder/` — build_runner generator
- `packages/rfw_gen_mcp/` — MCP server for widget registry, conversion, and validation
- `packages/rfw_preview/` — Dev preview widget with live editor
- `example/` — Example app + Widgetbook debugging

## Branch Rules

- **No direct commits to main** — always merge via PR from a feature branch
- Create a branch before starting work: `git checkout -b <type>/<description>`
- Branch types: `feat`, `fix`, `docs`, `chore`, `refactor`, `test`, `release`
- Examples: `feat/error-reporting`, `fix/offset-missing`, `release/0.5.0`
- No package prefix needed (rfw_gen + rfw_gen_builder usually change together)
- `.githooks/pre-commit` blocks direct commits to main

## Release Rules

- `rfw_gen`, `rfw_gen_builder`, `rfw_gen_mcp`, `rfw_preview` versions must always stay in sync
- Follow semver: breaking change → major, new feature → minor, bug fix → patch
- Release process: `release/x.y.z` branch → CHANGELOG + version bump → PR → main → tag → pub.dev
- Hotfixes also use `release/x.y.z` branches (patch version)

## Development Rules

- Adding a widget mapping requires unit + integration + golden tests
- rfwtxt output must be validated with `parseLibraryFile()`
- Unsupported patterns must produce build-time errors + suggest alternatives
- `@RfwWidget` is only allowed on top-level functions
- Golden images are generated/updated only on Linux CI
- Run golden tests separately: `flutter test --tags golden`
- Golden test infrastructure: example/test/helpers/golden_test_helper.dart

## Commands

- `melos bootstrap` — install package dependencies
- `melos run test --no-select` — run all tests across packages
- `melos run analyze --no-select` — static analysis across packages
- `melos run format --no-select` — format all packages
- `melos run format:check --no-select` — check format without modifying
- `melos run test:golden --no-select` — run golden tests in example
- `melos run test:all --no-select` — run all tests including golden

## References

- @rules/rfw-syntax.md: rfwtxt syntax
- @rules/rfw-widgets.md: widget list + parameters
- @rules/rfw-types.md: argument type encoding
- @agents/golden-test-writer.md: golden test writing agent
- @skills/add-golden-test.md: golden test addition skill
- @skills/dogfood.md: dogfood DX 테스트 스킬
- @skills/commit.md: 커밋 스킬
- @skills/git-workflow.md: git worktree 워크플로우 스킬
- @skills/rfw-contribute.md: RFW upstream 기여 스킬
- @skills/release.md: 릴리즈 스킬 (버전 범프, CHANGELOG, PR, 태그)
