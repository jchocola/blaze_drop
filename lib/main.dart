import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'core/constants/constants.dart';
import 'core/di/injection.dart';
import 'core/router/app_router.dart';
import 'core/theme/theme.dart';
import 'features/history/presentation/cubit/history_cubit.dart';
import 'features/onboarding/presentation/cubit/onboarding_cubit.dart';
import 'features/p2p/presentation/cubit/p2p_cubit.dart';
import 'features/server/presentation/cubit/server_cubit.dart';
import 'features/settings/presentation/cubit/settings_cubit.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await setupLocator();
  runApp(const BlazeDropApp());
}

/// Root widget.
///
/// Cubits are provided above the navigator so that every route can reach them
/// (RULE.md §2.4 / §3.3):
/// - [OnboardingCubit] drives the Module A onboarding chain.
/// - [P2pCubit] drives the Module B P2P flow (discovery → transfer).
/// - [SettingsCubit] drives the SYSTEM CONFIG (settings) screen.
/// - [ServerCubit] drives the Module C host-web server screen.
/// - [HistoryCubit] drives the TRANSFER HISTORY tab.
class BlazeDropApp extends StatelessWidget {
  const BlazeDropApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider<OnboardingCubit>(
          create: (_) => sl<OnboardingCubit>(),
        ),
        BlocProvider<P2pCubit>(
          create: (_) => sl<P2pCubit>(),
        ),
        BlocProvider<SettingsCubit>(
          create: (_) => sl<SettingsCubit>(),
        ),
        BlocProvider<ServerCubit>(
          create: (_) => sl<ServerCubit>(),
        ),
        BlocProvider<HistoryCubit>(
          create: (_) => sl<HistoryCubit>(),
        ),
      ],
      child: MaterialApp.router(
        title: AppConstants.appName,
        debugShowCheckedModeBanner: false,
        theme: AppTheme.dark,
        routerConfig: appRouter,
      ),
    );
  }
}
