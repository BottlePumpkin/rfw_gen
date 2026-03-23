import 'package:flutter/widgets.dart';
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
