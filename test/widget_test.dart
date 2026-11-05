import 'package:flutter_test/flutter_test.dart';
import 'package:dots_memories_danna/main.dart';
import 'package:dots_memories_danna/services/storage_service.dart';

void main() {
  testWidgets('Dots Memories smoke test', (WidgetTester tester) async {
    final storageService = StorageService();
    await tester.pumpWidget(DotsMemoriesApp(storageService: storageService));
    await tester.pump();

    expect(find.textContaining('Danna'), findsWidgets);
  });
}
