// ignore_for_file: argument_type_not_assignable, undefined_function
import 'package:flutter/material.dart';
import 'package:rfw_gen/rfw_gen.dart';

// ─── 기본: 인사 카드 ───

@RfwWidget('greeting')
Widget buildGreeting() {
  return Column(
    mainAxisAlignment: MainAxisAlignment.center,
    children: [
      Text('Hello, RFW!'),
      SizedBox(height: 16.0),
      Container(
        color: Color(0xFF2196F3),
        padding: EdgeInsets.all(16.0),
        child: Text('Welcome'),
      ),
    ],
  );
}

// ─── 프로필 카드 ───

@RfwWidget('profileCard')
Widget buildProfileCard() {
  return Container(
    padding: EdgeInsets.all(24.0),
    color: Color(0xFFF5F5F5),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.start,
      children: [
        Container(
          width: 64.0,
          height: 64.0,
          color: Color(0xFF9C27B0),
          child: Center(
            child: Text('BP'),
          ),
        ),
        SizedBox(width: 16.0),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('BottlePumpkin'),
            SizedBox(height: 4.0),
            Text('Flutter Developer'),
          ],
        ),
      ],
    ),
  );
}

// ─── 통계 대시보드 ───

@RfwWidget('statsDashboard')
Widget buildStatsDashboard() {
  return Column(
    children: [
      Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          Container(
            width: 100.0,
            padding: EdgeInsets.all(16.0),
            color: Color(0xFF4CAF50),
            child: Column(
              children: [
                Text('128'),
                SizedBox(height: 4.0),
                Text('Users'),
              ],
            ),
          ),
          Container(
            width: 100.0,
            padding: EdgeInsets.all(16.0),
            color: Color(0xFF2196F3),
            child: Column(
              children: [
                Text('56'),
                SizedBox(height: 4.0),
                Text('Active'),
              ],
            ),
          ),
          Container(
            width: 100.0,
            padding: EdgeInsets.all(16.0),
            color: Color(0xFFFF9800),
            child: Column(
              children: [
                Text('89%'),
                SizedBox(height: 4.0),
                Text('Rate'),
              ],
            ),
          ),
        ],
      ),
    ],
  );
}

// ─── 리스트 아이템 ───

@RfwWidget('listItem')
Widget buildListItem() {
  return Container(
    padding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
    child: Row(
      children: [
        Container(
          width: 40.0,
          height: 40.0,
          color: Color(0xFFE0E0E0),
          child: Center(
            child: Text('1'),
          ),
        ),
        SizedBox(width: 12.0),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('List Item Title'),
            SizedBox(height: 2.0),
            Text('Subtitle description here'),
          ],
        ),
      ],
    ),
  );
}

// ─── 배너 ───

@RfwWidget('banner')
Widget buildBanner() {
  return Container(
    padding: EdgeInsets.all(20.0),
    color: Color(0xFF1565C0),
    child: Column(
      children: [
        Text('Special Offer'),
        SizedBox(height: 8.0),
        Text('Get 50% off on all items'),
        SizedBox(height: 16.0),
        Container(
          padding: EdgeInsets.symmetric(horizontal: 24.0, vertical: 12.0),
          color: Color(0xFFFFFFFF),
          child: Text('Shop Now'),
        ),
      ],
    ),
  );
}

// ─── 레이아웃 데모: 중첩 Row/Column ───

@RfwWidget('gridLayout')
Widget buildGridLayout() {
  return Column(
    children: [
      Row(
        children: [
          Container(
            width: 80.0,
            height: 80.0,
            color: Color(0xFFE91E63),
            child: Center(child: Text('A')),
          ),
          SizedBox(width: 8.0),
          Container(
            width: 80.0,
            height: 80.0,
            color: Color(0xFF9C27B0),
            child: Center(child: Text('B')),
          ),
          SizedBox(width: 8.0),
          Container(
            width: 80.0,
            height: 80.0,
            color: Color(0xFF3F51B5),
            child: Center(child: Text('C')),
          ),
        ],
      ),
      SizedBox(height: 8.0),
      Row(
        children: [
          Container(
            width: 80.0,
            height: 80.0,
            color: Color(0xFF009688),
            child: Center(child: Text('D')),
          ),
          SizedBox(width: 8.0),
          Container(
            width: 80.0,
            height: 80.0,
            color: Color(0xFF4CAF50),
            child: Center(child: Text('E')),
          ),
          SizedBox(width: 8.0),
          Container(
            width: 80.0,
            height: 80.0,
            color: Color(0xFFFF9800),
            child: Center(child: Text('F')),
          ),
        ],
      ),
    ],
  );
}

// ─── 빈 상태 ───

@RfwWidget('emptyState')
Widget buildEmptyState() {
  return Center(
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          width: 80.0,
          height: 80.0,
          color: Color(0xFFEEEEEE),
          child: Center(child: Text('?')),
        ),
        SizedBox(height: 16.0),
        Text('No items found'),
        SizedBox(height: 8.0),
        Text('Try adding something new'),
      ],
    ),
  );
}

// ─── 스크롤 리스트 ───

@RfwWidget('scrollableList')
Widget buildScrollableList() {
  return ListView(
    padding: EdgeInsets.all(16),
    children: [
      Padding(
        padding: EdgeInsets.symmetric(vertical: 8),
        child: Row(
          children: [
            SizedBox(width: 8),
            Text('Item 1'),
          ],
        ),
      ),
      Padding(
        padding: EdgeInsets.symmetric(vertical: 8),
        child: Row(
          children: [
            SizedBox(width: 8),
            Text('Item 2'),
          ],
        ),
      ),
      Padding(
        padding: EdgeInsets.symmetric(vertical: 8),
        child: Row(
          children: [
            SizedBox(width: 8),
            Text('Item 3'),
          ],
        ),
      ),
    ],
  );
}

// ─── 오버레이 레이아웃 ───

@RfwWidget('overlayLayout')
Widget buildOverlayLayout() {
  return Stack(
    children: [
      Container(
        color: Color(0xFFE0E0E0),
        width: 300.0,
        height: 200.0,
      ),
      Positioned(
        top: 10.0,
        left: 10.0,
        child: Opacity(
          opacity: 0.9,
          child: Container(
            color: Color(0xFF42A5F5),
            width: 120.0,
            height: 80.0,
            child: Center(
              child: Text('Overlay'),
            ),
          ),
        ),
      ),
    ],
  );
}

// ─── 반응형 Wrap ───

@RfwWidget('responsiveWrap')
Widget buildResponsiveWrap() {
  return SafeArea(
    child: Wrap(
      spacing: 8.0,
      runSpacing: 8.0,
      children: [
        Container(
          color: Color(0xFF42A5F5),
          padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          child: Text('Flutter'),
        ),
        Container(
          color: Color(0xFF66BB6A),
          padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          child: Text('Dart'),
        ),
        Container(
          color: Color(0xFFFF7043),
          padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          child: Text('RFW'),
        ),
      ],
    ),
  );
}

// ─── 애니메이션 카드 ───

@RfwWidget('animatedCard')
Widget buildAnimatedCard() {
  return Opacity(
    opacity: 0.95,
    child: ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: Container(
        color: Color(0xFFF5F5F5),
        padding: EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Animated Card'),
            SizedBox(height: 8),
            Text('With ClipRRect'),
          ],
        ),
      ),
    ),
  );
}

// ─── Expanded 레이아웃 ───

@RfwWidget('expandedLayout')
Widget buildExpandedLayout() {
  return Column(
    children: [
      Expanded(
        flex: 2,
        child: Container(
          color: Color(0xFF42A5F5),
          child: Center(
            child: Text('Top (flex: 2)'),
          ),
        ),
      ),
      Expanded(
        child: Container(
          color: Color(0xFF66BB6A),
          child: Center(
            child: Text('Bottom (flex: 1)'),
          ),
        ),
      ),
    ],
  );
}

// ─── 인터랙티브 버튼 ───

@RfwWidget('interactiveButton')
Widget buildInteractiveButton() {
  return ElevatedButton(
    onPressed: RfwHandler.event('button.click'),
    child: Text('Click Me'),
  );
}

// ─── 토글 카드 ───

@RfwWidget('toggleCard')
Widget buildToggleCard() {
  return GestureDetector(
    onTap: RfwHandler.setState('selected', true),
    child: Card(
      color: Color(0xFF42A5F5),
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Text('Tap to select'),
      ),
    ),
  );
}

// ─── 스캐폴드 페이지 ───

@RfwWidget('scaffoldPage')
Widget buildScaffoldPage() {
  return Scaffold(
    appBar: AppBar(
      title: Text('My Page'),
    ),
    body: Center(
      child: Text('Hello Material'),
    ),
  );
}

// ─── 커스텀 위젯 데모 ───

@RfwWidget('customWidgetDemo')
Widget buildCustomWidgetDemo() {
  return Column(
    children: [
      CustomText(text: 'Hello Custom Widget', fontType: 'heading', color: 0xFF4169FF),
      SizedBox(height: 16.0),
      CustomBounceTapper(
        onTap: RfwHandler.event('custom.tap', {'action': 'greet'}),
        child: Container(
          padding: EdgeInsets.all(16.0),
          color: Color(0xFF4CAF50),
          child: CustomText(text: 'Tap Me', fontType: 'button', color: 0xFFFFFFFF),
        ),
      ),
      SizedBox(height: 16.0),
      NullConditionalWidget(
        child: CustomText(text: 'Visible Content', fontType: 'body'),
        nullChild: CustomText(text: 'Fallback (null)', fontType: 'caption', color: 0xFF999999),
      ),
    ],
  );
}
