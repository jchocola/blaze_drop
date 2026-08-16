import 'package:blaze_drop/core/config/app_config.dart';
import 'package:blaze_drop/core/theme/theme.dart';
import 'package:blaze_drop/features/onboarding/domain/entities/permission_requirement.dart';
import 'package:blaze_drop/features/onboarding/domain/use_cases/check_permissions_use_case.dart';
import 'package:blaze_drop/features/onboarding/domain/use_cases/complete_onboarding_use_case.dart';
import 'package:blaze_drop/features/onboarding/domain/use_cases/get_onboarding_completion_use_case.dart';
import 'package:blaze_drop/features/onboarding/domain/use_cases/open_app_settings_use_case.dart';
import 'package:blaze_drop/features/onboarding/domain/use_cases/request_permissions_use_case.dart';
import 'package:blaze_drop/features/onboarding/presentation/cubit/onboarding_cubit.dart';
import 'package:blaze_drop/features/settings/domain/entities/app_version.dart';
import 'package:blaze_drop/features/settings/domain/use_cases/get_version_info_use_case.dart';
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

class _MockGetVersionInfo extends Mock implements GetVersionInfoUseCase {}

class _MockCheckPermissions extends Mock implements CheckPermissionsUseCase {}

class _MockRequestPermissions extends Mock
    implements RequestPermissionsUseCase {}

class _MockOpenAppSettings extends Mock implements OpenAppSettingsUseCase {}

class _MockCompleteOnboarding extends Mock
    implements CompleteOnboardingUseCase {}

class _MockGetOnboardingCompletion extends Mock
    implements GetOnboardingCompletionUseCase {}

const _testVersion = AppVersion(
  version: '0.1.0',
  buildNumber: '7',
  packageName: 'com.example.blaze_drop',
);

const _mixedPermissions = <PermissionRequirement>[
  PermissionRequirement(
    id: 'location',
    category: PermissionCategory.location,
    title: 'Location Access',
    description: 'Required for discovery.',
    status: PermissionStatusType.granted,
  ),
  PermissionRequirement(
    id: 'notifications',
    category: PermissionCategory.notifications,
    title: 'Notifications',
    description: 'Alerts.',
    status: PermissionStatusType.denied,
  ),
];

const _blockedPermissions = <PermissionRequirement>[
  PermissionRequirement(
    id: 'location',
    category: PermissionCategory.location,
    title: 'Location Access',
    description: 'Required for discovery.',
    status: PermissionStatusType.permanentlyDenied,
  ),
];

const _grantedPermissions = <PermissionRequirement>[
  PermissionRequirement(
    id: 'location',
    category: PermissionCategory.location,
    title: 'Location Access',
    description: 'Required for discovery.',
    status: PermissionStatusType.granted,
  ),
  PermissionRequirement(
    id: 'notifications',
    category: PermissionCategory.notifications,
    title: 'Notifications',
    description: 'Alerts.',
    status: PermissionStatusType.granted,
  ),
];

void main() {
  setUpAll(() {
    registerFallbackValue(AppConfig.defaults);
  });

  group('SystemConfigPage', () {
    late _MockLoadConfig load;
    late _MockSaveConfig save;
    late _MockResetConfig reset;
    late _MockGetVersionInfo version;
    late _MockCheckPermissions checkPermissions;
    late _MockRequestPermissions requestPermissions;
    late _MockOpenAppSettings openAppSettings;
    late _MockCompleteOnboarding completeOnboarding;
    late _MockGetOnboardingCompletion getOnboardingCompletion;

    setUp(() {
      load = _MockLoadConfig();
      save = _MockSaveConfig();
      reset = _MockResetConfig();
      version = _MockGetVersionInfo();
      checkPermissions = _MockCheckPermissions();
      requestPermissions = _MockRequestPermissions();
      openAppSettings = _MockOpenAppSettings();
      completeOnboarding = _MockCompleteOnboarding();
      getOnboardingCompletion = _MockGetOnboardingCompletion();
      when(() => load.execute()).thenAnswer((_) async => AppConfig.defaults);
      when(() => save.execute(any())).thenAnswer((_) async {});
      when(() => reset.execute()).thenAnswer((_) async {});
      when(() => version.execute()).thenAnswer((_) async => _testVersion);
      when(() => getOnboardingCompletion.execute()).thenAnswer((_) async => false);
      when(() => checkPermissions.execute())
          .thenAnswer((_) async => _mixedPermissions);
      when(() => completeOnboarding.execute()).thenAnswer((_) async {});
    });

    OnboardingCubit buildOnboardingCubit() {
      return OnboardingCubit(
        checkPermissionsUseCase: checkPermissions,
        requestPermissionsUseCase: requestPermissions,
        openAppSettingsUseCase: openAppSettings,
        completeOnboardingUseCase: completeOnboarding,
        getOnboardingCompletionUseCase: getOnboardingCompletion,
        splashDelay: Duration.zero,
      );
    }

    Widget buildPage() {
      return MultiBlocProvider(
        providers: [
          BlocProvider(
            create: (_) => SettingsCubit(
              loadConfigUseCase: load,
              saveConfigUseCase: save,
              resetConfigUseCase: reset,
              getVersionInfoUseCase: version,
            ),
          ),
          // The SYSTEM CONFIG permissions panel reads the app-scoped
          // OnboardingCubit (same instance main.dart provides app-wide).
          BlocProvider.value(value: buildOnboardingCubit()),
        ],
        child: MaterialApp(theme: AppTheme.dark, home: const SystemConfigPage()),
      );
    }

    testWidgets('renders the config sections and action bar', (tester) async {
      await tester.pumpWidget(buildPage());
      await tester.pump(); // run the initial load future
      await tester.pump();

      expect(find.text('SYSTEM CONFIG'), findsOneWidget);
      // The ACCESS PERMISSIONS panel is the first section (top of the list).
      expect(find.text('ACCESS PERMISSIONS'), findsOneWidget);
      expect(find.text('CONNECTION PROTOCOLS'), findsOneWidget);
      expect(find.text('SAVE CONFIG'), findsOneWidget);
      expect(find.text('RESET CONFIG'), findsOneWidget);

      // CONNECTION PROTOCOLS / SECURITY MATRIX / INTERFACE sit below the fold
      // once the permissions panel is rendered — scroll to each in turn.
      await tester.scrollUntilVisible(
        find.text('Auto-Accept Incoming'),
        120,
        scrollable: find.byType(Scrollable).first,
      );
      expect(find.text('Auto-Accept Incoming'), findsOneWidget);

      await tester.scrollUntilVisible(
        find.text('SECURITY MATRIX'),
        120,
        scrollable: find.byType(Scrollable).first,
      );
      expect(find.text('SECURITY MATRIX'), findsOneWidget);
      expect(find.text('E2E Encryption'), findsOneWidget);

      await tester.scrollUntilVisible(
        find.text('INTERFACE'),
        120,
        scrollable: find.byType(Scrollable).first,
      );
      expect(find.text('INTERFACE'), findsOneWidget);
      expect(find.text('Show HUD Logs'), findsOneWidget);
    });

    testWidgets('renders the ACCESS PERMISSIONS overview with statuses', (
      tester,
    ) async {
      await tester.pumpWidget(buildPage());
      await tester.pump(); // initial load + refresh futures
      await tester.pump();

      expect(find.text('ACCESS PERMISSIONS'), findsOneWidget);
      // 1 of 2 granted in the mixed fixture.
      expect(find.text('1 / 2'), findsOneWidget);
      expect(find.text('SOME ACCESS MISSING'), findsOneWidget);
      // Per-permission status tags.
      expect(find.text('LOCATION ACCESS'), findsOneWidget);
      expect(find.text('NOTIFICATIONS'), findsOneWidget);
      expect(find.text('DENIED'), findsOneWidget);
      expect(find.text('REQUEST ACCESS'), findsOneWidget);
      expect(find.text('REFRESH STATUS'), findsOneWidget);
    });

    testWidgets('REQUEST ACCESS re-prompts for missing permissions', (
      tester,
    ) async {
      when(
        () => requestPermissions.execute(),
      ).thenAnswer((_) async => _grantedPermissions);

      await tester.pumpWidget(buildPage());
      await tester.pump();
      await tester.pump();

      await tester.tap(find.text('REQUEST ACCESS'));
      await tester.pump(); // request begins
      await tester.pump(); // request resolves

      verify(() => requestPermissions.execute()).called(1);
    });

    testWidgets('OPEN SETTINGS is offered for permanently denied access', (
      tester,
    ) async {
      when(() => checkPermissions.execute())
          .thenAnswer((_) async => _blockedPermissions);

      await tester.pumpWidget(buildPage());
      await tester.pump();
      await tester.pump();

      expect(find.text('BLOCKED'), findsOneWidget);
      expect(find.text('OPEN SETTINGS'), findsOneWidget);

      await tester.tap(find.text('OPEN SETTINGS'));
      await tester.pump();

      verify(() => openAppSettings.execute()).called(1);
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

    testWidgets('renders the legal links section', (tester) async {
      await tester.pumpWidget(buildPage());
      await tester.pump();
      await tester.pump();

      // The LEGAL & COMPLIANCE section sits below the fold — scroll to it.
      await tester.scrollUntilVisible(
        find.text('Privacy Policy'),
        120,
        scrollable: find.byType(Scrollable).first,
      );
      expect(find.text('LEGAL & COMPLIANCE'), findsOneWidget);
      expect(find.text('Privacy Policy'), findsOneWidget);
      expect(find.text('Terms of Service'), findsOneWidget);
    });

    testWidgets('tapping a legal link without URL shows pending snackbar',
        (tester) async {
      await tester.pumpWidget(buildPage());
      await tester.pump();
      await tester.pump();

      await tester.scrollUntilVisible(
        find.text('Privacy Policy'),
        120,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.tap(find.text('Privacy Policy'));
      await tester.pump();

      expect(find.text('LINK NOT CONFIGURED // URL PENDING'), findsOneWidget);
    });

    testWidgets('renders the build info section with version metadata',
        (tester) async {
      await tester.pumpWidget(buildPage());
      await tester.pump();
      await tester.pump();

      // The BUILD INFO section sits at the bottom — scroll to it.
      await tester.scrollUntilVisible(
        find.text('BUILD INFO'),
        120,
        scrollable: find.byType(Scrollable).first,
      );
      expect(find.text('BUILD INFO'), findsOneWidget);
      expect(find.text('0.1.0'), findsOneWidget);
      expect(find.text('7'), findsOneWidget);
      expect(find.text('com.example.blaze_drop'), findsOneWidget);
    });
  });
}
