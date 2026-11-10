import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:grana_amiga/app.dart';

void main() {
  testWidgets('app starts on the welcome screen', (tester) async {
    await tester.pumpWidget(const GranaAmigaApp());
    await tester.pump();
    expect(find.byType(MaterialApp), findsOneWidget);
    expect(find.byType(Scaffold), findsWidgets);
  });
}
