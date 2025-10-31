import 'dart:convert';
import 'package:get/get.dart';
import 'package:grow_castle_calculator/l10n/app_localizations.dart';
import 'package:http/http.dart' as http;
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher_string.dart';

class UpdateChecker {
  static const String githubOwner = "FnxAg";
  static const String githubRepo = "GrowCastleCalculator";
  static const String githubApiUrl = 
      "https://api.github.com/repos/$githubOwner/$githubRepo/releases/latest";

  static String appName = '';
  static String packageName = '';
  static String version = '';
  static String buildNumber = '';

  static Future<void> getAppInfo() async {
    PackageInfo packageInfo = await PackageInfo.fromPlatform();
    appName = packageInfo.appName;
    packageName = packageInfo.packageName;
    version = packageInfo.version;
    buildNumber = packageInfo.buildNumber;
  }

  static Future<String> getAppVersion() async {
    await getAppInfo();
    return version;
  }

  static Future<UpdateInfo?> checkForUpdate() async {
    await getAppInfo();
    try {
      final response = await http.get(Uri.parse(githubApiUrl));
      if (response.statusCode != 200) {
        return null;
      }

      final releaseData = json.decode(response.body);
      final latestVersion = releaseData["tag_name"].toString().replaceAll('v', '');
      final updateContent = releaseData["body"] ?? AppLocalizations.of(Get.context!)!.newVersionAvailable;
      final downloadUrl = releaseData["assets"][0]["browser_download_url"];

      if (_compareVersions(version, latestVersion) < 0) {
        return UpdateInfo(
          hasUpdate: true,
          latestVersion: latestVersion,
          localVersion: version,
          updateContent: updateContent,
          downloadUrl: downloadUrl,
        );
      } else {
        return UpdateInfo(hasUpdate: false);
      }
    } catch (e) {
      return null;
    }
  }

  static int _compareVersions(String version1, String version2) {
    final List<int> v1 = version1.split('.').map((e) => int.tryParse(e) ?? 0).toList();
    final List<int> v2 = version2.split('.').map((e) => int.tryParse(e) ?? 0).toList();
    final length = v1.length > v2.length ? v1.length : v2.length;

    for (int i = 0; i < length; i++) {
      final int num1 = i < v1.length ? v1[i] : 0;
      final int num2 = i < v2.length ? v2[i] : 0;
      if (num1 != num2) {
        return num1.compareTo(num2);
      }
    }
    return 0;
  }

  static void openDownloadUrl(String url) async {
    if (await canLaunchUrlString(url)) {
      await launchUrlString(url, mode: LaunchMode.externalApplication);
    }
  }
}

class UpdateInfo {
  final bool hasUpdate;
  final String? latestVersion;
  final String? localVersion;
  final String? updateContent;
  final String? downloadUrl;

  UpdateInfo({
    required this.hasUpdate,
    this.latestVersion,
    this.localVersion,
    this.updateContent,
    this.downloadUrl,
  });
}