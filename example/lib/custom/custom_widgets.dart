// ignore_for_file: argument_type_not_assignable, undefined_function, undefined_class, undefined_named_parameter, not_enough_positional_arguments
import 'package:flutter/material.dart';
import 'package:rfw_gen/rfw_gen.dart';

// ============================================================
// 1. CustomText — child_type: none, pass-through params
// ============================================================

@RfwWidget('customTextDemo')
Widget buildCustomTextDemo() {
  return Column(
    children: [
      CustomText(text: 'Heading Style', fontType: 'heading', color: 0xFF1565C0),
      SizedBox(height: 8.0),
      CustomText(text: 'Body Style', fontType: 'body', color: 0xFF424242),
      SizedBox(height: 8.0),
      CustomText(text: 'Caption with maxLines', fontType: 'caption', color: 0xFF757575, maxLines: 1),
    ],
  );
}

// ============================================================
// 2. CustomBounceTapper — child_type: optionalChild, handler: onTap
// ============================================================

@RfwWidget('customBounceTapperDemo')
Widget buildCustomBounceTapperDemo() {
  return CustomBounceTapper(
    onTap: RfwHandler.event('bounce.tap', {'source': 'demo'}),
    child: Container(
      padding: const EdgeInsets.all(16.0),
      color: const Color(0xFF2196F3),
      child: Text('Tap me (bounce)', style: const TextStyle(color: Color(0xFFFFFFFF))),
    ),
  );
}

// ============================================================
// 3. NullConditionalWidget — optionalChild + widget-value param (nullChild)
// ============================================================

@RfwWidget('nullConditionalDemo')
Widget buildNullConditionalDemo() {
  return Column(
    children: [
      NullConditionalWidget(
        child: CustomText(text: 'Visible content', fontType: 'heading', color: 0xFF4CAF50),
        nullChild: CustomText(text: 'Fallback content', fontType: 'body', color: 0xFFFF5722),
      ),
      SizedBox(height: 16.0),
      NullConditionalWidget(
        nullChild: Container(
          padding: const EdgeInsets.all(12.0),
          color: const Color(0xFFFFF3E0),
          child: Text('This is the fallback'),
        ),
      ),
    ],
  );
}

// ============================================================
// 4. CustomButton — child_type: child, handlers: onPressed + onLongPress
// ============================================================

@RfwWidget('customButtonDemo')
Widget buildCustomButtonDemo() {
  return Column(
    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
    children: [
      CustomButton(
        onPressed: RfwHandler.event('button.press', {'id': 'primary'}),
        onLongPress: RfwHandler.event('button.longPress', {'id': 'primary'}),
        child: Text('Primary Button'),
      ),
      SizedBox(height: 12.0),
      CustomButton(
        onPressed: RfwHandler.event('button.press', {'id': 'secondary'}),
        child: Text('Secondary Button'),
      ),
    ],
  );
}

// ============================================================
// 5. CustomBadge — child_type: none, Color + number + string params
// ============================================================

@RfwWidget('customBadgeDemo')
Widget buildCustomBadgeDemo() {
  return Row(
    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
    children: [
      CustomBadge(label: 'NEW', count: 5, backgroundColor: 0xFFE91E63),
      CustomBadge(label: 'HOT', count: 12, backgroundColor: 0xFFFF9800),
      CustomBadge(label: 'SALE', count: 0, backgroundColor: 0xFF4CAF50),
    ],
  );
}

// ============================================================
// 6. CustomProgressBar — child_type: none, value + color + enum params
// ============================================================

@RfwWidget('customProgressBarDemo')
Widget buildCustomProgressBarDemo() {
  return Column(
    children: [
      CustomProgressBar(value: 0.3, color: 0xFF2196F3, shape: 'rounded'),
      SizedBox(height: 12.0),
      CustomProgressBar(value: 0.7, color: 0xFF4CAF50, shape: 'square'),
      SizedBox(height: 12.0),
      CustomProgressBar(value: 1.0, color: 0xFFFF9800, shape: 'rounded', height: 8.0),
    ],
  );
}

// ============================================================
// 7. CustomColumn — child_type: childList
// ============================================================

@RfwWidget('customColumnDemo')
Widget buildCustomColumnDemo() {
  return CustomColumn(
    spacing: 8.0,
    dividerColor: 0xFFE0E0E0,
    children: [
      Container(height: 40.0, color: const Color(0xFF2196F3)),
      Container(height: 40.0, color: const Color(0xFF4CAF50)),
      Container(height: 40.0, color: const Color(0xFFFF9800)),
    ],
  );
}

// ============================================================
// 8. SkeletonContainer — child_type: optionalChild, boolean param
// ============================================================

@RfwWidget('skeletonContainerDemo')
Widget buildSkeletonContainerDemo() {
  return Column(
    children: [
      SkeletonContainer(
        isLoading: true,
        child: Text('This content is loading...'),
      ),
      SizedBox(height: 16.0),
      SkeletonContainer(
        isLoading: false,
        child: Text('This content is loaded!'),
      ),
    ],
  );
}

// ============================================================
// 9. CompareWidget — optionalChild + multiple widget-value params
// ============================================================

@RfwWidget('compareWidgetDemo')
Widget buildCompareWidgetDemo() {
  return Column(
    children: [
      CompareWidget(
        child: CustomText(text: 'Checking condition...', fontType: 'body', color: 0xFF757575),
        trueChild: Container(
          padding: const EdgeInsets.all(12.0),
          color: const Color(0xFFE8F5E9),
          child: Text('Condition is TRUE', style: const TextStyle(color: Color(0xFF4CAF50))),
        ),
        falseChild: Container(
          padding: const EdgeInsets.all(12.0),
          color: const Color(0xFFFFEBEE),
          child: Text('Condition is FALSE', style: const TextStyle(color: Color(0xFFFF5722))),
        ),
      ),
    ],
  );
}

// ============================================================
// 10. PvContainer — optionalChild + custom event name handler (onPv)
// ============================================================

@RfwWidget('pvContainerDemo')
Widget buildPvContainerDemo() {
  return PvContainer(
    onPv: RfwHandler.event('pv.track', {'screen': 'demo', 'section': 'custom'}),
    child: Container(
      padding: const EdgeInsets.all(16.0),
      color: const Color(0xFFE3F2FD),
      child: Column(
        children: [
          Text('PV Tracking Container', style: const TextStyle(fontSize: 16.0, fontWeight: FontWeight.bold)),
          SizedBox(height: 4.0),
          Text('onPv event fires on view', style: const TextStyle(fontSize: 12.0, color: Color(0xFF757575))),
        ],
      ),
    ),
  );
}

// ============================================================
// 11. CustomCard — child_type: child + handler: onTap
// ============================================================

@RfwWidget('customCardDemo')
Widget buildCustomCardDemo() {
  return Column(
    children: [
      CustomCard(
        onTap: RfwHandler.event('card.tap', {'id': 'card1'}),
        elevation: 4.0,
        borderRadius: 12.0,
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Custom Card 1', style: const TextStyle(fontSize: 18.0, fontWeight: FontWeight.bold)),
              SizedBox(height: 4.0),
              Text('Tappable card with elevation', style: const TextStyle(color: Color(0xFF757575))),
            ],
          ),
        ),
      ),
      SizedBox(height: 12.0),
      CustomCard(
        onTap: RfwHandler.event('card.tap', {'id': 'card2'}),
        elevation: 2.0,
        borderRadius: 8.0,
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Text('Custom Card 2'),
        ),
      ),
    ],
  );
}

// ============================================================
// 12. CustomTile — namedSlots (leading/title/subtitle/trailing) + handler
// ============================================================

@RfwWidget('customTileDemo')
Widget buildCustomTileDemo() {
  return Column(
    children: [
      CustomTile(
        leading: Icon(icon: RfwIcon.email, size: 40.0, color: const Color(0xFF2196F3)),
        title: CustomText(text: 'Custom Tile Title', fontType: 'heading', color: 0xFF212121),
        subtitle: Text('Subtitle with named slots'),
        trailing: Icon(icon: RfwIcon.chevronRight),
        onTap: RfwHandler.event('tile.tap', {'id': 'tile1'}),
      ),
      Divider(),
      CustomTile(
        leading: Icon(icon: RfwIcon.settings, size: 40.0, color: const Color(0xFF757575)),
        title: Text('Minimal Tile'),
        onTap: RfwHandler.event('tile.tap', {'id': 'tile2'}),
      ),
    ],
  );
}

// ============================================================
// 13. CustomAppBar — namedSlots (title + actions list slot)
// ============================================================

@RfwWidget('customAppBarDemo')
Widget buildCustomAppBarDemo() {
  return Column(
    children: [
      CustomAppBar(
        title: Text('Custom App Bar', style: const TextStyle(fontSize: 20.0, fontWeight: FontWeight.bold, color: Color(0xFFFFFFFF))),
        actions: [
          GestureDetector(
            onTap: RfwHandler.event('appbar.search', {}),
            child: Icon(icon: RfwIcon.search, color: const Color(0xFFFFFFFF)),
          ),
          GestureDetector(
            onTap: RfwHandler.event('appbar.more', {}),
            child: Icon(icon: RfwIcon.moreVert, color: const Color(0xFFFFFFFF)),
          ),
        ],
      ),
      SizedBox(height: 16.0),
      CustomAppBar(
        title: CustomText(text: 'Styled Title', fontType: 'heading', color: 0xFFFFFFFF),
      ),
    ],
  );
}
