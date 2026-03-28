---
name: add-widget
description: Add a new widget mapping to rfw_gen's WidgetRegistry with full test coverage. Use when the user says /add-widget, wants to support a new Flutter widget in RFW conversion, add widget mapping, or extend the widget registry. Triggers on widget addition requests for rfw_gen.
user_invocable: true
---

# Add Widget Skill

Standardized workflow for adding a new widget mapping to rfw_gen.

## Usage

`/add-widget [WidgetName]`

## Steps

1. Check the widget spec in `rules/rfw-widgets.md`
2. Add the mapping to `WidgetRegistry.core()` in `packages/rfw_gen/lib/src/widget_registry.dart`
3. If needed, add type conversion logic in `expression_converter.dart`
4. Add unit tests in `packages/rfw_gen/test/`
5. Add integration tests in `packages/rfw_gen/test/integration_test.dart`
6. Add an `@RfwWidget` demo function in `example/lib/catalog/catalog_widgets.dart`
7. Add golden tests in `example/test/golden_catalog_{category}_test.dart`
8. Verify all tests pass:
   ```bash
   dart test
   ```
9. Generate golden images:
   ```bash
   cd example && flutter test --tags golden --update-goldens
   ```
10. Commit the changes
