// ignore_for_file: argument_type_not_assignable, list_element_type_not_assignable
import 'package:flutter/material.dart';
import 'package:rfw_gen/rfw_gen.dart';

// ============================================================
// Screen 1: Shop Home
// ============================================================

@RfwWidget('shopHome')
Widget buildShopHome() {
  return SingleChildScrollView(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Promotion Banner
        Container(
          height: 160.0,
          padding: const EdgeInsets.all(24.0),
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment(-1.0, 0.0),
              end: Alignment(1.0, 0.0),
              colors: [Color(0xFFFF6B6B), Color(0xFFFF8E53)],
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                DataRef('banners.items.0.title'),
                style: const TextStyle(fontSize: 24.0, fontWeight: FontWeight.bold, color: Color(0xFFFFFFFF)),
              ),
              SizedBox(height: 4.0),
              Text(
                DataRef('banners.items.0.subtitle'),
                style: const TextStyle(fontSize: 14.0, color: Color(0xFFFFFFFF)),
              ),
            ],
          ),
        ),

        // Categories header
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Text(
            '카테고리',
            style: const TextStyle(fontSize: 18.0, fontWeight: FontWeight.bold),
          ),
        ),
        // Category list
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              RfwFor(
                items: DataRef('categories.items'),
                itemName: 'cat',
                builder: (cat) => GestureDetector(
                  onTap: RfwHandler.event('navigate', {'page': 'productList'}),
                  child: Column(
                    children: [
                      Icon(cat['icon'], size: 32.0, color: const Color(0xFF2196F3)),
                      SizedBox(height: 4.0),
                      Text(cat['name'], style: const TextStyle(fontSize: 12.0)),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),

        // Recommended header
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Text(
            '추천 상품',
            style: const TextStyle(fontSize: 18.0, fontWeight: FontWeight.bold),
          ),
        ),
        // Recommended products horizontal scroll
        SizedBox(
          height: 180.0,
          child: ListView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            children: [
              RfwFor(
                items: DataRef('recommended.items'),
                itemName: 'product',
                builder: (product) => GestureDetector(
                  onTap: RfwHandler.event('navigate', {'page': 'productDetail'}),
                  child: Container(
                    width: 140.0,
                    margin: const EdgeInsets.only(right: 12.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        ClipRRect(
                          borderRadius: const BorderRadius.all(Radius.circular(8)),
                          child: Image(
                            image: NetworkImage(product['image']),
                            width: 140.0,
                            height: 100.0,
                            fit: BoxFit.cover,
                          ),
                        ),
                        SizedBox(height: 8.0),
                        Text(
                          product['name'],
                          style: const TextStyle(fontSize: 14.0, fontWeight: FontWeight.bold),
                        ),
                        Text(
                          RfwConcat([product['price'], '원']),
                          style: const TextStyle(fontSize: 13.0, color: Color(0xFF757575)),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    ),
  );
}

// ============================================================
// Screen 2: Product List
// ============================================================

@RfwWidget('productList')
Widget buildProductList() {
  return Column(
    children: [
      Container(
        padding: const EdgeInsets.all(16.0),
        color: const Color(0xFF2196F3),
        child: Text(
          '상품 목록',
          style: const TextStyle(fontSize: 20.0, fontWeight: FontWeight.bold, color: Color(0xFFFFFFFF)),
        ),
      ),
      Expanded(
        child: ListView(
          padding: const EdgeInsets.all(8.0),
          children: [
            RfwFor(
              items: DataRef('products.items'),
              itemName: 'item',
              builder: (item) => GestureDetector(
                onTap: RfwHandler.event('navigate', {'page': 'productDetail'}),
                child: Card(
                  margin: const EdgeInsets.all(4.0),
                  child: Padding(
                    padding: const EdgeInsets.all(12.0),
                    child: Row(
                      children: [
                        ClipRRect(
                          borderRadius: const BorderRadius.all(Radius.circular(8)),
                          child: Image(
                            image: NetworkImage(item['image']),
                            width: 80.0,
                            height: 80.0,
                            fit: BoxFit.cover,
                          ),
                        ),
                        SizedBox(width: 12.0),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                item['name'],
                                style: const TextStyle(fontSize: 16.0, fontWeight: FontWeight.bold),
                              ),
                              SizedBox(height: 4.0),
                              Text(
                                RfwConcat([item['price'], '원']),
                                style: const TextStyle(fontSize: 14.0, color: Color(0xFF757575)),
                              ),
                              SizedBox(height: 4.0),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 2.0),
                                color: RfwSwitchValue<int>(
                                  value: item['inStock'],
                                  cases: {true: 0xFF4CAF50, false: 0xFFFF5722},
                                ),
                                child: Text(
                                  RfwSwitchValue<String>(
                                    value: item['inStock'],
                                    cases: {true: '재고 있음', false: '품절'},
                                  ),
                                  style: const TextStyle(color: Color(0xFFFFFFFF), fontSize: 12.0),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    ],
  );
}

// ============================================================
// Screen 3: Product Detail
// ============================================================

@RfwWidget('productDetail', state: {'quantity': 1})
Widget buildProductDetail() {
  return SingleChildScrollView(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Product Image
        Image(
          image: NetworkImage(DataRef('product.image')),
          width: 400.0,
          height: 300.0,
          fit: BoxFit.cover,
        ),

        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Name + Price
              Text(
                DataRef('product.name'),
                style: const TextStyle(fontSize: 24.0, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 8.0),
              Text(
                RfwConcat([DataRef('product.price'), '원']),
                style: const TextStyle(fontSize: 20.0, color: Color(0xFF2196F3), fontWeight: FontWeight.bold),
              ),

              SizedBox(height: 16.0),

              // Stock status
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 4.0),
                color: RfwSwitchValue<int>(
                  value: DataRef('product.inStock'),
                  cases: {true: 0xFF4CAF50, false: 0xFFFF5722},
                ),
                child: Text(
                  RfwSwitchValue<String>(
                    value: DataRef('product.inStock'),
                    cases: {true: '재고 있음', false: '품절'},
                  ),
                  style: const TextStyle(color: Color(0xFFFFFFFF)),
                ),
              ),

              SizedBox(height: 16.0),

              // Description
              Text(
                DataRef('product.description'),
                style: const TextStyle(fontSize: 15.0, color: Color(0xFF616161)),
              ),

              SizedBox(height: 24.0),

              // Quantity selector
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  ElevatedButton(
                    onPressed: RfwHandler.event('quantity.decrease', {}),
                    child: Text('-'),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24.0),
                    child: Text(
                      StateRef('quantity'),
                      style: const TextStyle(fontSize: 20.0, fontWeight: FontWeight.bold),
                    ),
                  ),
                  ElevatedButton(
                    onPressed: RfwHandler.event('quantity.increase', {}),
                    child: Text('+'),
                  ),
                ],
              ),

              SizedBox(height: 24.0),

              // Add to cart button
              ElevatedButton(
                onPressed: RfwHandler.event('addToCart', {'id': DataRef('product.id')}),
                child: Text('장바구니에 담기'),
              ),
            ],
          ),
        ),
      ],
    ),
  );
}

// ============================================================
// Screen 4: Cart
// ============================================================

@RfwWidget('cart')
Widget buildCart() {
  return Column(
    children: [
      Container(
        padding: const EdgeInsets.all(16.0),
        color: const Color(0xFF2196F3),
        child: Text(
          '장바구니',
          style: const TextStyle(fontSize: 20.0, fontWeight: FontWeight.bold, color: Color(0xFFFFFFFF)),
        ),
      ),

      Expanded(
        child: ListView(
          padding: const EdgeInsets.all(8.0),
          children: [
            RfwFor(
              items: DataRef('cart.items'),
              itemName: 'cartItem',
              builder: (cartItem) => Card(
                margin: const EdgeInsets.symmetric(vertical: 4.0),
                child: ListTile(
                  title: Text(cartItem['name']),
                  subtitle: Text(RfwConcat([cartItem['price'], '원 × ', cartItem['quantity']])),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      GestureDetector(
                        onTap: RfwHandler.event('cart.decrease', {'id': cartItem['id']}),
                        child: Icon(RfwIcon.remove, color: const Color(0xFF757575)),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 8.0),
                        child: Text(
                          cartItem['quantity'],
                          style: const TextStyle(fontSize: 16.0, fontWeight: FontWeight.bold),
                        ),
                      ),
                      GestureDetector(
                        onTap: RfwHandler.event('cart.increase', {'id': cartItem['id']}),
                        child: Icon(RfwIcon.add, color: const Color(0xFF2196F3)),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),

      // Total + Checkout
      Container(
        padding: const EdgeInsets.all(16.0),
        color: const Color(0xFFF5F5F5),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '총 금액',
                  style: const TextStyle(fontSize: 18.0, fontWeight: FontWeight.bold),
                ),
                Text(
                  RfwConcat([DataRef('cart.totalPrice'), '원']),
                  style: const TextStyle(fontSize: 20.0, color: Color(0xFF2196F3), fontWeight: FontWeight.bold),
                ),
              ],
            ),
            SizedBox(height: 12.0),
            ElevatedButton(
              onPressed: RfwHandler.event('checkout', {}),
              child: Text(RfwConcat(['주문하기 (', DataRef('cart.itemCount'), '개)'])),
            ),
          ],
        ),
      ),
    ],
  );
}

// ============================================================
// Screen 5: Order Complete
// ============================================================

@RfwWidget('orderComplete')
Widget buildOrderComplete() {
  return Center(
    child: Padding(
      padding: const EdgeInsets.all(32.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(RfwIcon.check, size: 80.0, color: const Color(0xFF4CAF50)),
          SizedBox(height: 24.0),
          Text(
            '주문이 완료되었습니다!',
            style: const TextStyle(fontSize: 24.0, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 12.0),
          Text(
            RfwConcat(['주문번호: ', DataRef('order.orderNumber')]),
            style: const TextStyle(fontSize: 16.0, color: Color(0xFF757575)),
          ),
          SizedBox(height: 8.0),
          Text(
            RfwConcat(['총 ', DataRef('order.itemCount'), '개 상품 / ', DataRef('order.totalPrice'), '원']),
            style: const TextStyle(fontSize: 14.0, color: Color(0xFF757575)),
          ),
          SizedBox(height: 32.0),
          ElevatedButton(
            onPressed: RfwHandler.event('navigate', {'page': 'shopHome'}),
            child: Text('홈으로 돌아가기'),
          ),
        ],
      ),
    ),
  );
}
