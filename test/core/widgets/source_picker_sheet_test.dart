import 'package:blaze_drop/core/theme/theme.dart';
import 'package:blaze_drop/core/widgets/source_picker_sheet.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Hosts a button that opens the source sheet and reports the picked value.
class _SheetHost extends StatelessWidget {
  const _SheetHost({required this.onPicked});

  final ValueChanged<FilePickSource?> onPicked;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Builder(
        builder: (context) => TextButton(
          onPressed: () async {
            final picked = await showSourcePickerSheet(
              context,
              title: 'STAGE PAYLOAD FROM',
            );
            onPicked(picked);
          },
          child: const Text('OPEN'),
        ),
      ),
    );
  }
}

Future<void> _openSheet(WidgetTester tester) async {
  await tester.tap(find.text('OPEN'));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('offers files, gallery and camera and resolves the tap', (
    tester,
  ) async {
    FilePickSource? picked;
    var resolved = false;
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.dark,
        home: _SheetHost(
          onPicked: (value) {
            picked = value;
            resolved = true;
          },
        ),
      ),
    );

    await _openSheet(tester);

    expect(find.text('STAGE PAYLOAD FROM'), findsOneWidget);
    expect(find.text('FILES'), findsOneWidget);
    expect(find.text('GALLERY'), findsOneWidget);
    expect(find.text('CAMERA'), findsOneWidget);

    await tester.tap(find.text('CAMERA'));
    await tester.pumpAndSettle();

    expect(resolved, isTrue);
    expect(picked, FilePickSource.camera);
  });

  testWidgets('resolves null when dismissed through the barrier', (
    tester,
  ) async {
    FilePickSource? picked = FilePickSource.files;
    var resolved = false;
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.dark,
        home: _SheetHost(
          onPicked: (value) {
            picked = value;
            resolved = true;
          },
        ),
      ),
    );

    await _openSheet(tester);
    await tester.tapAt(const Offset(20, 20));
    await tester.pumpAndSettle();

    expect(find.text('GALLERY'), findsNothing);
    expect(resolved, isTrue);
    expect(picked, isNull);
  });
}
