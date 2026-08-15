import 'package:equatable/equatable.dart';

import '../../../../core/config/app_config.dart';

/// UI state for the "SYSTEM CONFIG" screen (FUNCTIONALITY.md mock).
class SettingsState extends Equatable {
  const SettingsState({
    this.config = AppConfig.defaults,
    this.isLoading = true,
    this.isSaving = false,
    this.dirty = false,
    this.saved = false,
    this.error,
  });

  /// The working copy being edited (may differ from the persisted one).
  final AppConfig config;

  final bool isLoading;

  final bool isSaving;

  /// True once the user has changed a value but not yet saved.
  final bool dirty;

  /// True immediately after a successful save/reset (for UI feedback).
  final bool saved;

  final String? error;

  SettingsState copyWith({
    AppConfig? config,
    bool? isLoading,
    bool? isSaving,
    bool? dirty,
    bool? saved,
    Object? error = _unset,
  }) {
    return SettingsState(
      config: config ?? this.config,
      isLoading: isLoading ?? this.isLoading,
      isSaving: isSaving ?? this.isSaving,
      dirty: dirty ?? this.dirty,
      saved: saved ?? this.saved,
      error: identical(error, _unset) ? this.error : error as String?,
    );
  }

  static const _unset = Object();

  @override
  List<Object?> get props => [
    config,
    isLoading,
    isSaving,
    dirty,
    saved,
    error,
  ];
}
