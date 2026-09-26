import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/models.dart';
import '../providers/catalog.dart';
import '../providers/mock_provider.dart';
import '../providers/provider.dart';
import '../providers/anthropic.dart';
import '../providers/gemini.dart';
import '../providers/ollama.dart';
import '../providers/openai_compatible.dart';
import 'secure_store.dart';

/// 全局应用状态 —— 全部页面共享的数据源（ChangeNotifier）。
///
/// 持久化（PRD §9）：MVP 走 SharedPreferences（JSON 序列化）；接口保持
/// [AppStore.persistencePrefix] 抽象，桌面端换 SQLite 时只动 [load]/[save]。
/// Key 明文永不入此 store —— [SecureStore] 引用 id 而已（ADR-001）。
class AppStore extends ChangeNotifier {
  AppStore({required this.secure, this.prefs}) {
    _seedDemoData();
  }

  final SecureStore secure;
  final SharedPreferencesAsync? prefs;

  static const String persistencePrefix = 'lf.';

  // ---- 模型配置（I）----
  final List<ProviderProfile> _profiles = [];
  List<ProviderProfile> get profiles => List.unmodifiable(_profiles);
  ProviderProfile? get defaultProfile =>
      _profiles.where((p) => p.isDefault).firstOrNull ?? _profiles.firstOrNull;

  // ---- 历史记录（H）----
  final List<HistoryRecord> _history = [];
  List<HistoryRecord> get history => List.unmodifiable(_history);

  // 今日用量统计（H 统计卡）
  int todayCalls = 42;
  double monthTokens = 128.4; // K tok
  double monthCost = 6.42; // ¥
  int avgFirstTokenMs = 480;

  // ---- 术语表（K）----
  final List<TermGroup> _termGroups = [];
  List<TermGroup> get termGroups => List.unmodifiable(_termGroups);

  // ---- Skills（K，六场景对齐 Chatterfly）----
  final List<Skill> _skills = [];
  List<Skill> get skills => List.unmodifiable(_skills);

  // ---- 热键（J）----
  final List<HotkeyItem> _hotkeys = [];
  List<HotkeyItem> get hotkeys => List.unmodifiable(_hotkeys);

  // ---- 偏好（K 翻译偏好 + 语音设置抽屉）----
  String sourceLang = '中文';
  String targetLang = 'English';
  String translateStyle = '商务'; // 直译/意译/商务/口语
  bool autoDetectLang = true;
  bool bilingualWriteBack = false; // 双语写回（默认仅译文）
  bool glossaryInject = true;
  bool glossaryHitHint = true;
  bool stripFillerWords = true; // 去口头禅
  bool autoPunctuation = true;
  String previewMode = '1.2 秒后自动写入'; // 总是预览 / 直接写入
  String sttEngine = '本地 Whisper'; // 云端 STT
  bool launchAtLogin = true;
  bool privacyLock = false;
  bool offlineNotice = true;
  bool telemetry = false; // 零遥测：默认关、关闭态展示（PRD §8）

  // ---- 首次引导（L）----
  bool onboarded = false;
  String? chosenPlatform; // 引导第一步选的平台名

  // ---- 隐私锁（F）----
  bool get locked => _locked;
  bool _locked = false;

  // ---- 流程状态（A-E 演示 / 真实链路共用）----
  bool useMockProvider = true; // 无已配置模型时兜底（PRD §7 绝不白屏）

  // ============================================================
  // 模型配置操作
  // ============================================================
  void addProfile(ProviderProfile p) {
    _profiles.add(p);
    if (p.isDefault) _ensureSingleDefault(p.id);
    notifyListeners();
  }

  void removeProfile(String id) {
    _profiles.removeWhere((p) => p.id == id);
    if (defaultProfile == null && _profiles.isNotEmpty) {
      _profiles[0] = _profiles[0].copyWith(isDefault: true);
    }
    notifyListeners();
  }

  void setDefault(String id) {
    _ensureSingleDefault(id);
    notifyListeners();
  }

  void updateProfileHealth(String id, {required bool healthy, int? latencyMs}) {
    final i = _profiles.indexWhere((p) => p.id == id);
    if (i < 0) return;
    _profiles[i] = _profiles[i].copyWith(healthy: healthy, latencyMs: latencyMs);
    notifyListeners();
  }

  void _ensureSingleDefault(String id) {
    for (var i = 0; i < _profiles.length; i++) {
      _profiles[i] = _profiles[i].copyWith(isDefault: _profiles[i].id == id);
    }
  }

  /// 依 profile 建 ADR-007 Provider 实例；Key 从 SecureStore 取。
  Future<TranslationProvider> buildProvider(ProviderProfile p) async {
    if (useMockProvider && p.platform.contains('演示')) return MockProvider();
    final apiKey = p.keyRef != null ? await secure.read(p.keyRef!) ?? '' : '';
    switch (p.platform) {
      case 'Anthropic' || 'Claude':
        return AnthropicProvider(apiKey: apiKey, model: p.model, baseUrl: p.baseUrl);
      case 'Gemini':
        return GeminiProvider(apiKey: apiKey, model: p.model, baseUrl: p.baseUrl);
      case 'Ollama' || 'Ollama（本地）':
        return OllamaProvider(model: p.model, baseUrl: p.baseUrl);
      default:
        return OpenAICompatibleProvider.forPlatform(
          p.platform,
          apiKey: apiKey,
          model: p.model,
          baseUrl: p.baseUrl,
        );
    }
  }

  /// 新增 Provider 表单的默认值（原型 form-grid 预填）。
  ({String baseUrl, String model, String keyHint}) formDefaults(String platform) {
    final item = kPlatformCatalog.firstWhere((c) => c.name == platform);
    final oai = OpenAICompatibleProvider.platformDefaults[platform];
    return (
      baseUrl: oai?.baseUrl ??
          switch (item.kind) {
            PlatformKind.anthropic => 'https://api.anthropic.com/v1',
            PlatformKind.gemini => 'https://generativelanguage.googleapis.com/v1beta',
            PlatformKind.ollama => 'http://localhost:11434',
            _ => 'https://api.openai.com/v1',
          },
      model: oai?.model ??
          switch (item.kind) {
            PlatformKind.anthropic => 'claude-sonnet-4',
            PlatformKind.gemini => 'gemini-2.0-flash',
            PlatformKind.ollama => 'qwen2.5:7b',
            _ => 'gpt-4o-mini',
          },
      keyHint: item.keyHint ?? 'sk-…',
    );
  }

  // ============================================================
  // 历史记录
  // ============================================================
  void addHistory(HistoryRecord r) {
    _history.insert(0, r);
    todayCalls += 1;
    notifyListeners();
  }

  void toggleStar(String id) {
    final i = _history.indexWhere((r) => r.id == id);
    if (i < 0) return;
    _history[i] = _history[i].copyWith(starred: !_history[i].starred);
    notifyListeners();
  }

  // ============================================================
  // 术语表
  // ============================================================
  void addTerm(String group, TermEntry e) {
    final i = _termGroups.indexWhere((g) => g.name == group);
    if (i < 0) {
      _termGroups.add(TermGroup(name: group, entries: [e]));
    } else {
      final g = _termGroups[i];
      _termGroups[i] = TermGroup(name: g.name, entries: [...g.entries, e]);
    }
    notifyListeners();
  }

  List<TermEntry> termsOf(String group) {
    for (final g in _termGroups) {
      if (g.name == group) return g.entries;
    }
    return const [];
  }

  /// 术语表注入 JSON（prompt 注入格式，P0 防专名错译）。
  String? glossaryJson() {
    if (!glossaryInject) return null;
    final all = <String, String>{};
    for (final g in _termGroups) {
      for (final t in g.entries) {
        all[t.source] = t.target;
      }
    }
    if (all.isEmpty) return null;
    return all.entries.map((e) => '${e.key} => ${e.value}').join('; ');
  }

  // ============================================================
  // 隐私锁
  // ============================================================
  void lock() {
    if (!privacyLock) return;
    _locked = true;
    notifyListeners();
  }

  void unlock() {
    _locked = false;
    notifyListeners();
  }

  void setPrivacyLock(bool on) {
    privacyLock = on;
    if (!on) _locked = false;
    notifyListeners();
  }

  // ============================================================
  // 偏好 setter（统一入口便于持久化挂点）
  // ============================================================
  void set<T>(void Function() assign) {
    assign();
    notifyListeners();
  }

  void setOnboarded(String? platform) {
    onboarded = true;
    chosenPlatform = platform;
    notifyListeners();
  }

  // ============================================================
  // 持久化（MVP：SharedPreferences JSON；桌面端可平移 SQLite）
  // ============================================================
  Future<void> save() async {
    final sp = prefs;
    if (sp == null) return;
    await sp.setString('${persistencePrefix}profiles', jsonEncode(_profiles.map((p) => p.toJson()).toList()));
    await sp.setString('${persistencePrefix}terms',
        jsonEncode(_termGroups.map((g) => {'name': g.name, 'entries': g.entries.map((e) => e.toJson()).toList()}).toList()));
    await sp.setString('${persistencePrefix}history', jsonEncode(_history.map((h) => h.toJson()).toList()));
    await sp.setBool('${persistencePrefix}onboarded', onboarded);
  }

  Future<void> load() async {
    final sp = prefs;
    if (sp == null) return;
    final profilesJson = await sp.getString('${persistencePrefix}profiles');
    if (profilesJson != null) {
      _profiles
        ..clear()
        ..addAll((jsonDecode(profilesJson) as List<Object?>).map(
          (e) => ProviderProfile.fromJson(e! as Map<String, Object?>),
        ));
    }
    final termsJson = await sp.getString('${persistencePrefix}terms');
    if (termsJson != null) {
      _termGroups
        ..clear()
        ..addAll((jsonDecode(termsJson) as List<Object?>).map((g) {
          final m = g! as Map<String, Object?>;
          return TermGroup(
            name: m['name']! as String,
            entries: (m['entries']! as List<Object?>)
                .map((e) => TermEntry.fromJson(e! as Map<String, Object?>))
                .toList(),
          );
        }));
    }
    final historyJson = await sp.getString('${persistencePrefix}history');
    if (historyJson != null) {
      _history
        ..clear()
        ..addAll((jsonDecode(historyJson) as List<Object?>).map(
          (e) => HistoryRecord.fromJson(e! as Map<String, Object?>),
        ));
    }
    onboarded = await sp.getBool('${persistencePrefix}onboarded') ?? false;
    notifyListeners();
  }

  // ============================================================
  // 演示种子数据（对齐原型 mock；首启无持久化时展示完整信息架构）
  // ============================================================
  void _seedDemoData() {
    _profiles.addAll([
      const ProviderProfile(
        id: 'p-openai', platform: 'OpenAI', baseUrl: 'https://api.openai.com/v1',
        model: 'gpt-4o-mini', keyRef: 'ref-openai', latencyMs: 342, healthy: true,
      ),
      const ProviderProfile(
        id: 'p-claude', platform: 'Claude', baseUrl: 'https://api.anthropic.com/v1',
        model: 'claude-sonnet-4', keyRef: 'ref-claude', latencyMs: 512, healthy: true,
      ),
      const ProviderProfile(
        id: 'p-ollama', platform: 'Ollama（本地）', baseUrl: 'http://localhost:11434',
        model: 'qwen2.5:7b', isDefault: true, latencyMs: 0, healthy: true,
      ),
    ]);

    _history.addAll([
      const HistoryRecord(id: 'h1', time: '14:32', dir: '中→英', source: '那个报价我确认没问题，下周三之前可以签合同。', target: 'Confirmed, no problem with the quote. We can sign before next Wednesday.', meta: '86 字 · 1.1s', flow: 'A'),
      const HistoryRecord(id: 'h2', time: '14:21', dir: '中→英', source: '本周三之前能敲定报价吗？', target: 'Can we finalize the quote by this Wednesday?', meta: '38 字 · 0.9s', flow: 'B'),
      const HistoryRecord(id: 'h3', time: '13:58', dir: '英→中', source: 'forget to unsubscribe', target: '忘记取消订阅', meta: '3 词 · 0.3s', flow: 'C'),
      const HistoryRecord(id: 'h4', time: '13:41', dir: '中→英', source: '需要给页面添加一个深色模式开关', target: 'Add a dark mode toggle to the page', meta: '31 字 · 1.0s', flow: 'D'),
      const HistoryRecord(id: 'h5', time: '11:20', dir: 'OCR', source: 'The Seller shall deliver the Goods within thirty (30) business days…', target: '卖方应在收到采购订单后 30 个工作日内交付货物。', meta: '112 字 · 2.4s', flow: 'E'),
      const HistoryRecord(id: 'h6', time: '10:07', dir: '中→英', source: '发票抬头请写：译语科技有限公司', target: 'Please make the invoice out to LinguaFlow Technology Co., Ltd.', meta: '52 字 · 1.2s', flow: 'A'),
    ]);

    _termGroups.addAll([
      const TermGroup(name: '通用', entries: [
        TermEntry(source: '报价', target: 'quote', flag: 'both'),
        TermEntry(source: '合同', target: 'contract', flag: 'both'),
        TermEntry(source: 'BYOK', target: 'BYOK', flag: 'en'),
        TermEntry(source: '签字', target: 'sign', flag: 'both'),
        TermEntry(source: '工作日', target: 'business day', flag: 'both'),
        TermEntry(source: '里程碑', target: 'milestone', flag: 'both'),
        TermEntry(source: '需求方', target: 'Stakeholder', flag: 'zh'),
        TermEntry(source: '交付物', target: 'deliverable', flag: 'both'),
      ]),
      const TermGroup(name: '跨境电商', entries: [
        TermEntry(source: 'SKU', target: 'SKU', flag: 'en'),
        TermEntry(source: '选品', target: 'product sourcing', flag: 'both'),
        TermEntry(source: 'Listing', target: '商品上架页', flag: 'both'),
        TermEntry(source: '爆款', target: 'blockbuster', flag: 'both'),
        TermEntry(source: '复购', target: 'repurchase', flag: 'both'),
        TermEntry(source: '差评', target: 'negative review', flag: 'both'),
        TermEntry(source: '退货率', target: 'return rate', flag: 'both'),
        TermEntry(source: '客单价', target: 'average order value', flag: 'both'),
        TermEntry(source: 'FBA', target: 'Fulfillment by Amazon', flag: 'en'),
        TermEntry(source: '亚马逊', target: 'Amazon', flag: 'zh'),
        TermEntry(source: '广告 ACOS', target: 'Advertising Cost of Sales', flag: 'en'),
        TermEntry(source: '跟卖', target: 'hijacker listing', flag: 'both'),
      ]),
      const TermGroup(name: '法律合同', entries: [
        TermEntry(source: '甲方', target: 'Party A', flag: 'both'),
        TermEntry(source: '乙方', target: 'Party B', flag: 'both'),
        TermEntry(source: '不可抗力', target: 'force majeure', flag: 'both'),
        TermEntry(source: '违约责任', target: 'liability for breach', flag: 'both'),
        TermEntry(source: '争议解决', target: 'dispute resolution', flag: 'both'),
        TermEntry(source: '管辖法院', target: 'jurisdiction', flag: 'both'),
      ]),
      const TermGroup(name: '技术文档', entries: [
        TermEntry(source: 'API', target: 'API', flag: 'en'),
        TermEntry(source: '端点', target: 'endpoint', flag: 'both'),
        TermEntry(source: '鉴权', target: 'authentication', flag: 'both'),
        TermEntry(source: '限流', target: 'rate limiting', flag: 'both'),
        TermEntry(source: 'WebSocket', target: 'WebSocket', flag: 'en'),
        TermEntry(source: '发布', target: 'release', flag: 'both'),
        TermEntry(source: '回滚', target: 'rollback', flag: 'both'),
        TermEntry(source: '灰度', target: 'canary', flag: 'both'),
        TermEntry(source: '热更新', target: 'hot reload', flag: 'both'),
        TermEntry(source: '副作用', target: 'side effect', flag: 'both'),
        TermEntry(source: '清理函数', target: 'cleanup function', flag: 'both'),
        TermEntry(source: '事件监听', target: 'event listener', flag: 'both'),
        TermEntry(source: '内存泄漏', target: 'memory leak', flag: 'both'),
        TermEntry(source: '依赖', target: 'dependency', flag: 'both'),
        TermEntry(source: '单页应用', target: 'single-page app', flag: 'both'),
        TermEntry(source: '类型守卫', target: 'type guard', flag: 'both'),
        TermEntry(source: '中间件', target: 'middleware', flag: 'both'),
        TermEntry(source: '加密', target: 'encryption', flag: 'both'),
        TermEntry(source: '哈希', target: 'hash', flag: 'both'),
        TermEntry(source: '签名', target: 'signature', flag: 'both'),
        TermEntry(source: '公钥', target: 'public key', flag: 'both'),
        TermEntry(source: '私钥', target: 'private key', flag: 'both'),
        TermEntry(source: '会话', target: 'session', flag: 'both'),
        TermEntry(source: '令牌', target: 'token', flag: 'both'),
      ]),
    ]);

    _skills.addAll([
      const Skill(id: 's-meeting', name: '会议纪要', desc: '口头语压缩为条目式纪要，自动提炼 action items 与负责人。', icon: 'fileText', meta: '内置 · 适配流程 A'),
      const Skill(id: 's-report', name: '工作汇报', desc: '碎碎念整理成「进展 / 风险 / 下一步」三段式周报口吻。', icon: 'barChart', meta: '内置 · 适配流程 A'),
      const Skill(id: 's-project', name: '项目进度', desc: '按里程碑归组更新事项，标注阻塞点与责任人。', icon: 'calendar', meta: '内置 · 适配流程 A'),
      const Skill(id: 's-marketing', name: '营销文案', desc: '吸睛开头 + 卖点结构化，适配跨境电商 Listing 场景。', icon: 'megaphone', meta: '内置 · 适配流程 B'),
      const Skill(id: 's-mail', name: '邮件润色', desc: '正式书面语气，带称呼与落款模板，润色+翻译一次完成。', icon: 'mail', meta: '内置 · 适配流程 A/B'),
      const Skill(id: 's-coding', name: 'Vibe-Coding 提示词', desc: '把口述需求转成结构化 Prompt，含约束条件与输出格式。', icon: 'code', meta: '内置 · 适配流程 A'),
    ]);

    _hotkeys.addAll([
      const HotkeyItem(id: 'hk-a', label: '按住说话（流程 A）', mac: '按住 Fn', win: '按住 Fn'),
      const HotkeyItem(id: 'hk-b', label: '唤起悬浮窗（流程 B）', mac: '⌥ Space', win: 'Alt Space'),
      const HotkeyItem(id: 'hk-c', label: '划词翻译（流程 C）', mac: '⌥ D', win: 'Ctrl Alt D'),
      const HotkeyItem(id: 'hk-d', label: '静默替换（流程 D）', mac: '⌥ ↩', win: 'Ctrl Alt ↩'),
      const HotkeyItem(id: 'hk-e', label: '截图 OCR（流程 E）', mac: '⌥ S', win: 'Ctrl Alt S', conflictWith: 'macOS 截屏 ⌥⇧S'),
      const HotkeyItem(id: 'hk-main', label: '打开主窗口', mac: '双击 ⌥', win: '双击 Ctrl'),
      const HotkeyItem(id: 'hk-pause', label: '临时禁用全部热键', mac: '⌥ ⇧ P', win: 'Ctrl Alt P'),
      const HotkeyItem(id: 'hk-lock', label: '隐私锁', mac: '⌥ ⇧ K', win: 'Ctrl Alt K'),
    ]);
  }
}
