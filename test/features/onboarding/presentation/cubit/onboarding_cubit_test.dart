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

class _MockCompleteOnboarding extends Mock
    implements CompleteOnboardingUseCase {}

class _MockGetOnboardingCompletion extends Mock
    implements GetOnboardingCompletionUseCase {}

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
    late _MockCompleteOnboarding completeOnboarding;
    late _MockGetOnboardingCompletion getOnboardingCompletion;

    OnboardingCubit buildCubit() {
      return OnboardingCubit(
        checkPermissionsUseCase: checkPermissions,
        requestPermissionsUseCase: requestPermissions,
        openAppSettingsUseCase: openAppSettings,
        completeOnboardingUseCase: completeOnboarding,
        getOnboardingCompletionUseCase: getOnboardingCompletion,
        splashDelay: Duration.zero,
      );
    }

    setUp(() {
      checkPermissions = _MockCheckPermissions();
      requestPermissions = _MockRequestPermissions();
      openAppSettings = _MockOpenAppSettings();
      completeOnboarding = _MockCompleteOnboarding();
      getOnboardingCompletion = _MockGetOnboardingCompletion();
      when(
        () => getOnboardingCompletion.execute(),
      ).thenAnswer((_) async => false);
    });

    test('initial state has no permissions and is not initialized', () {
      final cubit = buildCubit();
      expect(cubit.state.permissions, isEmpty);
      expect(cubit.state.isInitialized, isFalse);
      expect(cubit.state.completed, isFalse);
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
      'initialize keeps completed=false with pending permissions',
      build: buildCubit,
      act: (cubit) => cubit.initialize(),
      setUp: () {
        when(
          () => checkPermissions.execute(),
        ).thenAnswer((_) async => _deniedPermissions);
      },
      expect: () => [
        const OnboardingState(
          permissions: _deniedPermissions,
          isInitialized: true,
          completed: false,
        ),
      ],
    );

    blocTest<OnboardingCubit, OnboardingState>(
      'initialize carries over completion so splash can skip to Home',
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

    test('shouldEnterHome is true when completed even if permissions pending',
        () {
      const state = OnboardingState(
        permissions: _deniedPermissions,
        isInitialized: true,
        completed: true,
      );
      expect(state.shouldEnterHome, isTrue);
      expect(state.allMandatoryGranted, isFalse);
    });

    test('shouldEnterHome is true when all permissions granted', () {
      const state = OnboardingState(
        permissions: _grantedPermissions,
        isInitialized: true,
      );
      expect(state.shouldEnterHome, isTrue);
    });

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
          completed: false,
        ),
      ],
    );

    blocTest<OnboardingCubit, OnboardingState>(
      'requestPermissions auto-completes when all mandatory are granted',
      build: buildCubit,
      act: (cubit) => cubit.requestPermissions(),
      setUp: () {
        when(
          () => requestPermissions.execute(),
        ).thenAnswer((_) async => _grantedPermissions);
        when(() => completeOnboarding.execute()).thenAnswer((_) async {});
      },
      expect: () => [
        const OnboardingState(permissions: [], isRequesting: true),
        const OnboardingState(
          permissions: _grantedPermissions,
          isInitialized: false,
          isRequesting: false,
          completed: true,
        ),
      ],
      verify: (_) {
        verify(() => completeOnboarding.execute()).called(1);
      },
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
      'refreshPermissions re-checks statuses without prompting',
      build: buildCubit,
      seed: () => const OnboardingState(
        permissions: _grantedPermissions,
        isInitialized: true,
      ),
      act: (cubit) => cubit.refreshPermissions(),
      setUp: () {
        when(
          () => checkPermissions.execute(),
        ).thenAnswer((_) async => _deniedPermissions);
      },
      expect: () => [
        const OnboardingState(
          permissions: _deniedPermissions,
          isInitialized: true,
        ),
      ],
    );

    blocTest<OnboardingCubit, OnboardingState>(
      'finishOnboarding marks onboarding complete and allows continuing',
      build: buildCubit,
      act: (cubit) => cubit.finishOnboarding(),
      setUp: () {
        when(() => completeOnboarding.execute()).thenAnswer((_) async {});
      },
      expect: () => [
        const OnboardingState(permissions: [], isRequesting: true),
        const OnboardingState(
          permissions: [],
          isRequesting: false,
          completed: true,
        ),
      ],
      verify: (_) {
        verify(() => completeOnboarding.execute()).called(1);
      },
    );

    blocTest<OnboardingCubit, OnboardingState>(
      'finishOnboarding still completes even when persistence fails',
      build: buildCubit,
      act: (cubit) => cubit.finishOnboarding(),
      setUp: () {
        when(() => completeOnboarding.execute()).thenThrow(Exception('boom'));
      },
      expect: () => [
        const OnboardingState(permissions: [], isRequesting: true),
        const OnboardingState(
          permissions: [],
          isRequesting: false,
          completed: true,
        ),
      ],
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
  });
}
