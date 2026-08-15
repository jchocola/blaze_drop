import '../entities/app_version.dart';
import '../repositories/version_repository.dart';

/// Resolves the current app version/build metadata for display.
class GetVersionInfoUseCase {
  const GetVersionInfoUseCase(this._repository);

  final VersionRepository _repository;

  Future<AppVersion> execute() => _repository.getVersionInfo();
}
