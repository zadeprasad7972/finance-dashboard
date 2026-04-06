import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:finance_flutter/main.dart';
import 'package:finance_flutter/providers/auth_provider.dart';

void main() {
  testWidgets('App renders login screen when not authenticated', (WidgetTester tester) async {
    final auth = AuthProvider();
    await tester.pumpWidget(
      ChangeNotifierProvider.value(
        value: auth,
        child: const FinanceApp(),
      ),
    );
    expect(find.text('Finance Dashboard'), findsOneWidget);
    expect(find.text('Sign in to your account'), findsOneWidget);
  });
}
