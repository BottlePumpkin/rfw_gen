## 0.5.0

- Add fitness/health/timer category icons to `RfwIcon` (fitnessCenter, timer, directionsRun, etc.)
- Add setState toggle pattern example to README
- Add rfw dependency and rendering guide to README

## 0.4.1

- No changes (version bump to match rfw_gen_builder)

## 0.4.0

- **Breaking**: Remove `rfw_gen.yaml` custom widget configuration
- Custom widgets are now auto-detected from `@RfwWidget` functions via Dart analyzer

## 0.3.0

- No changes (version bump to match rfw_gen_mcp)

## 0.2.2

- No changes (version bump to match rfw_gen_mcp)

## 0.2.1

- No changes to rfw_gen (version bump to match rfw_gen_builder)

## 0.2.0

- Add `column` field to `RfwGenIssue` for precise error location reporting

## 0.1.0

- Initial release
- Support 65 widgets (Core + Material)
- Custom widget support via `rfw_gen.yaml` (removed in 0.4.0)
- Dynamic features: `DataRef`, `ArgsRef`, `StateRef`, `RfwFor`, `RfwSwitch`, `RfwConcat`
- Event handlers: `RfwHandler` (`setState`, `setStateFromArg`, `event`)
- RFW-only widget aliases: `SizedBoxExpand`, `SizedBoxShrink`, `Rotation`, `Scale`, `AnimationDefaults`
