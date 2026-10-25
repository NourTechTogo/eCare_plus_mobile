import 'package:ecare_plus_mobile/main.dart' as app;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('Startup locks the app to upright portrait', (tester) async {
    final calls = <MethodCall>[];
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
      SystemChannels.platform,
      (call) async {
        calls.add(call);
        return null;
      },
    );
    addTearDown(() {
      tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        SystemChannels.platform,
        null,
      );
    });

    app.main();
    await tester.pump();
    final orientationCalls = calls.where(
      (call) => call.method == 'SystemChrome.setPreferredOrientations',
    );
    expect(orientationCalls, hasLength(1));
    expect(orientationCalls.single.arguments, ['DeviceOrientation.portraitUp']);

    await tester.pumpWidget(const SizedBox.shrink());
  });
}
