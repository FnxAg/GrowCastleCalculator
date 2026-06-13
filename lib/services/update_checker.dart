import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher_string.dart';
import 'package:grow_castle_calculator/models/update_info.dart';

/// Checks for app updates via the GitHub Releases API.
class UpdateChecker {
  static const String _githubOwner = 'FnxAg';
  static const String _githubRepo = 'GrowCastleCalculator';
  static const String _githubApiUrl =
      'https://api.github.com/repos/$_githubOwner/$_githubRepo/releases/latest';

  static String _version = '';

  /// Returns the current app version string.
  static Future<String> getAppVersion() async {
    if (_version.isEmpty) {
      final info = await PackageInfo.fromPlatform();
      _version = info.version;
    }
    return _version;
  }

  /// Checks GitHub for a newer release. Returns null on failure.
  static Future<UpdateInfo?> checkForUpdate() async {
    final localVersion = await getAppVersion();
    try {
      final response = await http.get(Uri.parse(_githubApiUrl));
      if (response.statusCode != 200) return null;

      final releaseData = json.decode(response.body);
      final latestVersion =
          releaseData['tag_name'].toString().replaceAll('v', '');
      final updateContent = releaseData['body'] as String?;
      final downloadUrl =
          releaseData['assets']?[0]?['browser_download_url'] as String?;

      if (_compareVersions(localVersion, latestVersion) < 0) {
        return UpdateInfo(
          hasUpdate: true,
          latestVersion: latestVersion,
          localVersion: localVersion,
          updateContent: updateContent,
          downloadUrl: downloadUrl,
        );
      } else {
        return const UpdateInfo(hasUpdate: false);
      }
    } catch (_) {
      return null;
    }
  }

  /// Opens [url] in an external application (e.g., browser).
  static Future<void> openDownloadUrl(String url) async {
    if (await canLaunchUrlString(url)) {
      await launchUrlString(url, mode: LaunchMode.externalApplication);
    }
  }

  /// Returns negative if v1 < v2, positive if v1 > v2, 0 if equal.
  static int _compareVersions(String v1, String v2) {
    final p1 = v1.split('.').map((e) => int.tryParse(e) ?? 0).toList();
    final p2 = v2.split('.').map((e) => int.tryParse(e) ?? 0).toList();
    final length = p1.length > p2.length ? p1.length : p2.length;

    for (int i = 0; i < length; i++) {
      final a = i < p1.length ? p1[i] : 0;
      final b = i < p2.length ? p2[i] : 0;
      if (a != b) return a.compareTo(b);
    }
    return 0;
  }
}
