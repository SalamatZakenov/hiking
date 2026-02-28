import 'package:flutter_test/flutter_test.dart';
import 'package:hiking/main.dart';
import 'package:hiking/core/di/locator.dart';

void main() {
  testWidgets('App smoke test', (WidgetTester tester) async {
    // Обязательно инициализируем DI перед запуском приложения в тесте
    setupLocator();

    // Запускаем наше приложение
    await tester.pumpWidget(const HikingApp());
  });
}