// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Chinese (`zh`).
class AppLocalizationsZh extends AppLocalizations {
  AppLocalizationsZh([String locale = 'zh']) : super(locale);

  @override
  String get appName => '成长城堡计算器';

  @override
  String get calculator => '计算器';

  @override
  String get tool => '工具';

  @override
  String get settings => '设置';

  @override
  String get castleDefault => '城堡（默认）';

  @override
  String get taDefault => '城弓（默认）';

  @override
  String get clearInputFields => '清空所有输入';

  @override
  String get loadData => '载入数据';

  @override
  String get currentWave => '当前波数';

  @override
  String get typeCurrentWave => '输入当前波数';

  @override
  String get seasonalWave => '赛季波数';

  @override
  String get typeSeasonalWave => '输入赛季波数';

  @override
  String get currentSeasonalWave => '当前赛季波数';

  @override
  String get typeCurrentSeasonalWave => '输入当前赛季波数';

  @override
  String get totalWave => '总波数：';

  @override
  String get totalGold => '总经济：';

  @override
  String get gp => 'GP：';

  @override
  String get ratio => '指数：';

  @override
  String get seasonProgress => '赛季进度：';

  @override
  String get progress => '进度';

  @override
  String get updateTime => '更新时间：';

  @override
  String get timeTillReset => '重置倒计时：';

  @override
  String get wph => '波速：';

  @override
  String unitName(int index) {
    return '单位 $index 名称';
  }

  @override
  String get typeUnitName => '输入单位名称';

  @override
  String get unitLevel => '单位等级';

  @override
  String get typeUnitLevel => '输入单位等级';

  @override
  String get remove => '移除';

  @override
  String get add => '新增';

  @override
  String get save => '保存';

  @override
  String get todo =>
      '工具页面\n施工中\n未来可能的新功能：\n- 收入计算器\n- 赛季/无尽/赛季殖民地重置倒计时\n- 升级计算器\n- 通天回本计算器\n- 伤害对比\n- 收益计算';

  @override
  String get language => '语言';

  @override
  String get themeMode => '主题模式';

  @override
  String get systemDefault => '跟随系统';

  @override
  String get lightMode => '浅色';

  @override
  String get darkMode => '深色';

  @override
  String get clearSavedData => '清除数据';

  @override
  String get clearDataWarning => '您确定要清除已保存的数据吗？此操作无法撤销。';

  @override
  String get cancel => '取消';

  @override
  String get confirm => '确认';

  @override
  String get clearDataFinished => '数据已清除';

  @override
  String get about => '关于';

  @override
  String get version => '版本';

  @override
  String get developer => 'by FnxAg aka Ariyara';

  @override
  String appVersion(String versionNumber) {
    return '版本 $versionNumber';
  }

  @override
  String get github => 'GitHub';

  @override
  String get repositoryUrl => 'https://github.com/FnxAg/GrowCastleCalculator';

  @override
  String get bilibili => 'Bilibili';

  @override
  String get developerBilibiliUrl => 'https://space.bilibili.com/505144597';

  @override
  String cannotLaunchURL(String url) {
    return '无法打开链接：$url';
  }

  @override
  String get zh_CN_withCode => 'zh_CN\t简体中文';

  @override
  String get en_withCode => 'en\tEnglish';
}
