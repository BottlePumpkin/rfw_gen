# RFW Widget Reference

## Core Widgets (createCoreWidgets)

### Layout

| Widget | Params | Children | Handlers |
|--------|--------|----------|----------|
| **Align** | alignment, widthFactor, heightFactor, duration, curve | optionalChild | onEnd |
| **AspectRatio** | aspectRatio | optionalChild | — |
| **Center** | widthFactor, heightFactor | optionalChild | — |
| **Column** | mainAxisAlignment, mainAxisSize, crossAxisAlignment, textDirection, verticalDirection, textBaseline | childList(children) | — |
| **Expanded** | flex | child | — |
| **Flexible** | flex, fit | child | — |
| **FittedBox** | fit, alignment, clipBehavior | optionalChild | — |
| **FractionallySizedBox** | alignment, widthFactor, heightFactor | child | — |
| **IntrinsicHeight** | — | optionalChild | — |
| **IntrinsicWidth** | width, height | optionalChild | — |
| **Row** | mainAxisAlignment, mainAxisSize, crossAxisAlignment, textDirection, verticalDirection, textBaseline | childList(children) | — |
| **SizedBox** | width, height | optionalChild | — |
| **SizedBoxExpand** | — | optionalChild | — |
| **SizedBoxShrink** | — | optionalChild | — |
| **Spacer** | flex | — | — |
| **Stack** | alignment, textDirection, fit, clipBehavior | childList(children) | — |
| **Wrap** | direction, alignment, spacing, runAlignment, runSpacing, crossAxisAlignment, textDirection, verticalDirection, clipBehavior | childList(children) | — |

### Scrolling

| Widget | Params | Children |
|--------|--------|----------|
| **GridView** | scrollDirection, reverse, primary, shrinkWrap, padding, gridDelegate, cacheExtent, clipBehavior | childList(children) |
| **ListBody** | mainAxis, reverse | childList(children) |
| **ListView** | scrollDirection, reverse, primary, shrinkWrap, padding, itemExtent, cacheExtent, clipBehavior | childList(children) |
| **SingleChildScrollView** | scrollDirection, reverse, padding, primary, clipBehavior | optionalChild |

### Styling & Visual

| Widget | Params | Children | Handlers |
|--------|--------|----------|----------|
| **ClipRRect** | borderRadius, clipBehavior | optionalChild | — |
| **ColoredBox** | color | optionalChild | — |
| **Container** | alignment, padding, color, decoration, foregroundDecoration, width, height, constraints, margin, transform, clipBehavior, duration, curve | optionalChild | onEnd |
| **DefaultTextStyle** | style, textAlign, softWrap, overflow, maxLines, duration, curve | child | onEnd |
| **Directionality** | textDirection | child | — |
| **Icon** | iconData, size, color, semanticLabel | — | — |
| **IconTheme** | iconThemeData | child | — |
| **Image** | imageProvider, semanticLabel, width, height, color, fit, alignment, repeat | optionalChild | — |
| **Opacity** | opacity, duration, curve | optionalChild | onEnd |
| **Padding** | padding, duration, curve | optionalChild | onEnd |
| **Placeholder** | color, strokeWidth, placeholderWidth, placeholderHeight | — | — |
| **Text** | text (positional), style, textAlign, maxLines, overflow, softWrap | — | — |

### Transform

| Widget | Params | Children | Handlers |
|--------|--------|----------|----------|
| **Positioned** | start, top, end, bottom, width, height, duration, curve | child | onEnd |
| **Rotation** | turns, alignment, duration, curve | optionalChild | onEnd |
| **Scale** | scale, alignment, duration, curve | optionalChild | onEnd |

### Interaction

| Widget | Params | Children | Handlers |
|--------|--------|----------|----------|
| **GestureDetector** | behavior | optionalChild | onTap, onTapDown, onTapUp, onTapCancel, onDoubleTap, onLongPress |

### Other

| Widget | Params | Children |
|--------|--------|----------|
| **AnimationDefaults** | duration, curve | child |
| **SafeArea** | left, top, right, bottom, minimum | child |

## Material Widgets (createMaterialWidgets)

| Widget | Key Params | Children | Handlers |
|--------|-----------|----------|----------|
| **AppBar** | backgroundColor, elevation, centerTitle, toolbarHeight | leading(opt), title(opt), actions(list) | — |
| **Card** | color, elevation, shape, margin | optionalChild | — |
| **CircularProgressIndicator** | value, color, strokeWidth | — | — |
| **Divider** | height, thickness, indent, endIndent, color | — | — |
| **Drawer** | elevation | optionalChild | — |
| **ElevatedButton** | autofocus, clipBehavior | child | onPressed, onLongPress |
| **FloatingActionButton** | tooltip, backgroundColor, elevation, mini | child | onPressed |
| **InkWell** | splashColor, highlightColor, borderRadius | optionalChild | onTap, onDoubleTap, onLongPress |
| **LinearProgressIndicator** | value, color, backgroundColor | — | — |
| **ListTile** | dense, enabled, selected, contentPadding | leading(opt), title(opt), subtitle(opt), trailing(opt) | onTap, onLongPress |
| **Material** | type, elevation, color, shadowColor | child | — |
| **OutlinedButton** | autofocus, clipBehavior | child | onPressed, onLongPress |
| **OverflowBar** | spacing, alignment, overflowSpacing | childList(children) | — |
| **Scaffold** | backgroundColor, resizeToAvoidBottomInset | appBar(opt), body(opt), floatingActionButton(opt), drawer(opt), bottomNavigationBar(opt) | — |
| **Slider** | min, max, value, divisions, activeColor | — | onChanged({value}), onChangeStart, onChangeEnd |
| **TextButton** | autofocus, clipBehavior | child | onPressed, onLongPress |
| **VerticalDivider** | width, thickness, indent, endIndent, color | — | — |

## Notes

- Container, Align, Opacity, Padding, DefaultTextStyle, Positioned, Rotation, Scale are animated variants (implicit animation via duration/curve)
- Text is the only widget with a positional parameter (`text`)
- GestureDetector discards tap detail info (position, velocity)
- Scaffold.bottomHeight sets PreferredSize height for appBar (default 56.0)
