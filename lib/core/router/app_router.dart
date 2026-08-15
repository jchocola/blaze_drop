import 'package:go_router/go_router.dart';

import '../../features/history/presentation/pages/history_page.dart';
import '../../features/home/presentation/pages/home_page.dart';
import '../../features/onboarding/presentation/pages/onboarding_page.dart';
import '../../features/onboarding/presentation/pages/splash_page.dart';
import '../../features/p2p/presentation/pages/p2p_discovery_page.dart';
import '../../features/p2p/presentation/pages/p2p_transfer_page.dart';
import '../../features/server/presentation/pages/server_page.dart';
import '../../features/settings/presentation/pages/system_config_page.dart';
import '../constants/constants.dart';
import 'app_shell.dart';

/// Central `go_router` configuration (RULE.md §4).
///
/// Module A owns the onboarding chain: `/splash` → `/onboarding` (if
/// permissions pending) → `/home`. Module B owns the P2P chain:
/// `/p2p` (discovery grid) → `/p2p/transfer` (target + payload). Module C
/// owns the Server chain `/server`.
///
/// HOME and SETTINGS are shell branches inside a
/// [`StatefulShellRoute.indexedStack`]: tapping a tab switches branches in
/// place instead of pushing a new screen onto the stack.
final GoRouter appRouter = GoRouter(
  initialLocation: AppConstants.splashPath,
  routes: <RouteBase>[
    GoRoute(
      path: AppConstants.splashPath,
      builder: (context, state) => const SplashPage(),
    ),
    GoRoute(
      path: AppConstants.onboardingPath,
      builder: (context, state) => const OnboardingPage(),
    ),
    GoRoute(
      path: AppConstants.p2pPath,
      builder: (context, state) => const P2pDiscoveryPage(),
    ),
    GoRoute(
      path: AppConstants.p2pTransferPath,
      builder: (context, state) => const P2pTransferPage(),
    ),
    GoRoute(
      path: AppConstants.serverPath,
      builder: (context, state) => const ServerPage(),
    ),
    StatefulShellRoute.indexedStack(
      builder: (context, state, navigationShell) =>
          AppShell(navigationShell: navigationShell),
      branches: [
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: AppConstants.homePath,
              builder: (context, state) => const HomePage(),
            ),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: AppConstants.historyPath,
              builder: (context, state) => const HistoryPage(),
            ),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: AppConstants.settingsPath,
              builder: (context, state) => const SystemConfigPage(),
            ),
          ],
        ),
      ],
    ),
  ],
);
