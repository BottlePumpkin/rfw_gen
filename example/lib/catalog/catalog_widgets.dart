// ignore_for_file: argument_type_not_assignable, undefined_function, undefined_class, undefined_named_parameter, not_enough_positional_arguments
import 'package:flutter/material.dart';
import 'package:rfw_gen/rfw_gen.dart';

// ============================================================
// Layout Category
// ============================================================

@RfwWidget('columnDemo')
Widget buildColumnDemo() {
  return Column(
    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
    mainAxisSize: MainAxisSize.max,
    children: [
      Container(width: 60.0, height: 60.0, color: const Color(0xFF2196F3)),
      Container(width: 60.0, height: 60.0, color: const Color(0xFF4CAF50)),
      Container(width: 60.0, height: 60.0, color: const Color(0xFFFF9800)),
    ],
  );
}

@RfwWidget('rowDemo')
Widget buildRowDemo() {
  return Row(
    crossAxisAlignment: CrossAxisAlignment.center,
    mainAxisAlignment: MainAxisAlignment.spaceAround,
    children: [
      Container(width: 50.0, height: 80.0, color: const Color(0xFFE91E63)),
      Container(width: 50.0, height: 60.0, color: const Color(0xFF9C27B0)),
      Container(width: 50.0, height: 40.0, color: const Color(0xFF673AB7)),
    ],
  );
}

@RfwWidget('wrapDemo')
Widget buildWrapDemo() {
  return Wrap(
    spacing: 8.0,
    runSpacing: 8.0,
    children: [
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 6.0),
        color: const Color(0xFF2196F3),
        child: Text('Flutter', style: const TextStyle(color: Color(0xFFFFFFFF))),
      ),
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 6.0),
        color: const Color(0xFF4CAF50),
        child: Text('RFW', style: const TextStyle(color: Color(0xFFFFFFFF))),
      ),
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 6.0),
        color: const Color(0xFFFF9800),
        child: Text('Dart', style: const TextStyle(color: Color(0xFFFFFFFF))),
      ),
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 6.0),
        color: const Color(0xFFE91E63),
        child: Text('Widget', style: const TextStyle(color: Color(0xFFFFFFFF))),
      ),
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 6.0),
        color: const Color(0xFF9C27B0),
        child: Text('Remote', style: const TextStyle(color: Color(0xFFFFFFFF))),
      ),
    ],
  );
}

@RfwWidget('stackDemo')
Widget buildStackDemo() {
  return Stack(
    alignment: const Alignment(0.0, 0.0),
    children: [
      Container(width: 200.0, height: 200.0, color: const Color(0xFF2196F3)),
      Container(width: 150.0, height: 150.0, color: const Color(0xFF4CAF50)),
      Positioned(
        top: 10.0,
        end: 10.0,
        child: Container(width: 40.0, height: 40.0, color: const Color(0xFFFF9800)),
      ),
    ],
  );
}

@RfwWidget('expandedDemo')
Widget buildExpandedDemo() {
  return Row(
    children: [
      Expanded(
        flex: 2,
        child: Container(height: 60.0, color: const Color(0xFF2196F3)),
      ),
      Expanded(
        flex: 1,
        child: Container(height: 60.0, color: const Color(0xFF4CAF50)),
      ),
      Flexible(
        flex: 1,
        fit: FlexFit.loose,
        child: Container(width: 30.0, height: 60.0, color: const Color(0xFFFF9800)),
      ),
    ],
  );
}

@RfwWidget('sizedBoxDemo')
Widget buildSizedBoxDemo() {
  return Column(
    children: [
      SizedBox(
        width: 100.0,
        height: 50.0,
        child: ColoredBox(color: const Color(0xFF2196F3)),
      ),
      Spacer(flex: 1),
      SizedBoxExpand(
        child: ColoredBox(color: const Color(0xFFE8EAF6)),
      ),
      SizedBoxShrink(),
    ],
  );
}

@RfwWidget('alignDemo')
Widget buildAlignDemo() {
  return SizedBox(
    width: 200.0,
    height: 200.0,
    child: Stack(
      children: [
        Container(color: const Color(0xFFE8EAF6)),
        Align(
          alignment: const Alignment(-1.0, -1.0),
          child: Container(width: 40.0, height: 40.0, color: const Color(0xFFFF5722)),
        ),
        Center(
          child: Text('Center'),
        ),
        Align(
          alignment: const Alignment(1.0, 1.0),
          child: Container(width: 40.0, height: 40.0, color: const Color(0xFF4CAF50)),
        ),
      ],
    ),
  );
}

@RfwWidget('aspectRatioDemo')
Widget buildAspectRatioDemo() {
  return Column(
    children: [
      AspectRatio(
        aspectRatio: 1.78,
        child: Container(color: const Color(0xFF2196F3)),
      ),
      SizedBox(height: 8.0),
      FractionallySizedBox(
        widthFactor: 0.7,
        child: Container(height: 40.0, color: const Color(0xFF4CAF50)),
      ),
    ],
  );
}

@RfwWidget('intrinsicDemo')
Widget buildIntrinsicDemo() {
  return Column(
    children: [
      IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(width: 50.0, color: const Color(0xFF2196F3)),
            Column(
              children: [
                Container(width: 100.0, height: 30.0, color: const Color(0xFF4CAF50)),
                Container(width: 100.0, height: 60.0, color: const Color(0xFFFF9800)),
              ],
            ),
          ],
        ),
      ),
      SizedBox(height: 8.0),
      IntrinsicWidth(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(height: 30.0, width: 80.0, color: const Color(0xFFE91E63)),
            Container(height: 30.0, width: 120.0, color: const Color(0xFF9C27B0)),
          ],
        ),
      ),
    ],
  );
}

// ============================================================
// Scrolling Category
// ============================================================

@RfwWidget('listViewDemo')
Widget buildListViewDemo() {
  return ListView(
    padding: const EdgeInsets.all(8.0),
    children: [
      Container(height: 50.0, color: const Color(0xFF2196F3), margin: const EdgeInsets.only(bottom: 4.0)),
      Container(height: 50.0, color: const Color(0xFF4CAF50), margin: const EdgeInsets.only(bottom: 4.0)),
      Container(height: 50.0, color: const Color(0xFFFF9800), margin: const EdgeInsets.only(bottom: 4.0)),
      Container(height: 50.0, color: const Color(0xFFE91E63)),
    ],
  );
}

@RfwWidget('gridViewDemo')
Widget buildGridViewDemo() {
  return GridView(
    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 2),
    shrinkWrap: true,
    children: [
      Container(color: const Color(0xFF2196F3), margin: const EdgeInsets.all(4.0)),
      Container(color: const Color(0xFF4CAF50), margin: const EdgeInsets.all(4.0)),
      Container(color: const Color(0xFFFF9800), margin: const EdgeInsets.all(4.0)),
      Container(color: const Color(0xFFE91E63), margin: const EdgeInsets.all(4.0)),
    ],
  );
}

@RfwWidget('scrollViewDemo')
Widget buildScrollViewDemo() {
  return SingleChildScrollView(
    padding: const EdgeInsets.all(16.0),
    child: Column(
      children: [
        Container(height: 100.0, color: const Color(0xFF2196F3)),
        SizedBox(height: 8.0),
        Container(height: 100.0, color: const Color(0xFF4CAF50)),
        SizedBox(height: 8.0),
        Container(height: 100.0, color: const Color(0xFFFF9800)),
      ],
    ),
  );
}

@RfwWidget('listBodyDemo')
Widget buildListBodyDemo() {
  return SingleChildScrollView(
    child: ListBody(
      children: [
        Container(height: 40.0, color: const Color(0xFF2196F3), margin: const EdgeInsets.only(bottom: 4.0)),
        Container(height: 40.0, color: const Color(0xFF4CAF50), margin: const EdgeInsets.only(bottom: 4.0)),
        Container(height: 40.0, color: const Color(0xFFFF9800)),
      ],
    ),
  );
}

// ============================================================
// Styling & Visual Category
// ============================================================

@RfwWidget('containerDemo')
Widget buildContainerDemo() {
  return Container(
    width: 200.0,
    height: 200.0,
    padding: const EdgeInsets.all(16.0),
    margin: const EdgeInsets.all(8.0),
    decoration: const BoxDecoration(
      gradient: LinearGradient(
        begin: Alignment(-1.0, -1.0),
        end: Alignment(1.0, 1.0),
        colors: [Color(0xFF2196F3), Color(0xFF9C27B0)],
      ),
      borderRadius: BorderRadius.all(Radius.circular(16)),
      boxShadow: [BoxShadow(color: Color(0x40000000), blurRadius: 8, offset: Offset(0, 4))],
    ),
    child: Center(
      child: Text('Container', style: const TextStyle(color: Color(0xFFFFFFFF), fontSize: 18.0)),
    ),
  );
}

@RfwWidget('paddingOpacityDemo')
Widget buildPaddingOpacityDemo() {
  return Column(
    children: [
      Padding(
        padding: const EdgeInsets.all(24.0),
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
        child: Container(width: 100.0, height: 50.0, color: const Color(0xFF2196F3)),
      ),
      Opacity(
        opacity: 0.5,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
        child: Container(width: 100.0, height: 50.0, color: const Color(0xFFFF9800)),
      ),
    ],
  );
}

@RfwWidget('clipRRectDemo')
Widget buildClipRRectDemo() {
  return ClipRRect(
    borderRadius: const BorderRadius.all(Radius.circular(20)),
    child: Container(
      width: 150.0,
      height: 100.0,
      color: const Color(0xFF4CAF50),
      child: Center(
        child: Text('Clipped', style: const TextStyle(color: Color(0xFFFFFFFF))),
      ),
    ),
  );
}

@RfwWidget('defaultTextStyleDemo')
Widget buildDefaultTextStyleDemo() {
  return DefaultTextStyle(
    style: const TextStyle(fontSize: 20.0, color: Color(0xFF1565C0), fontWeight: FontWeight.bold),
    duration: const Duration(milliseconds: 400),
    child: Column(
      children: [
        Text('Inherited Style'),
        Text('Same Style Here'),
      ],
    ),
  );
}

@RfwWidget('directionalityDemo')
Widget buildDirectionalityDemo() {
  return Column(
    children: [
      Directionality(
        textDirection: TextDirection.ltr,
        child: Row(
          children: [
            Text('LTR → '),
            Text('Left to Right'),
          ],
        ),
      ),
      Directionality(
        textDirection: TextDirection.rtl,
        child: Row(
          children: [
            Text('RTL ← '),
            Text('Right to Left'),
          ],
        ),
      ),
    ],
  );
}

@RfwWidget('iconDemo')
Widget buildIconDemo() {
  return Row(
    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
    children: [
      Icon(icon: RfwIcon.home, size: 32.0, color: const Color(0xFF2196F3)),
      Icon(icon: RfwIcon.favorite, size: 32.0, color: const Color(0xFFE91E63)),
      Icon(icon: RfwIcon.star, size: 32.0, color: const Color(0xFFFF9800)),
    ],
  );
}

@RfwWidget('iconThemeDemo')
Widget buildIconThemeDemo() {
  return IconTheme(
    data: const IconThemeData(color: Color(0xFF9C27B0), size: 40.0),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        Icon(icon: RfwIcon.star),
        Icon(icon: RfwIcon.favorite),
        Icon(icon: RfwIcon.bookmark),
      ],
    ),
  );
}

@RfwWidget('imageDemo')
Widget buildImageDemo() {
  return Image(
    image: const NetworkImage('https://picsum.photos/seed/rfw/300/200'),
    width: 300.0,
    height: 200.0,
    fit: BoxFit.cover,
  );
}

@RfwWidget('textDemo')
Widget buildTextDemo() {
  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text('Regular Text', style: const TextStyle(fontSize: 16.0)),
      Text('Bold Text', style: const TextStyle(fontSize: 16.0, fontWeight: FontWeight.bold)),
      Text('Italic Colored', style: const TextStyle(fontSize: 16.0, fontStyle: FontStyle.italic, color: Color(0xFFE91E63))),
      Text('Overflow ellipsis for very long text that should be truncated', maxLines: 1, overflow: TextOverflow.ellipsis),
    ],
  );
}

@RfwWidget('coloredBoxDemo')
Widget buildColoredBoxDemo() {
  return Column(
    children: [
      ColoredBox(
        color: const Color(0xFF2196F3),
        child: SizedBox(width: 100.0, height: 50.0),
      ),
      SizedBox(height: 8.0),
      Placeholder(
        color: const Color(0xFFFF5722),
        strokeWidth: 2.0,
        placeholderWidth: 100.0,
        placeholderHeight: 50.0,
      ),
    ],
  );
}

// ============================================================
// Transform Category
// ============================================================

@RfwWidget('rotationDemo')
Widget buildRotationDemo() {
  return Row(
    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
    children: [
      Rotation(
        turns: 0.125,
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeInOut,
        child: Container(width: 60.0, height: 60.0, color: const Color(0xFF2196F3)),
      ),
      Rotation(
        turns: 0.25,
        child: Container(width: 60.0, height: 60.0, color: const Color(0xFF4CAF50)),
      ),
    ],
  );
}

@RfwWidget('scaleDemo')
Widget buildScaleDemo() {
  return Row(
    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
    children: [
      Scale(
        scale: 1.5,
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeOut,
        child: Container(width: 40.0, height: 40.0, color: const Color(0xFFE91E63)),
      ),
      Scale(
        scale: 0.5,
        child: Container(width: 80.0, height: 80.0, color: const Color(0xFF9C27B0)),
      ),
    ],
  );
}

@RfwWidget('fittedBoxDemo')
Widget buildFittedBoxDemo() {
  return SizedBox(
    width: 200.0,
    height: 100.0,
    child: FittedBox(
      fit: BoxFit.contain,
      child: Text('FittedBox', style: const TextStyle(fontSize: 60.0)),
    ),
  );
}

// ============================================================
// Interaction Category
// ============================================================

@RfwWidget('gestureDetectorDemo', state: {'tapped': false, 'longPressed': false})
Widget buildGestureDetectorDemo() {
  return GestureDetector(
    onTap: RfwHandler.setState('tapped', true),
    onLongPress: RfwHandler.setState('longPressed', true),
    onDoubleTap: RfwHandler.event('gesture.doubleTap', {}),
    child: Container(
      width: 200.0,
      height: 80.0,
      color: RfwSwitchValue<int>(
        value: StateRef('tapped'),
        cases: {true: 0xFF4CAF50, false: 0xFF2196F3},
      ),
      child: Center(
        child: Text('Tap / Long Press / Double Tap', style: const TextStyle(color: Color(0xFFFFFFFF))),
      ),
    ),
  );
}

@RfwWidget('inkWellDemo', state: {'pressed': false})
Widget buildInkWellDemo() {
  return InkWell(
    onTap: RfwHandler.setState('pressed', true),
    onLongPress: RfwHandler.event('inkwell.longPress', {}),
    splashColor: const Color(0x402196F3),
    child: Container(
      padding: const EdgeInsets.all(16.0),
      child: Text('InkWell with Ripple', style: const TextStyle(fontSize: 16.0)),
    ),
  );
}

// ============================================================
// Other Category
// ============================================================

@RfwWidget('animationDefaultsDemo')
Widget buildAnimationDefaultsDemo() {
  return AnimationDefaults(
    duration: const Duration(milliseconds: 600),
    curve: Curves.fastOutSlowIn,
    child: Column(
      children: [
        Opacity(
          opacity: 0.5,
          child: Container(width: 120.0, height: 40.0, color: const Color(0xFF2196F3)),
        ),
        SizedBox(height: 8.0),
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: Container(width: 120.0, height: 40.0, color: const Color(0xFF4CAF50)),
        ),
      ],
    ),
  );
}

@RfwWidget('safeAreaDemo')
Widget buildSafeAreaDemo() {
  return SafeArea(
    child: Container(
      color: const Color(0xFFE8EAF6),
      child: Center(
        child: Text('Inside SafeArea', style: const TextStyle(fontSize: 16.0)),
      ),
    ),
  );
}

@RfwWidget('argsPatternDemo')
Widget buildArgsPatternDemo() {
  return Column(
    children: [
      // data.list.0 index access
      Text(DataRef('catalog.sampleItems.0.name')),
      SizedBox(height: 8.0),
      // RfwSwitch with default case
      Container(
        width: 100.0,
        height: 40.0,
        color: RfwSwitchValue<int>(
          value: DataRef('catalog.sampleItems.0.name'),
          cases: {'Apple': 0xFFFF0000, 'Banana': 0xFFFFEB3B},
          defaultCase: 0xFF9E9E9E,
        ),
      ),
    ],
  );
}

// ============================================================
// Material Category
// ============================================================

@RfwWidget('scaffoldDemo')
Widget buildScaffoldDemo() {
  return Scaffold(
    appBar: AppBar(
      title: Text('Scaffold Demo'),
      backgroundColor: const Color(0xFF2196F3),
    ),
    body: Center(
      child: Text('Scaffold Body', style: const TextStyle(fontSize: 18.0)),
    ),
    floatingActionButton: FloatingActionButton(
      onPressed: RfwHandler.event('fab.pressed', {}),
      child: Icon(icon: RfwIcon.add),
    ),
  );
}

@RfwWidget('materialDemo')
Widget buildMaterialDemo() {
  return Material(
    elevation: 4.0,
    color: const Color(0xFFFFFFFF),
    child: Padding(
      padding: const EdgeInsets.all(16.0),
      child: Text('Material Surface', style: const TextStyle(fontSize: 16.0)),
    ),
  );
}

@RfwWidget('cardDemo')
Widget buildCardDemo() {
  return Column(
    children: [
      Card(
        elevation: 4.0,
        margin: const EdgeInsets.all(8.0),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Text('Rounded Card', style: const TextStyle(fontSize: 16.0)),
        ),
      ),
    ],
  );
}

@RfwWidget('buttonDemo')
Widget buildButtonDemo() {
  return Column(
    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
    children: [
      ElevatedButton(
        onPressed: RfwHandler.event('button.elevated', {}),
        child: Text('Elevated'),
      ),
      SizedBox(height: 8.0),
      TextButton(
        onPressed: RfwHandler.event('button.text', {}),
        child: Text('Text Button'),
      ),
      SizedBox(height: 8.0),
      OutlinedButton(
        onPressed: RfwHandler.event('button.outlined', {}),
        child: Text('Outlined'),
      ),
    ],
  );
}

@RfwWidget('listTileDemo')
Widget buildListTileDemo() {
  return Column(
    children: [
      ListTile(
        leading: Icon(icon: RfwIcon.email, size: 40.0, color: const Color(0xFF2196F3)),
        title: Text('List Tile Title'),
        subtitle: Text('Subtitle text here'),
        trailing: Icon(icon: RfwIcon.chevronRight),
        onTap: RfwHandler.event('listTile.tap', {}),
      ),
      Divider(),
      ListTile(
        leading: Icon(icon: RfwIcon.settings, size: 40.0, color: const Color(0xFF757575)),
        title: Text('Settings'),
        onTap: RfwHandler.event('listTile.settings', {}),
      ),
    ],
  );
}

@RfwWidget('sliderDemo', state: {'value': 50.0})
Widget buildSliderDemo() {
  return Column(
    children: [
      Slider(
        min: 0.0,
        max: 100.0,
        value: StateRef('value'),
        onChanged: RfwHandler.setStateFromArg('value'),
        onChangeStart: RfwHandler.event('slider.start', {}),
        onChangeEnd: RfwHandler.event('slider.end', {}),
      ),
      Text(RfwConcat(['Value: ', StateRef('value')])),
    ],
  );
}

@RfwWidget('drawerDemo')
Widget buildDrawerDemo() {
  return Scaffold(
    appBar: AppBar(title: Text('Drawer Demo')),
    drawer: Drawer(
      child: ListView(
        children: [
          ListTile(
            leading: Icon(icon: RfwIcon.home),
            title: Text('Home'),
            onTap: RfwHandler.event('drawer.home', {}),
          ),
          ListTile(
            leading: Icon(icon: RfwIcon.settings),
            title: Text('Settings'),
            onTap: RfwHandler.event('drawer.settings', {}),
          ),
        ],
      ),
    ),
    body: Center(
      child: Text('Swipe or tap menu to open drawer'),
    ),
  );
}

@RfwWidget('dividerDemo')
Widget buildDividerDemo() {
  return Column(
    children: [
      Text('Above Divider'),
      Divider(thickness: 2.0, color: const Color(0xFF2196F3)),
      Text('Below Divider'),
      SizedBox(height: 16.0),
      Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text('Left'),
          SizedBox(
            height: 40.0,
            child: VerticalDivider(thickness: 2.0, color: const Color(0xFFFF9800)),
          ),
          Text('Right'),
        ],
      ),
    ],
  );
}

@RfwWidget('progressDemo')
Widget buildProgressDemo() {
  return Column(
    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
    children: [
      CircularProgressIndicator(value: 0.7, color: const Color(0xFF2196F3), strokeWidth: 6.0),
      SizedBox(height: 16.0),
      LinearProgressIndicator(value: 0.4, color: const Color(0xFF4CAF50), backgroundColor: const Color(0xFFE0E0E0)),
    ],
  );
}

@RfwWidget('overflowBarDemo')
Widget buildOverflowBarDemo() {
  return OverflowBar(
    spacing: 8.0,
    overflowSpacing: 4.0,
    children: [
      ElevatedButton(
        onPressed: RfwHandler.event('overflow.1', {}),
        child: Text('Action 1'),
      ),
      OutlinedButton(
        onPressed: RfwHandler.event('overflow.2', {}),
        child: Text('Action 2'),
      ),
      TextButton(
        onPressed: RfwHandler.event('overflow.3', {}),
        child: Text('Action 3'),
      ),
    ],
  );
}
