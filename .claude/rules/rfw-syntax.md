# rfwtxt Syntax Reference

## Imports

```rfwtxt
import core.widgets;
import material;
```

## Widget Declarations

```rfwtxt
widget myWidget = Container(
  color: 0xFF002211,
  child: Text(text: "Hello"),
);
```

## Stateful Widgets

```rfwtxt
widget Button { down: false } = GestureDetector(
  onTapDown: set state.down = true,
  onTapUp: set state.down = false,
  child: Container(
    color: switch state.down {
      true: 0xFFFF0000,
      false: 0xFF00FF00,
    },
  ),
);
```

## Data References

- `data.path.to.value` — DynamicContent 데이터 접근
- `data.list.0` — 리스트 인덱스 접근
- `args.paramName` — 위젯 생성자 인자 접근
- `state.fieldName` — 위젯 로컬 상태 접근

## String Concatenation

```rfwtxt
Text(text: ["Hello, ", data.user.name, "!"])
```

## Switch Expressions

```rfwtxt
color: switch state.active {
  true: 0xFF00FF00,
  false: 0xFFFF0000,
  default: 0xFF888888,
}
```

## State Mutation

```rfwtxt
onTap: set state.selected = true,
```

## Event Handlers

```rfwtxt
onTap: event "shop.purchase" { productId: args.product.id, quantity: 1 },
```

## For Loops (List Spread)

```rfwtxt
children: [
  Text(text: "Header"),
  ...for item in data.items:
    ListTile(title: Text(text: item.name)),
]
```

## Comments

```rfwtxt
// Line comment
/* Block comment */
```

## Literals

- String: `"hello"`
- Number: `24.0`
- Integer: `0xFF000000`
- Boolean: `true`, `false`
- List: `[16.0, 8.0]`
- Map: `{ fontSize: 24.0, color: 0xFF000000 }`
