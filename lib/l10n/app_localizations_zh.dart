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
  String get clearInputFields => '清空输入';

  @override
  String get currentWave => '当前波数';

  @override
  String get enterCurrentWave => '输入当前波数';

  @override
  String get seasonalWave => '赛季波数';

  @override
  String get enterSeasonalWave => '输入赛季波数';

  @override
  String get currentSeasonalWave => '当前赛季波数';

  @override
  String get enterCurrentSeasonalWave => '输入当前赛季波数';

  @override
  String get totalWave => '总波数';

  @override
  String get totalGold => '总经济';

  @override
  String get gp => 'GP';

  @override
  String get ratio => '指数';

  @override
  String get seasonProgress => '赛季进度：';

  @override
  String get hellModeSeasonProgress => '无尽赛季进度：';

  @override
  String get seasonalColonyProgress => '赛季殖民地进度：';

  @override
  String get progress => '进度';

  @override
  String get updateTime => '截止时间：';

  @override
  String get timeTillReset => '重置倒计时：';

  @override
  String get wph => '波速';

  @override
  String unitName(int index) {
    return '单位 $index';
  }

  @override
  String get enterUnitName => '输入单位名称';

  @override
  String get unitLevel => '等级';

  @override
  String get enterUnitLevel => '输入单位等级';

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
  String get exportData => '导出数据';

  @override
  String get importData => '导入数据';

  @override
  String get exportSuccess => '数据导出成功';

  @override
  String get exportFailed => '数据导出失败';

  @override
  String get importSuccess => '数据导入成功';

  @override
  String get importFailed => '数据导入失败';

  @override
  String get invalidDataFormat => '无效的文件格式';

  @override
  String get importWarning => '导入将覆盖当前数据，确定继续吗？';

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
  String get checkForUpdates => '检查更新';

  @override
  String get checkForUpdateFailed => '检查更新失败';

  @override
  String get isLatestVersion => '当前已是最新版本';

  @override
  String get findNewVersion => '发现新版本！';

  @override
  String get currentVersion => '当前版本：';

  @override
  String get latestVersion => '最新版本：';

  @override
  String get updateContent => '更新内容：';

  @override
  String get fixedKnownIssues => '优化体验，修复已知问题';

  @override
  String get updateLater => '稍后更新';

  @override
  String get updateNow => '立即更新';

  @override
  String get newVersionAvailable => '有新版本可用';

  @override
  String get about => '关于';

  @override
  String get version => '版本';

  @override
  String get developer => 'by FnxAg aka Ariyara\n🐾欢迎加入POC谢谢喵🐾';

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

  @override
  String get goldCalculator => '收入计算器';

  @override
  String get waveSpeedQuery => '波速估算';

  @override
  String get inherit => '继承';

  @override
  String get gabCost => '金挂成本';

  @override
  String get goldDay => '每日收入';

  @override
  String get gameSpeed => '游戏速度';

  @override
  String get enterGameSpeed => '输入游戏速度';

  @override
  String get jumpAndWave => '单次跳波数';

  @override
  String get enterWave => '输入波数';

  @override
  String get waveTime => '单波时间 (s)';

  @override
  String get enterWaveTime => '输入单波时间 (s)';

  @override
  String get infiniteColony => '通天塔';

  @override
  String get icLevel => '通天塔等级(LV)';

  @override
  String get enterLV => '输入等级';

  @override
  String get ironWheel => '车轮';

  @override
  String get extraColonyCD => '额外殖民地C';

  @override
  String get extraColonyGold => '额外殖民地G';

  @override
  String get secCart => '每车时间';

  @override
  String get goldCart => '每车金币';

  @override
  String get cartHour => '每小时小推车数量';

  @override
  String get icRatio => '通天塔比例';

  @override
  String get goldHour => '小时收入';

  @override
  String get goldAutoBattle => '金挂 (GAB)';

  @override
  String get gabHourDay => '每日金挂时长 (h)';

  @override
  String get enterHour => '输入时长';

  @override
  String get gabProfit => '金挂收益 (%)';

  @override
  String get enterProfit => '输入收益百分比';

  @override
  String get goldWave => '每波收益';

  @override
  String get timeAutoBattle => '时挂 (TAB)';

  @override
  String get tabHourDay => '每日时挂时长 (h)';

  @override
  String get goldenTree => '金币大树';

  @override
  String get seasonalColony => '赛季殖民地';

  @override
  String get historyArchives => '历史存档';

  @override
  String get archiveName => '存档名称';

  @override
  String get load => '加载';

  @override
  String get rename => '重命名';

  @override
  String get delete => '删除';

  @override
  String get noArchives => '暂无存档';

  @override
  String get renameArchive => '重命名存档';

  @override
  String get saveArchive => '保存存档';

  @override
  String get enterArchiveName => '输入存档名称';

  @override
  String get deleteArchiveConfirm => '确定要删除此存档吗？此操作无法撤销。';

  @override
  String get loadArchiveConfirm => '加载此存档将覆盖当前数据，确定继续吗？';

  @override
  String get currentWaveValue => '当前波数';

  @override
  String get onlineQuery => '在线查询';

  @override
  String get freeInput => '自由输入';

  @override
  String get gameName => '游戏名称';

  @override
  String get getInfo => '获取信息';

  @override
  String get nameNotFound => '用户名不存在';

  @override
  String get tooManyRequests => '请求过于频繁，请稍后再试';

  @override
  String get queryTime => '查询时间';

  @override
  String get queryResult => '查询结果';

  @override
  String get notQueried => '未查询';

  @override
  String get updateArchive => '更新当前存档';

  @override
  String get archiveCreated => '创建日期：';

  @override
  String get archiveUpdated => '最后更新：';

  @override
  String get modeLabel => '模式：';

  @override
  String get playerInfoQuery => '查询玩家信息';

  @override
  String get playerRanking => '玩家排名';

  @override
  String get guildInfoQuery => '公会排名';

  @override
  String get currentSeason => '当前赛季';

  @override
  String get rank => '排名';

  @override
  String get guildName => '公会名称';

  @override
  String get seasonalScore => '赛季波';

  @override
  String get seasonalWph => 'WPH';

  @override
  String get guildSubscription => '订阅公会信息';

  @override
  String get subscribe => '订阅';

  @override
  String get hellRanking => '无尽排名';

  @override
  String get damage => '伤害';
}
