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
    onTap: RfwHandler.event('card.toggle', {'action': 'select'}),
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

// ══════════════════════════════════════════════════════════════════════
// 동적 기능 예제 (Dynamic Features Examples)
// ══════════════════════════════════════════════════════════════════════

// ─── 1. 동적 인사 — DataRef + RfwConcat ───
// data.user.name 을 참조하여 동적으로 인사 문구를 구성합니다.

@RfwWidget('dynamicGreeting')
Widget buildDynamicGreeting() {
  return Container(
    padding: EdgeInsets.all(24.0),
    color: Color(0xFFF3E5F5),
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(RfwConcat(['Hello, ', DataRef('user.name'), '!'])),
        SizedBox(height: 8.0),
        Text(RfwConcat(['Your role: ', DataRef('user.role')])),
        SizedBox(height: 16.0),
        Text(DataRef('user.bio')),
      ],
    ),
  );
}

// ─── 2. 동적 리스트 — RfwFor + LoopVar ───
// data.items 리스트를 순회하며 각 아이템의 name과 description을 표시합니다.

@RfwWidget('dynamicList')
Widget buildDynamicList() {
  return ListView(
    padding: EdgeInsets.all(16.0),
    children: [
      Text('Item List'),
      SizedBox(height: 12.0),
      RfwFor(
        items: DataRef('items'),
        itemName: 'item',
        builder: (item) => Container(
          padding: EdgeInsets.symmetric(vertical: 8.0, horizontal: 12.0),
          child: Row(
            children: [
              Container(
                width: 40.0,
                height: 40.0,
                color: Color(0xFFE3F2FD),
                child: Center(child: Text(item['icon'])),
              ),
              SizedBox(width: 12.0),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(item['name']),
                  SizedBox(height: 2.0),
                  Text(item['description']),
                ],
              ),
            ],
          ),
        ),
      ),
    ],
  );
}

// ─── 3. 조건부 상태 표시 — RfwSwitch + DataRef ───
// data.status 값에 따라 다른 UI를 표시합니다.

@RfwWidget('conditionalStatus')
Widget buildConditionalStatus() {
  return Center(
    child: Container(
      padding: EdgeInsets.all(24.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text('Order Status'),
          SizedBox(height: 16.0),
          RfwSwitch(
            value: DataRef('order.status'),
            cases: {
              'pending': Container(
                padding: EdgeInsets.all(16.0),
                color: Color(0xFFFFF9C4),
                child: Column(
                  children: [
                    Text('Pending'),
                    SizedBox(height: 4.0),
                    Text('Your order is being processed'),
                  ],
                ),
              ),
              'shipped': Container(
                padding: EdgeInsets.all(16.0),
                color: Color(0xFFE3F2FD),
                child: Column(
                  children: [
                    Text('Shipped'),
                    SizedBox(height: 4.0),
                    Text('Your order is on the way'),
                  ],
                ),
              ),
              'delivered': Container(
                padding: EdgeInsets.all(16.0),
                color: Color(0xFFE8F5E9),
                child: Column(
                  children: [
                    Text('Delivered'),
                    SizedBox(height: 4.0),
                    Text('Your order has arrived'),
                  ],
                ),
              ),
            },
            defaultCase: Container(
              padding: EdgeInsets.all(16.0),
              color: Color(0xFFEEEEEE),
              child: Text('Unknown status'),
            ),
          ),
        ],
      ),
    ),
  );
}

// ─── 4. 토글 버튼 — StateRef + setState + state 선언 ───
// 위젯 로컬 상태(pressed)를 사용하여 탭 시 시각적 피드백을 제공합니다.

@RfwWidget('toggleButton', state: {'pressed': false})
Widget buildToggleButton() {
  return GestureDetector(
    onTapDown: RfwHandler.setState('pressed', true),
    onTapUp: RfwHandler.setState('pressed', false),
    onTapCancel: RfwHandler.setState('pressed', false),
    child: Container(
      padding: EdgeInsets.symmetric(horizontal: 32.0, vertical: 16.0),
      color: RfwSwitchValue(
        value: StateRef('pressed'),
        cases: {
          true: 0xFF1565C0,
          false: 0xFF42A5F5,
        },
      ),
      child: Center(
        child: RfwSwitch(
          value: StateRef('pressed'),
          cases: {
            true: Text('Pressing...'),
            false: Text('Press Me'),
          },
        ),
      ),
    ),
  );
}

// ─── 5. 사용자 프로필 — DataRef + ArgsRef + RfwConcat + RfwSwitch ───
// 여러 동적 기능을 조합하여 사용자 프로필 카드를 구성합니다.

@RfwWidget('userProfile')
Widget buildUserProfile() {
  return Container(
    padding: EdgeInsets.all(20.0),
    color: Color(0xFFF5F5F5),
    child: Column(
      children: [
        Row(
          children: [
            Container(
              width: 64.0,
              height: 64.0,
              color: Color(0xFF9C27B0),
              child: Center(
                child: Text(DataRef('profile.initials')),
              ),
            ),
            SizedBox(width: 16.0),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(DataRef('profile.displayName')),
                SizedBox(height: 4.0),
                Text(RfwConcat([DataRef('profile.department'), ' - ', DataRef('profile.title')])),
              ],
            ),
          ],
        ),
        SizedBox(height: 16.0),
        RfwSwitch(
          value: DataRef('profile.isVerified'),
          cases: {
            true: Container(
              padding: EdgeInsets.symmetric(horizontal: 12.0, vertical: 6.0),
              color: Color(0xFF4CAF50),
              child: Text('Verified Account'),
            ),
            false: Container(
              padding: EdgeInsets.symmetric(horizontal: 12.0, vertical: 6.0),
              color: Color(0xFFFF9800),
              child: Text('Unverified — Please verify your email'),
            ),
          },
        ),
        SizedBox(height: 12.0),
        Text(RfwConcat(['Member since ', DataRef('profile.joinDate')])),
      ],
    ),
  );
}

// ─── 6. 상품 목록 — RfwFor + RfwSwitch + 이벤트 (동적 페이로드) ───
// 상품 리스트를 순회하고, 재고 상태에 따라 UI를 분기하며,
// 탭 시 상품 ID가 포함된 이벤트를 발송합니다.

@RfwWidget('productList')
Widget buildProductList() {
  return ListView(
    padding: EdgeInsets.all(12.0),
    children: [
      Text('Products'),
      SizedBox(height: 8.0),
      RfwFor(
        items: DataRef('products'),
        itemName: 'product',
        builder: (product) => GestureDetector(
          onTap: RfwHandler.event('product.select', {
            'productId': ArgsRef('product.id'),
            'action': 'view',
          }),
          child: Container(
            padding: EdgeInsets.all(12.0),
            child: Row(
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(product['name']),
                    SizedBox(height: 4.0),
                    Text(product['price']),
                  ],
                ),
                SizedBox(width: 16.0),
                RfwSwitch(
                  value: product['inStock'],
                  cases: {
                    true: Container(
                      padding: EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
                      color: Color(0xFF4CAF50),
                      child: Text('In Stock'),
                    ),
                    false: Container(
                      padding: EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
                      color: Color(0xFFE0E0E0),
                      child: Text('Sold Out'),
                    ),
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    ],
  );
}

// ─── 7. 알림 목록 — RfwFor + RfwConcat + 이벤트 ───
// 알림 리스트를 순회하며 포맷된 텍스트와 해제 이벤트를 보여줍니다.

@RfwWidget('notificationList')
Widget buildNotificationList() {
  return ListView(
    padding: EdgeInsets.all(16.0),
    children: [
      Text('Notifications'),
      SizedBox(height: 12.0),
      RfwFor(
        items: DataRef('notifications'),
        itemName: 'notif',
        builder: (notif) => Container(
          padding: EdgeInsets.symmetric(vertical: 8.0, horizontal: 12.0),
          child: Row(
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(RfwConcat([notif['sender'], ': ', notif['message']])),
                  SizedBox(height: 4.0),
                  Text(notif['time']),
                ],
              ),
              SizedBox(width: 8.0),
              GestureDetector(
                onTap: RfwHandler.event('notification.dismiss', {
                  'notifId': ArgsRef('notif.id'),
                }),
                child: Container(
                  padding: EdgeInsets.all(8.0),
                  color: Color(0xFFEF5350),
                  child: Text('X'),
                ),
              ),
            ],
          ),
        ),
      ),
    ],
  );
}

// ─── 8. 탭 선택기 — state + switch + 다중 핸들러 ───
// 로컬 상태를 사용하여 3개 탭 사이를 전환합니다.

@RfwWidget('tabSelector', state: {'activeTab': 0})
Widget buildTabSelector() {
  return Column(
    children: [
      // 탭 바
      Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          GestureDetector(
            onTap: RfwHandler.setState('activeTab', 0),
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 20.0, vertical: 12.0),
              color: RfwSwitchValue(
                value: StateRef('activeTab'),
                cases: {0: 0xFF1976D2},
                defaultCase: 0xFFBBDEFB,
              ),
              child: Text('Home'),
            ),
          ),
          GestureDetector(
            onTap: RfwHandler.setState('activeTab', 1),
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 20.0, vertical: 12.0),
              color: RfwSwitchValue(
                value: StateRef('activeTab'),
                cases: {1: 0xFF1976D2},
                defaultCase: 0xFFBBDEFB,
              ),
              child: Text('Search'),
            ),
          ),
          GestureDetector(
            onTap: RfwHandler.setState('activeTab', 2),
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 20.0, vertical: 12.0),
              color: RfwSwitchValue(
                value: StateRef('activeTab'),
                cases: {2: 0xFF1976D2},
                defaultCase: 0xFFBBDEFB,
              ),
              child: Text('Settings'),
            ),
          ),
        ],
      ),
      SizedBox(height: 16.0),
      // 탭 콘텐츠
      RfwSwitch(
        value: StateRef('activeTab'),
        cases: {
          0: Center(
            child: Text('Home Content'),
          ),
          1: Center(
            child: Text('Search Content'),
          ),
          2: Center(
            child: Text('Settings Content'),
          ),
        },
      ),
    ],
  );
}

// ─── 9. 검색 결과 — DataRef + RfwFor + 조건부 빈 상태 ───
// 결과가 있으면 리스트를 표시하고, 없으면 빈 상태를 표시합니다.

@RfwWidget('searchResults')
Widget buildSearchResults() {
  return Column(
    children: [
      Container(
        padding: EdgeInsets.all(16.0),
        color: Color(0xFFF5F5F5),
        child: Text(RfwConcat(['Results for "', DataRef('search.query'), '"'])),
      ),
      SizedBox(height: 8.0),
      RfwSwitch(
        value: DataRef('search.hasResults'),
        cases: {
          true: ListView(
            shrinkWrap: true,
            children: [
              RfwFor(
                items: DataRef('search.results'),
                itemName: 'result',
                builder: (result) => Container(
                  padding: EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(result['title']),
                      SizedBox(height: 2.0),
                      Text(result['snippet']),
                    ],
                  ),
                ),
              ),
            ],
          ),
          false: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                SizedBox(height: 32.0),
                Text('No results found'),
                SizedBox(height: 8.0),
                Text('Try a different search term'),
              ],
            ),
          ),
        },
      ),
    ],
  );
}

// ─── 10. 설정 토글 — state + switch + 이벤트 디스패치 ───
// 로컬 상태를 토글하면서 동시에 호스트 앱에 이벤트를 전송합니다.

@RfwWidget('settingsToggle', state: {'darkMode': false, 'notifications': true})
Widget buildSettingsToggle() {
  return Container(
    padding: EdgeInsets.all(20.0),
    child: Column(
      children: [
        Text('Settings'),
        SizedBox(height: 20.0),
        // 다크 모드 토글
        GestureDetector(
          onTap: RfwHandler.setState('darkMode', true),
          onDoubleTap: RfwHandler.setState('darkMode', false),
          child: Container(
            padding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
            color: RfwSwitchValue(
              value: StateRef('darkMode'),
              cases: {
                true: 0xFF424242,
                false: 0xFFF5F5F5,
              },
            ),
            child: Row(
              children: [
                Text('Dark Mode'),
                SizedBox(width: 12.0),
                RfwSwitch(
                  value: StateRef('darkMode'),
                  cases: {
                    true: Text('ON'),
                    false: Text('OFF'),
                  },
                ),
              ],
            ),
          ),
        ),
        SizedBox(height: 12.0),
        // 알림 토글
        GestureDetector(
          onTap: RfwHandler.setState('notifications', false),
          onDoubleTap: RfwHandler.setState('notifications', true),
          child: Container(
            padding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
            color: RfwSwitchValue(
              value: StateRef('notifications'),
              cases: {
                true: 0xFFE8F5E9,
                false: 0xFFFCE4EC,
              },
            ),
            child: Row(
              children: [
                Text('Notifications'),
                SizedBox(width: 12.0),
                RfwSwitch(
                  value: StateRef('notifications'),
                  cases: {
                    true: Text('ON'),
                    false: Text('OFF'),
                  },
                ),
              ],
            ),
          ),
        ),
        SizedBox(height: 20.0),
        // 설정 저장 버튼 — 이벤트 디스패치
        GestureDetector(
          onTap: RfwHandler.event('settings.save', {
            'darkMode': StateRef('darkMode'),
            'notifications': StateRef('notifications'),
          }),
          child: Container(
            padding: EdgeInsets.symmetric(horizontal: 24.0, vertical: 12.0),
            color: Color(0xFF1976D2),
            child: Center(child: Text('Save Settings')),
          ),
        ),
      ],
    ),
  );
}

// ─── 11. 채팅 메시지 — RfwFor + RfwConcat + RfwSwitch (발신/수신 분기) ───
// 메시지 리스트를 순회하며 발신/수신에 따라 정렬 방향을 분기합니다.

@RfwWidget('chatMessages')
Widget buildChatMessages() {
  return ListView(
    padding: EdgeInsets.all(12.0),
    children: [
      RfwFor(
        items: DataRef('chat.messages'),
        itemName: 'msg',
        builder: (msg) => Container(
          padding: EdgeInsets.symmetric(vertical: 4.0),
          child: RfwSwitch(
            value: msg['isMine'],
            cases: {
              true: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Container(
                    padding: EdgeInsets.all(12.0),
                    color: Color(0xFF42A5F5),
                    child: Text(msg['text']),
                  ),
                ],
              ),
              false: Row(
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  Container(
                    padding: EdgeInsets.all(12.0),
                    color: Color(0xFFE0E0E0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(msg['sender']),
                        SizedBox(height: 2.0),
                        Text(msg['text']),
                      ],
                    ),
                  ),
                ],
              ),
            },
          ),
        ),
      ),
    ],
  );
}

// ─── 12. 카운터 — state + 증감 핸들러 ───
// 상태를 사용하여 간단한 카운터 UI를 구현합니다.

@RfwWidget('counter', state: {'count': 0})
Widget buildCounter() {
  return Center(
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text('Counter'),
        SizedBox(height: 16.0),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            GestureDetector(
              onTap: RfwHandler.event('counter.decrement'),
              child: Container(
                width: 48.0,
                height: 48.0,
                color: Color(0xFFEF5350),
                child: Center(child: Text('-')),
              ),
            ),
            SizedBox(width: 24.0),
            Container(
              width: 80.0,
              height: 48.0,
              color: Color(0xFFF5F5F5),
              child: Center(
                child: Text(StateRef('count')),
              ),
            ),
            SizedBox(width: 24.0),
            GestureDetector(
              onTap: RfwHandler.event('counter.increment'),
              child: Container(
                width: 48.0,
                height: 48.0,
                color: Color(0xFF66BB6A),
                child: Center(child: Text('+')),
              ),
            ),
          ],
        ),
      ],
    ),
  );
}
