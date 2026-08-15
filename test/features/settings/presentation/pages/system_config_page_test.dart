import 'package:blaze_drop/core/config/app_config.dart';
import 'package:blaze_drop/core/theme/theme.dart';
import 'package:blaze_drop/features/settings/domain/use_cases/load_config_use_case.dart';
import 'package:blaze_drop/features/settings/domain/use_cases/reset_config_use_case.dart';
import 'package:blaze_drop/features/settings/domain/use_cases/save_config_use_case.dart';
import 'package:blaze_drop/features/settings/presentation/cubit/settings_cubit.dart';
import 'package:blaze_drop/features/settings/presentation/pages/system_config_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _MockLoadConfig extends Mock implements LoadConfigUseCase {}

class _MockSaveConfig extends Mock implements SaveConfigUseCase {}

class _MockResetConfig extends Mock implements ResetConfigUseCase {}

void main() {
  setUpAll(() {
    registerFallbackValue(AppConfig.defaults);
  });

  group('SystemConfigPage', () {
    late _MockLoadConfig load;
    late _MockSaveConfig save;
    late _MockResetConfig reset;

    setUp(() {
      load = _MockLoadConfig();
      save = _MockSaveConfig();
      reset = _MockResetConfig();
      when(() => load.execute()).thenAnswer((_) async => AppConfig.defaults);
      when(() => save.execute(any())).thenAnswer((_) async {});
      when(() => reset.execute()).thenAnswer((_) async {});
    });

    Widget buildPage() {
      return BlocProvider(
        create: (_) => SettingsCubit(
          loadConfigUseCase: load,
          saveConfigUseCase: save,
          resetConfigUseCase: reset,
        ),
        child: MaterialApp(theme: AppTheme.dark, home: const SystemConfigPage()),
      );
    }

    testWidgets('renders the config sections and action bar', (tester) async {
      await tester.pumpWidget(buildPage());
      await tester.pump(); // run the initial load future
      await tester.pump();

      expect(find.text('SYSTEM CONFIG'), findsOneWidget);
      expect(find.text('CONNECTION PROTOCOLS'), findsOneWidget);
      expect(find.text('Auto-Accept Incoming'), findsOneWidget);
      expect(find.text('SECURITY MATRIX'), findsOneWidget);
      expect(find.text('E2E Encryption'), findsOneWidget);
      expect(find.text('SAVE CONFIG'), findsOneWidget);
      expect(find.text('RESET CONFIG'), findsOneWidget);

      // The INTERFACE section sits below the fold — scroll it into view.
      await tester.scrollUntilVisible(
        find.text('INTERFACE'),
        120,
        scrollable: find.byType(Scrollable).first,
      );
      expect(find.text('INTERFACE'), findsOneWidget);
      expect(find.text('Show HUD Logs'), findsOneWidget);
    });

    testWidgets('SAVE CONFIG persists the working copy', (tester) async {
      await tester.pumpWidget(buildPage());
      await tester.pump();
      await tester.pump();

      await tester.tap(find.text('SAVE CONFIG'));
      await tester.pump();

      verify(() => save.execute(any())).called(1);
    });

    testWidgets('RESET CONFIG restores defaults', (tester) async {
      await tester.pumpWidget(buildPage());
      await tester.pump();
      await tester.pump();

      await tester.tap(find.text('RESET CONFIG'));
      await tester.pump();

      verify(() => reset.execute()).called(1);
    });

    testWidgets('toggling a setting marks the config dirty', (tester) async {
      await tester.pumpWidget(buildPage());
      await tester.pump();
      await tester.pump();

      // "Show HUD Logs" is the last enabled switch; flip it.
      final switches = tester.widgetList<Switch>(find.byType(Switch)).toList();
      final hudSwitch = switches.last;
      await tester.tap(find.byWidget(hudSwitch));
      await tester.pump();

      // The SAVE button stays enabled and the header shows UNSAVED.
      expect(find.text('UNSAVED'), findsOneWidget);
    });
  });
}
