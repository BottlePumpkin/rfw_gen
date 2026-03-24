import 'package:rfw/rfw.dart';

/// All mock data for the example app.
class MockData {
  static void setupCatalog(DynamicContent data) {
    data.update('catalog', <String, Object>{
      'sampleItems': <Object>[
        <String, Object>{'name': 'Apple', 'description': 'A fresh red apple'},
        <String, Object>{'name': 'Banana', 'description': 'A ripe yellow banana'},
        <String, Object>{'name': 'Cherry', 'description': 'Sweet dark cherries'},
      ],
      'tags': <Object>['Flutter', 'RFW', 'Dart', 'Widget', 'Remote', 'Server-Driven'],
    });
  }

  static void setupShop(DynamicContent data) {
    data.update('banners', <String, Object>{
      'items': <Object>[
        <String, Object>{
          'title': '여름 세일 50%',
          'subtitle': '전 상품 할인 중',
          'color': 0xFFFF6B6B,
        },
        <String, Object>{
          'title': '신상품 입고',
          'subtitle': '이번 주 신상품을 만나보세요',
          'color': 0xFF4ECDC4,
        },
      ],
    });

    data.update('categories', <String, Object>{
      'items': <Object>[
        <String, Object>{'name': '의류', 'icon': <String, Object>{'icon': 0xe14f, 'fontFamily': 'MaterialIcons'}},
        <String, Object>{'name': '전자기기', 'icon': <String, Object>{'icon': 0xe1e3, 'fontFamily': 'MaterialIcons'}},
        <String, Object>{'name': '식품', 'icon': <String, Object>{'icon': 0xe532, 'fontFamily': 'MaterialIcons'}},
        <String, Object>{'name': '도서', 'icon': <String, Object>{'icon': 0xe02d, 'fontFamily': 'MaterialIcons'}},
      ],
    });

    data.update('recommended', <String, Object>{
      'items': <Object>[
        <String, Object>{
          'id': 1,
          'name': '무선 이어폰',
          'price': 45000,
          'image': 'https://picsum.photos/seed/earbuds/200',
          'inStock': true,
        },
        <String, Object>{
          'id': 2,
          'name': '스마트 워치',
          'price': 89000,
          'image': 'https://picsum.photos/seed/watch/200',
          'inStock': true,
        },
        <String, Object>{
          'id': 3,
          'name': '블루투스 스피커',
          'price': 35000,
          'image': 'https://picsum.photos/seed/speaker/200',
          'inStock': false,
        },
      ],
    });

    data.update('products', <String, Object>{
      'items': <Object>[
        <String, Object>{
          'id': 1,
          'name': '무선 이어폰',
          'price': 45000,
          'description': '고음질 블루투스 이어폰. 노이즈 캔슬링 지원.',
          'image': 'https://picsum.photos/seed/earbuds/400',
          'inStock': true,
          'category': '전자기기',
        },
        <String, Object>{
          'id': 2,
          'name': '스마트 워치',
          'price': 89000,
          'description': '건강 모니터링과 알림 기능을 갖춘 스마트 워치.',
          'image': 'https://picsum.photos/seed/watch/400',
          'inStock': true,
          'category': '전자기기',
        },
        <String, Object>{
          'id': 3,
          'name': '블루투스 스피커',
          'price': 35000,
          'description': '휴대용 방수 블루투스 스피커.',
          'image': 'https://picsum.photos/seed/speaker/400',
          'inStock': false,
          'category': '전자기기',
        },
        <String, Object>{
          'id': 4,
          'name': '코튼 티셔츠',
          'price': 25000,
          'description': '편안한 100% 면 티셔츠.',
          'image': 'https://picsum.photos/seed/tshirt/400',
          'inStock': true,
          'category': '의류',
        },
      ],
    });

    data.update('cart', <String, Object>{
      'items': <Object>[
        <String, Object>{
          'id': 1,
          'name': '무선 이어폰',
          'price': 45000,
          'quantity': 2,
        },
        <String, Object>{
          'id': 4,
          'name': '코튼 티셔츠',
          'price': 25000,
          'quantity': 1,
        },
      ],
      'totalPrice': 115000,
      'itemCount': 3,
    });

    data.update('order', <String, Object>{
      'orderNumber': 'ORD-2026-0001',
      'itemCount': 3,
      'totalPrice': 115000,
    });

    data.update('product', <String, Object>{
      'id': 1,
      'name': '무선 이어폰',
      'price': 45000,
      'description': '고음질 블루투스 이어폰. 노이즈 캔슬링 지원.',
      'image': 'https://picsum.photos/seed/earbuds/400',
      'inStock': true,
    });
  }
}
