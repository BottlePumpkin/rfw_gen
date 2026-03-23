# RFW Argument Type Encoding

## Color
32-bit integer `0xAARRGGBB`. Examples: `0xFF000000` (black), `0xFFFF0000` (red).

## EdgeInsets / EdgeInsetsDirectional
List of 1-4 doubles: `[all]`, `[horizontal, vertical]`, `[start, top, end, bottom]`.

## TextStyle
Map: `{ color: 0xFF000000, fontSize: 24.0, fontWeight: "bold", fontStyle: "italic", fontFamily: "Roboto", letterSpacing: 1.0, wordSpacing: 2.0, height: 1.5, decoration: "underline", decorationColor: 0xFFFF0000, decorationStyle: "wavy", overflow: "ellipsis" }`

fontWeight: w100-w900, normal(=w400), bold(=w700)

## Alignment
`{x: double, y: double}` — center: `{x: 0.0, y: 0.0}`, topLeft: `{x: -1.0, y: -1.0}`

AlignmentDirectional: `{start: double, y: double}`

## BoxDecoration
`{ type: "box", color: 0xFF000000, border: [...], borderRadius: [...], boxShadow: [...], gradient: {...}, shape: "rectangle"|"circle" }`

## BorderRadius
List of 1-4 radius: `[{x: 8.0}]` (all corners) or `[topStart, topEnd, bottomStart, bottomEnd]`

## BoxShadow
`{ color: 0xFF000000, offset: {x: 0.0, y: 2.0}, blurRadius: 4.0, spreadRadius: 0.0 }`

## Duration
Integer (milliseconds). Falls back to AnimationDefaults (200ms).

## Curve
String: `linear`, `ease`, `easeIn`, `easeOut`, `easeInOut`, `fastOutSlowIn`, `bounceIn`, `bounceOut`, `elasticIn`, `elasticOut`, etc.

## IconData
`{ icon: 0xe14f, fontFamily: "MaterialIcons" }`

## ImageProvider
`{ source: "url_or_asset", scale: 1.0 }` — absolute URL → NetworkImage, relative → AssetImage.

## Gradient
- Linear: `{ type: "linear", begin: alignment, end: alignment, colors: [...], stops: [...], tileMode: "clamp" }`
- Radial: `{ type: "radial", center: alignment, radius: double, colors: [...], stops: [...] }`
- Sweep: `{ type: "sweep", center: alignment, startAngle: double, endAngle: double, colors: [...] }`

## ShapeBorder
- Box: `{ type: "box", sides: borderList }`
- Rounded: `{ type: "rounded", side: borderSide, borderRadius: borderRadius }`
- Circle: `{ type: "circle", side: borderSide }`
- Stadium: `{ type: "stadium", side: borderSide }`

## VisualDensity
String: `"adaptivePlatformDensity"`, `"comfortable"`, `"compact"`, `"standard"`
Or map: `{ horizontal: double, vertical: double }`

## Common Enums

| Enum | Values |
|------|--------|
| MainAxisAlignment | start, end, center, spaceBetween, spaceAround, spaceEvenly |
| CrossAxisAlignment | start, end, center, stretch, baseline |
| MainAxisSize | min, max |
| Axis | horizontal, vertical |
| TextAlign | left, right, center, justify, start, end |
| TextOverflow | clip, fade, ellipsis, visible |
| BoxFit | fill, contain, cover, fitWidth, fitHeight, none, scaleDown |
| StackFit | loose, expand, passthrough |
| Clip | none, hardEdge, antiAlias, antiAliasWithSaveLayer |
| FontWeight | w100-w900, normal, bold |
| FontStyle | normal, italic |
| VerticalDirection | up, down |
| FlexFit | tight, loose |
| WrapAlignment | start, end, center, spaceBetween, spaceAround, spaceEvenly |
