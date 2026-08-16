import 'package:blaze_drop/features/onboarding/domain/entities/permission_requirement.dart';
import 'package:blaze_drop/features/onboarding/domain/use_cases/check_permissions_use_case.dart';
import 'package:blaze_drop/features/onboarding/domain/use_cases/complete_onboarding_use_case.dart';
import 'package:blaze_drop/features/onboarding/domain/use_cases/get_onboarding_completion_use_case.dart';
import 'package:blaze_drop/features/onboarding/domain/use_cases/open_app_settings_use_case.dart';
import 'package:blaze_drop/features/onboarding/domain/use_cases/request_permissions_use_case.dart';
import 'package:blaze_drop/features/onboarding/presentation/cubit/onboarding_cubit.dart';
import 'package:blaze_drop/features/onboarding/presentation/cubit/onboarding_state.dart';
import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _MockCheckPermissions extends Mock implements CheckPermissionsUseCase {}

class _MockRequestPermissions extends Mock
    implements RequestPermissionsUseCase {}

class _MockOpenAppSettings extends Mock implements OpenAppSettingsUseCase {}

class _MockGetOnboardingCompletion extends Mock
    implements GetOnboardingCompletionUseCase {}

class _MockCompleteOnboarding extends Mock implements CompleteOnboardingUseCase {}

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

const _deniedPermissions = <PermissionRequirement>[
  PermissionRequirement(
    id: 'location',
    category: PermissionCategory.location,
    title: 'Location Access',
    description: 'Required for discovery.',
    status: PermissionStatusType.denied,
  ),
];

void main() {
  group('OnboardingCubit', () {
    late _MockCheckPermissions checkPermissions;
    late _MockRequestPermissions requestPermissions;
    late _MockOpenAppSettings openAppSettings;
    late _MockGetOnboardingCompletion getOnboardingCompletion;
    late _MockCompleteOnboarding completeOnboarding;

    OnboardingCubit buildCubit() {
      return OnboardingCubit(
        checkPermissionsUseCase: checkPermissions,
        requestPermissionsUseCase: requestPermissions,
        openAppSettingsUseCase: openAppSettings,
        getOnboardingCompletionUseCase: getOnboardingCompletion,
        completeOnboardingUseCase: completeOnboarding,
        splashDelay: Duration.zero,
      );
    }

    setUp(() {
      checkPermissions = _MockCheckPermissions();
      requestPermissions = _MockRequestPermissions();
      openAppSettings = _MockOpenAppSettings();
      getOnboardingCompletion = _MockGetOnboardingCompletion();
      completeOnboarding = _MockCompleteOnboarding();
      when(
        () => getOnboardingCompletion.execute(),
      ).thenAnswer((_) async => false);
      when(() => completeOnboarding.execute()).thenAnswer((_) async {});
    });

    test('initial state has no permissions and is not initialized', () {
      final cubit = buildCubit();
      expect(cubit.state.permissions, isEmpty);
      expect(cubit.state.isInitialized, isFalse);
    });

    blocTest<OnboardingCubit, OnboardingState>(
      'initialize emits initialized state with granted permissions',
      build: buildCubit,
      act: (cubit) => cubit.initialize(),
      setUp: () {
        when(
          () => checkPermissions.execute(),
        ).thenAnswer((_) async => _grantedPermissions);
      },
      expect: () => [
        const OnboardingState(
          permissions: _grantedPermissions,
          isInitialized: true,
        ),
      ],
    );

    blocTest<OnboardingCubit, OnboardingState>(
      'initialize keeps completed=true when onboarding was skipped before',
      build: buildCubit,
      act: (cubit) => cubit.initialize(),
      setUp: () {
        when(
          () => getOnboardingCompletion.execute(),
        ).thenAnswer((_) async => true);
        when(
          () => checkPermissions.execute(),
        ).thenAnswer((_) async => _deniedPermissions);
      },
      expect: () => [
        const OnboardingState(
          permissions: _deniedPermissions,
          isInitialized: true,
          completed: true,
        ),
      ],
    );

    blocTest<OnboardingCubit, OnboardingState>(
      'requestPermissions emits requesting then resolved state',
      build: buildCubit,
      act: (cubit) => cubit.requestPermissions(),
      setUp: () {
        when(
          () => requestPermissions.execute(),
        ).thenAnswer((_) async => _deniedPermissions);
      },
      expect: () => [
        const OnboardingState(permissions: [], isRequesting: true),
        const OnboardingState(
          permissions: _deniedPermissions,
          isInitialized: false,
          isRequesting: false,
        ),
      ],
    );

    blocTest<OnboardingCubit, OnboardingState>(
      'requestPermissions emits an error state on failure',
      build: buildCubit,
      act: (cubit) => cubit.requestPermissions(),
      setUp: () {
        when(() => requestPermissions.execute()).thenThrow(Exception('boom'));
      },
      expect: () => [
        const OnboardingState(permissions: [], isRequesting: true),
        const OnboardingState(
          permissions: [],
          isRequesting: false,
          error: 'Failed to request permissions',
        ),
      ],
    );

    blocTest<OnboardingCubit, OnboardingState>(
      'requestPermissions marks onboarding complete when all granted',
      build: buildCubit,
      act: (cubit) => cubit.requestPermissions(),
      setUp: () {
        when(
          () => requestPermissions.execute(),
        ).thenAnswer((_) async => _grantedPermissions);
      },
      expect: () => [
        const OnboardingState(permissions: [], isRequesting: true),
        const OnboardingState(
          permissions: _grantedPermissions,
          isRequesting: false,
          completed: true,
        ),
      ],
      verify: (cubit) {
        verify(() => completeOnboarding.execute()).called(1);
      },
    );

    blocTest<OnboardingCubit, OnboardingState>(
      'finishOnboarding persists completion and lets the user in',
      build: buildCubit,
      act: (cubit) => cubit.finishOnboarding(),
      expect: () => [
        const OnboardingState(completed: true),
      ],
      verify: (cubit) {
        verify(() => completeOnboarding.execute()).called(1);
      },
    );

    test(
      'allMandatoryGranted is true only when every permission is granted',
      () {
        final state = const OnboardingState(
          permissions: _grantedPermissions,
          isInitialized: true,
        );
        expect(state.allMandatoryGranted, isTrue);
        expect(state.hasPendingPermission, isFalse);
      },
    );

    test(
      'hasPermanentDenial is true when a permission is permanently denied',
      () {
        const state = OnboardingState(
          permissions: [
            PermissionRequirement(
              id: 'location',
              category: PermissionCategory.location,
              title: 'Location Access',
              description: 'Required.',
              status: PermissionStatusType.permanentlyDenied,
            ),
          ],
          isInitialized: true,
        );
        expect(state.allMandatoryGranted, isFalse);
        expect(state.hasPermanentDenial, isTrue);
      },
    );

    test('shouldEnterHome is true when onboarding was skipped', () {
      const state = OnboardingState(
        permissions: _deniedPermissions,
        isInitialized: true,
        completed: true,
      );
      expect(state.allMandatoryGranted, isFalse);
      expect(state.shouldEnterHome, isTrue);
    });
  });
}
