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

### Step 6.5: (Optional) Add playground gallery example

If the widget is commonly used and would benefit from a live playground example:

1. Create `rfw_gen_playground/lib/screens/gallery/widget_detail_{snake_name}.dart`
   - Include an `@RfwWidget` function demonstrating the widget's key parameters
   - Show 2-3 usage variations (basic, with styling, with interaction if applicable)
2. Add entry to `rfw_gen_playground/remote/manifest.json` under `gallery_detail`:
   ```json
   {
     "id": "widget_detail_{snake_name}",
     "title": "{WidgetName}",
     "category": "gallery_detail",
     "rfwtxt": "screens/widget_detail_{snake_name}.rfwtxt",
     "keywords": ["{widget_name}", "gallery"]
   }
   ```
3. Run `cd rfw_gen_playground && flutter build web` to verify the example compiles

> **Skip this step** if the widget is niche (e.g., AnimationDefaults, Directionality) or if it's an animated alias of an already-covered widget.

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
