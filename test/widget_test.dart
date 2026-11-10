import 'package:flutter_test/flutter_test.dart';
import 'package:dots_memories_danna/main.dart';
import 'package:dots_memories_danna/services/appwrite_auth_service.dart';
import 'package:dots_memories_danna/services/storage_service.dart';

void main() {
  testWidgets('Dots Memories smoke test', (WidgetTester tester) async {
    final storageService = StorageService();
    final authService = AppwriteAuthService();
    await tester.pumpWidget(DotsMemoriesApp(
      storageService: storageService,
      authService: authService,
    ));
    await tester.pump(const Duration(milliseconds: 50));

    expect(find.textContaining('Danna'), findsWidgets);
  });
}
