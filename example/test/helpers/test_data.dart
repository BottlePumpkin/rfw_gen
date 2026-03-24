import 'package:rfw/rfw.dart';
import 'package:rfw_gen_example/data/mock_data.dart';

/// 테스트용 mock data를 DynamicContent에 주입.
/// example app의 MockData를 그대로 재사용.
void setupTestData(DynamicContent data) {
  MockData.setupCatalog(data);
  MockData.setupShop(data);
}
