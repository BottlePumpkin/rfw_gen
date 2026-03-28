---
name: add-golden-test
description: Add golden tests for existing rfw_gen widgets. Use when the user says /add-golden-test, wants to add visual regression tests, create golden image tests for a widget, or needs to verify widget rendering output. Triggers on golden test creation requests for rfw_gen catalog widgets.
user_invocable: true
---

# Add Golden Test Skill

Add golden (visual regression) tests for existing rfw_gen widgets.

## Usage

`/add-golden-test [widgetName]`

## Steps

1. Check the widget's category from `_catalogWidgets` in `example/lib/main.dart`
2. Add a `testWidgets` block to the matching `example/test/golden_catalog_{category}_test.dart`
3. Check if the widget uses network images (HttpOverrides is already configured in `loadTestFonts()`)
4. Generate golden images:
   ```bash
   cd example && flutter test {file} --update-goldens --tags golden
   ```
5. Verify the test passes:
   ```bash
   cd example && flutter test {file} --tags golden
   ```
6. Visually inspect the generated golden image at `goldens/catalog/{category}/{widget_name}.png`
7. Commit the changes

## References

- Helper: `example/test/helpers/golden_test_helper.dart`
- Spec: `docs/superpowers/specs/2026-03-24-quality-golden-tests-design.md`
- Agent: `.claude/agents/golden-test-writer.md`
