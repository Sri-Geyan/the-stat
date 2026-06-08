import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:the_stat/core/storage/hive_registry.dart';
import 'package:the_stat/main.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

void main() {
  setUpAll(() async {
    final tempDir = await Directory.systemTemp.createTemp('the_stat_widget_test');
    Hive.init(tempDir.path);
    await Hive.openBox(HiveRegistry.matchesBoxName);
  });

  testWidgets('App mounts and shows dashboard text', (WidgetTester tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: TheStatApp(),
      ),
    );

    // Verify Dashboard screen title matches brand text
    expect(find.text('THE STAT'), findsOneWidget);
    expect(find.text('TAMIL NADU LOCAL SCORING'), findsOneWidget);
  });
}
