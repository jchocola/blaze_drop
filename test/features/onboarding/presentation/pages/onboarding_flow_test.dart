import 'dart:async';

import 'package:blaze_drop/core/constants/constants.dart';
import 'package:blaze_drop/core/theme/theme.dart';
import 'package:blaze_drop/features/home/presentation/pages/home_page.dart';
import 'package:blaze_drop/features/onboarding/domain/entities/permission_requirement.dart';
import 'package:blaze_drop/features/onboarding/domain/use_cases/check_permissions_use_case.dart';
import 'package:blaze_drop/features/onboarding/domain/use_cases/open_app_settings_use_case.dart';
import 'package:blaze_drop/features/onboarding/domain/use_cases/request_permissions_use_case.dart';
import 'package:blaze_drop/features/onboarding/presentation/cubit/onboarding_cubit.dart';
import 'package:blaze_drop/features/onboarding/presentation/pages/onboarding_page.dart';
import 'package:blaze_drop/features/onboarding/presentation/pages/splash_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mocktail/mocktail.dart';

class _MockCheckPermissions extends Mock implements CheckPermissionsUseCase {}

class _MockRequestPermissions extends Mock
    implements RequestPermissionsUseCase {}

class _MockOpenAppSettings extends Mock implements OpenAppSettingsUseCase {}

const _pendingPermissions = <PermissionRequirement>[
  PermissionRequirement(
    id: 'location',
    category: PermissionCategory.location,
    title: 'Location Access',
    description: 'Required for discovery.',
    status: PermissionStatusType.denied,
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
];

void main() {
  late _MockCheckPermissions checkPermissions;
  late _MockRequestPermissions requestPermissions;
  late _MockOpenAppSettings openAppSettings;

  setUp(() {
    checkPermissions = _MockCheckPermissions();
    requestPermissions = _MockRequestPermissions();
    openAppSettings = _MockOpenAppSettings();
  });

  OnboardingCubit buildCubit() {
    return OnboardingCubit(
      checkPermissionsUseCase: checkPermissions,
      requestPermissionsUseCase: requestPermissions,
      openAppSettingsUseCase: openAppSettings,
      splashDelay: Duration.zero,
    );
  }

  Widget buildApp(OnboardingCubit cubit) {
    // A fresh router per test: the app's global `appRouter` is a singleton and
    // would leak navigation state between tests.
    final router = GoRouter(
      initialLocation: AppConstants.splashPath,
      routes: [
        GoRoute(
          path: AppConstants.splashPath,
          builder: (_, _) => const SplashPage(),
        ),
        GoRoute(
          path: AppConstants.onboardingPath,
          builder: (_, _) => const OnboardingPage(),
        ),
        GoRoute(
          path: AppConstants.homePath,
          builder: (_, _) => const HomePage(),
        ),
      ],
    );
    return BlocProvider<OnboardingCubit>(
      create: (_) => cubit,
      child: MaterialApp.router(theme: AppTheme.dark, routerConfig: router),
    );
  }

  /// Deterministically advances through the splash timer, the async
  /// permission check and the page transition (avoids `pumpAndSettle`, which
  /// can hang on indeterminate progress spinners).
  Future<void> pumpThroughSplash(WidgetTester tester) async {
    await tester.pump(); // build the splash page
    await tester.pump(
      const Duration(milliseconds: 60),
    ); // zero-delay init fires
    await tester.pump(const Duration(milliseconds: 60)); // async check resolves
    await tester.pump(const Duration(milliseconds: 400)); // transition frame 1
    await tester.pump(const Duration(milliseconds: 400)); // transition frame 2
  }

  testWidgets(
    'splash routes to the onboarding screen when permissions pending',
    (tester) async {
      when(
        () => checkPermissions.execute(),
      ).thenAnswer((_) async => _pendingPermissions);

      await tester.pumpWidget(buildApp(buildCubit()));
      await pumpThroughSplash(tester);

      expect(find.byType(OnboardingPage), findsOneWidget);
      expect(find.text('INITIALIZE NODE'), findsOneWidget);
    },
  );

  testWidgets('splash routes straight to Home when all permissions granted', (
    tester,
  ) async {
    when(
      () => checkPermissions.execute(),
    ).thenAnswer((_) async => _grantedPermissions);

    await tester.pumpWidget(buildApp(buildCubit()));
    await pumpThroughSplash(tester);

    expect(find.byType(OnboardingPage), findsNothing);
    expect(find.text('SELECT MODE'), findsOneWidget);
  });

  testWidgets('onboarding renders explanation cards and CTA', (tester) async {
    when(
      () => checkPermissions.execute(),
    ).thenAnswer((_) async => _pendingPermissions);

    await tester.pumpWidget(buildApp(buildCubit()));
    await pumpThroughSplash(tester);

    expect(find.text('INITIALIZE NODE'), findsOneWidget);
    expect(find.text('LOCATION ACCESS'), findsOneWidget);
    expect(find.text('DENIED'), findsOneWidget);
    expect(find.text('RETRY ACCESS'), findsOneWidget);
  });

  testWidgets('granting all permissions from onboarding lands on Home', (
    tester,
  ) async {
    when(
      () => checkPermissions.execute(),
    ).thenAnswer((_) async => _pendingPermissions);
    when(
      () => requestPermissions.execute(),
    ).thenAnswer((_) async => _grantedPermissions);

    final cubit = buildCubit();
    await tester.pumpWidget(buildApp(cubit));
    await pumpThroughSplash(tester);

    await tester.tap(find.text('RETRY ACCESS'));
    await tester.pump(); // request begins (spinner shown)
    await tester.pump(const Duration(milliseconds: 60)); // request resolves
    await tester.pump(const Duration(milliseconds: 400)); // navigate to home
    await tester.pump(const Duration(milliseconds: 400));

    expect(find.byType(OnboardingPage), findsNothing);
    expect(find.text('SELECT MODE'), findsOneWidget);
  });

  testWidgets('splash shows brand mark and status line', (tester) async {
    // Hold the permission check open so the splash stays on screen.
    final completer = Completer<List<PermissionRequirement>>();
    when(() => checkPermissions.execute()).thenAnswer((_) => completer.future);

    await tester.pumpWidget(buildApp(buildCubit()));
    await tester.pump(const Duration(milliseconds: 50));

    expect(find.text('BLAZE'), findsOneWidget);
    expect(find.text('DROP'), findsOneWidget);
    expect(find.textContaining('SYS.INIT'), findsOneWidget);

    // Release the check so no timers remain pending.
    completer.complete(_grantedPermissions);
    await tester.pump(const Duration(milliseconds: 100));
    await tester.pump(const Duration(milliseconds: 500));
  });
}
