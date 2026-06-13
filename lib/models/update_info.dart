/// Holds information about an available app update.
class UpdateInfo {
  final bool hasUpdate;
  final String? latestVersion;
  final String? localVersion;
  final String? updateContent;
  final String? downloadUrl;

  const UpdateInfo({
    required this.hasUpdate,
    this.latestVersion,
    this.localVersion,
    this.updateContent,
    this.downloadUrl,
  });
}
