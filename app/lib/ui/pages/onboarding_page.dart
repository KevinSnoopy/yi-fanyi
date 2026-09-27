import 'dart:async';

import 'package:flutter/material.dart' hide Badge;

import '../../core/icons/lf_icons.dart';
import '../../core/theme/tokens.dart';
import '../../models/models.dart';
import '../../providers/catalog.dart';
import '../../providers/provider.dart';
import '../../services/app_store.dart';
import '../../services/service_scope.dart';
import '../components/cards.dart';
import '../components/common.dart';
import '../overlays/floating_windows.dart';
import '../overlays/recorder_pill.dart' show LfSpinner;
import 'flow_demos.dart';
import 'flow_page.dart' show HostTitleBar;

/// F 页 · 隐私锁（桌面）—— PRD §6 #8（原型 Tab F 四态序列）。
/// 已解锁 banner → 离开设备倒计时 → 整屏锁定 → FaceID 解锁成功。
class PrivacyDemoPage extends FlowDemoPage {
  const PrivacyDemoPage({super.key, required super.store});

  @override
  int get stateCount => 4;

  @override
  String get hostTitle => '译语 · 主窗口';

  @override
  State<FlowDemoPage> createState() => _PrivacyDemoPageState();
}

class _PrivacyDemoPageState extends State<PrivacyDemoPage> with FlowDemoStateMixin {
  @override
  List<String> get stateLabels => const ['已解锁', '离开设备', '自动锁定', 'FaceID 解锁'];

  @override
  void initState() {
    super.initState();
    replay();
  }

  @override
  void replay() {
    setStateAt(0);
    schedule(() => setStateAt(1), const Duration(milliseconds: 1500));
    schedule(() => setStateAt(2), const Duration(milliseconds: 3300));
    schedule(() => setStateAt(3), const Duration(milliseconds: 6000));
  }

  @override
  Widget build(BuildContext context) {
    final s = LfScheme.of(context);
    return Stack(
      children: [
        Column(
          children: [
            HostTitleBar(title: widget.hostTitle),
            Expanded(
              child: Container(
                color: s.bgWindow,
                padding: const EdgeInsets.all(24),
                child: const Center(child: _ShieldIntro()),
              ),
            ),
          ],
        ),
        // 态 2 · 整屏锁定层
        if (stateIdx == 2)
          const Positioned.fill(child: LockScreen()),
        // 态 0/1/3 · 顶部 banner
        if (stateIdx != 2)
          Positioned(
            top: 46,
            left: 0,
            right: 0,
            child: Center(
              child: switch (stateIdx) {
                1 => const _PrivacyBanner(
                    warn: true,
                    iconName: 'clock',
                    title: '检测到离开设备',
                    sub: 'Mac 合盖 / 屏幕保护程序已触发 · 倒计时 60s',
                    trailing: _Countdown(text: '60s'),
                  ),
                3 => _PrivacyBanner(
                    success: true,
                    iconName: 'check',
                    title: 'FaceID 验证通过',
                    sub: '解锁耗时 320ms · 未发送任何遥测',
                    trailing: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
                      decoration: BoxDecoration(
                        color: s.success.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(LfDimens.rPill),
                      ),
                      child: Text('已解锁', style: TextStyle(fontSize: LfDimens.fs2xs, fontWeight: FontWeight.w700, color: s.success)),
                    ),
                  ),
                _ => _PrivacyBanner(
                    iconName: 'shieldCheck',
                    title: '隐私锁 · 已解锁',
                    sub: 'FaceID 已通过 · 本地无密钥缓存',
                    trailing: LfButton(label: '立即锁定', padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5), onPressed: () => setStateAt(2)),
                  ),
              },
            ),
          ),
        Positioned(top: 44, right: 16, child: demoControls()),
      ],
    );
  }
}

/// 宿主区介绍卡（原型 hostThread 内容）。
class _ShieldIntro extends StatelessWidget {
  const _ShieldIntro();

  @override
  Widget build(BuildContext context) {
    final s = LfScheme.of(context);
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 56,
          height: 56,
          decoration: BoxDecoration(gradient: s.brandGrad, borderRadius: BorderRadius.circular(16)),
          child: Center(child: LfIcons.icon('shieldCheck', size: 26, color: Colors.white)),
        ),
        const SizedBox(height: 12),
        Text('隐私锁已激活', style: TextStyle(fontSize: LfDimens.fsMd, fontWeight: FontWeight.w600, color: s.text)),
        const SizedBox(height: 8),
        Text('所有调用本地化 · 离开超过 1 分钟锁定', style: TextStyle(fontSize: LfDimens.fsSm, color: s.text2)),
        const SizedBox(height: 16),
        const Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          Badge('FaceID', live: true),
          SizedBox(width: 8),
          Badge('密码'),
          SizedBox(width: 8),
          Badge('TouchID'),
        ]),
      ],
    );
  }
}

/// privacy-banner —— 原型 .privacy-banner（bar-enter 弹入）。
class _PrivacyBanner extends StatelessWidget {
  const _PrivacyBanner({
    required this.iconName,
    required this.title,
    required this.sub,
    this.trailing,
    this.warn = false,
    this.success = false,
  });

  final String iconName;
  final String title;
  final String sub;
  final Widget? trailing;
  final bool warn;
  final bool success;

  @override
  Widget build(BuildContext context) {
    final s = LfScheme.of(context);
    final Color iconBg = warn ? s.warning : (success ? s.success : s.brand);
    return RiseIn(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: s.bgBar,
          borderRadius: BorderRadius.circular(LfDimens.rPopover),
          border: Border.all(color: s.divider),
          boxShadow: s.shadowMd,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 28,
              height: 28,
              decoration: BoxDecoration(color: iconBg.withValues(alpha: 0.14), borderRadius: BorderRadius.circular(8)),
              child: Center(child: LfIcons.icon(iconName, size: 14, color: iconBg)),
            ),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: TextStyle(fontSize: LfDimens.fsSm, fontWeight: FontWeight.w600, color: s.text)),
                const SizedBox(height: 1),
                Text(sub, style: TextStyle(fontSize: LfDimens.fs2xs, color: s.text2)),
              ],
            ),
            if (trailing != null) ...[
              const SizedBox(width: 12),
              trailing!,
            ],
          ],
        ),
      ),
    );
  }
}

class _Countdown extends StatelessWidget {
  const _Countdown({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    final s = LfScheme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: s.warning.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(LfDimens.rBtn),
      ),
      child: Text(text, style: TextStyle(fontSize: LfDimens.fsSm, fontWeight: FontWeight.w700, color: s.warning)),
    );
  }
}

// ==================================================================
// L 页 · 首次引导 —— PRD §6 #10（原型 Tab L 五态向导）
//
// T-025 · 三步向导接真实状态：
// - 填 Key：真实 testConnection → addProfileWithKey（Key 进 SecureStore）
// - 本地试用：Ollama 平台零 Key 可完整走完向导（本地模型无需授权）
// - 权限引导：真实 permissionStatus 自检（辅助功能 / 输入监控）→
//   openPermissionSettings 拉起系统设置 → 回到应用（lifecycle resumed）
//   自动重新自检刷新 UI；Web 预览无原生桥时如实标注并允许跳过
// ==================================================================
class OnboardingPage extends FlowDemoPage {
  const OnboardingPage({super.key, required super.store});

  @override
  int get stateCount => 5;

  @override
  String get hostTitle => '译语 · 首次启动';

  @override
  State<FlowDemoPage> createState() => _OnboardingPageState();
}

class _OnboardingPageState extends State<OnboardingPage>
    with FlowDemoStateMixin, WidgetsBindingObserver {
  int selectedPlat = 5; // 默认 Ollama 本地（零 Key 体验）

  final _keyCtl = TextEditingController();
  final _baseUrlCtl = TextEditingController();
  final _modelCtl = TextEditingController();

  // 填 Key 步真实态
  bool _testing = false;
  bool _checkingLocal = false;
  ConnectionTestResult? _testResult;
  ProviderProfile? _savedProfile;

  // 权限步真实态（macOS：accessibility / inputMonitoring；Web 预览为空 map）
  Map<String, bool> _perms = const {};
  bool _permChecking = false;

  @override
  List<String> get stateLabels => const ['选平台', '填 Key', '设热键', '权限引导', '完成'];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _applyPlatform(selectedPlat);
    setStateAt(0);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _keyCtl.dispose();
    _baseUrlCtl.dispose();
    _modelCtl.dispose();
    super.dispose();
  }

  /// 回到应用即重新自检（macOS 授权完切回来，UI 自动刷新，无需重启）。
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      unawaited(_refreshPerms());
    }
  }

  /// FlowDemoStateMixin 钩子：进入「权限引导」态时真实自检一次。
  @override
  void onStateChanged(int i) {
    if (i == 3) {
      unawaited(_refreshPerms());
    }
  }

  @override
  void replay() => setStateAt(0);

  // ---------------- 真实状态方法 ----------------

  PlatformCatalogItem get _plat => kOnboardingCatalog[selectedPlat];
  bool get _isOllama => _plat.kind == PlatformKind.ollama;

  /// 引导平台卡默认值（kOnboardingCatalog 名称与 I 页目录部分不一致，独立给默认）。
  void _applyPlatform(int i) {
    selectedPlat = i;
    final name = kOnboardingCatalog[i].name;
    final (
      String baseUrl,
      String model,
    ) = switch (name) {
      'OpenAI' => ('https://api.openai.com/v1', 'gpt-4o-mini'),
      'Anthropic' => ('https://api.anthropic.com/v1', 'claude-sonnet-4'),
      'Gemini' => ('https://generativelanguage.googleapis.com/v1beta', 'gemini-2.0-flash'),
      'DeepSeek' => ('https://api.deepseek.com/v1', 'deepseek-chat'),
      '通义' => ('https://dashscope.aliyuncs.com/compatible-mode/v1', 'qwen-plus'),
      _ => ('http://localhost:11434', 'qwen2.5:7b'), // Ollama 本地
    };
    _baseUrlCtl.text = baseUrl;
    _modelCtl.text = model;
    _keyCtl.text = '';
    _testResult = null;
    _savedProfile = null;
  }

  /// 「测试连接并保存」：成功才把 Key 写入 SecureStore 并落 Profile（ADR-001）。
  Future<void> _testAndSave() async {
    if (_testing) return;
    setState(() {
      _testing = true;
      _testResult = null;
    });
    final r = await widget.store.testConnection(
      platform: _plat.name,
      baseUrl: _baseUrlCtl.text.trim(),
      model: _modelCtl.text.trim(),
      apiKey: _keyCtl.text.trim(),
    );
    if (!mounted) return;
    ProviderProfile? saved;
    if (r.success) {
      saved = await widget.store.addProfileWithKey(
        platform: _plat.name,
        baseUrl: _baseUrlCtl.text.trim(),
        model: _modelCtl.text.trim(),
        apiKey: _isOllama ? null : _keyCtl.text.trim(),
        healthy: true,
        latencyMs: r.latencyMs,
      );
    }
    if (!mounted) return;
    setState(() {
      _testing = false;
      _testResult = r;
      _savedProfile = saved;
    });
    ServiceScope.maybeOf(context)?.toasts.show(r.success
        ? (_isOllama
            ? '连接成功 · ${_plat.name} · ${r.latencyMs ?? 0}ms · 本地模型就绪，无需 Key'
            : '连接成功 · ${_plat.name} · ${r.latencyMs ?? 0}ms · Key 已存入系统密钥串')
        : '连接失败 · ${r.errorCode ?? 'unknown'}（可继续，也可先跳过）');
  }

  /// 「检测本地 Ollama」：Ollama 平台的等价动作（无 Key，纯探测）。
  Future<void> _checkLocal() async {
    if (_checkingLocal) return;
    setState(() {
      _checkingLocal = true;
      _testResult = null;
    });
    final r = await widget.store.testConnection(
      platform: 'Ollama（本地）',
      baseUrl: _baseUrlCtl.text.trim(),
      model: _modelCtl.text.trim(),
    );
    if (!mounted) return;
    ProviderProfile? saved;
    if (r.success) {
      saved = await widget.store.addProfileWithKey(
        platform: 'Ollama（本地）',
        baseUrl: _baseUrlCtl.text.trim(),
        model: _modelCtl.text.trim(),
        healthy: true,
        latencyMs: r.latencyMs,
      );
    }
    if (!mounted) return;
    setState(() {
      _checkingLocal = false;
      _testResult = r;
      _savedProfile = saved;
    });
  }

  /// 权限自检：走原生桥 permissionStatus（macOS 返回 accessibility /
  /// inputMonitoring / microphone；Web 预览降级为空 map → UI 如实标注）。
  Future<void> _refreshPerms() async {
    setState(() => _permChecking = true);
    final bridge = ServiceScope.maybeOf(context)?.bridge;
    Map<String, bool> m = const {};
    try {
      m = await bridge?.permissionStatus() ?? const {};
    } catch (_) {
      m = const {};
    }
    if (!mounted) return;
    setState(() {
      _perms = m;
      _permChecking = false;
    });
  }

  Future<void> _openSettings(String kind, String label) async {
    final bridge = ServiceScope.maybeOf(context)?.bridge;
    if (bridge == null) return;
    try {
      await bridge.openPermissionSettings(kind);
    } catch (_) {
      // Web 预览：无系统设置可拉起，按钮点击保留（fallback 行为为 no-op）
    }
    if (!mounted) return;
    ServiceScope.maybeOf(context)?.toasts.show(
          '已在系统设置打开「$label」——授权后回到本窗口，会自动重新检测',
        );
  }

  /// 权限态三分：true 已授权 / false 待授权 / null 无法检测（Web 预览）。
  ({String label, Color color, bool granted}) _permState(String kind) {
    final s = LfScheme.of(context);
    final v = _perms[kind];
    return switch (v) {
      true => (label: '已授权', color: s.success, granted: true),
      false => (label: '待授权', color: s.warning, granted: false),
      null => (label: '未检测', color: s.text3, granted: false),
    };
  }

  // ---------------- UI ----------------

  @override
  Widget build(BuildContext context) {
    final s = LfScheme.of(context);
    return Stack(
      children: [
        Column(
          children: [
            HostTitleBar(title: widget.hostTitle),
            Expanded(
              child: Container(
                color: s.bgSource,
                child: LayoutBuilder(
                  builder: (context, box) => SingleChildScrollView(
                    child: ConstrainedBox(
                      constraints: BoxConstraints(minHeight: box.maxHeight),
                      child: Center(child: _wizardCard()),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
        Positioned(top: 44, right: 16, child: demoControls()),
      ],
    );
  }

  Widget _wizardCard() {
    return Container(
      width: 560,
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        color: LfScheme.of(context).bgWindow,
        borderRadius: BorderRadius.circular(LfDimens.rPopover),
        border: Border.all(color: LfScheme.of(context).divider),
        boxShadow: LfScheme.of(context).shadowWindow,
      ),
      child: AnimatedSwitcher(
        duration: LfDimens.tBase,
        child: KeyedSubtree(
          key: ValueKey(stateIdx),
          child: switch (stateIdx) {
            1 => _stepKey(),
            2 => _stepHotkeys(),
            3 => _stepPerms(),
            4 => _stepDone(),
            _ => _stepPlatform(),
          },
        ),
      ),
    );
  }

  Widget _dots(int active) {
    final s = LfScheme.of(context);
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        for (var i = 0; i < 3; i++) ...[
          if (i > 0) const SizedBox(width: 6),
          AnimatedContainer(
            duration: LfDimens.tBase,
            width: i == active ? 18 : 7,
            height: 7,
            decoration: BoxDecoration(
              color: i < active ? s.success : (i == active ? s.brand : s.dividerStrong),
              borderRadius: BorderRadius.circular(LfDimens.rPill),
            ),
          ),
        ],
      ],
    );
  }

  Widget _kicker(String t) => Text(
        t,
        style: TextStyle(
          fontSize: LfDimens.fs2xs,
          fontWeight: FontWeight.w700,
          letterSpacing: 1.2,
          color: LfScheme.of(context).brand,
        ),
      );

  Widget _title(String t) => Padding(
        padding: const EdgeInsets.only(top: 6, bottom: 6),
        child: Text(t, style: TextStyle(fontSize: LfDimens.fsXl, fontWeight: FontWeight.w700, color: LfScheme.of(context).text)),
      );

  Widget _sub(String t) => Text(
        t,
        textAlign: TextAlign.center,
        style: TextStyle(fontSize: LfDimens.fsSm, height: 1.55, color: LfScheme.of(context).text2),
      );

  Widget _actions(List<Widget> buttons) => Padding(
        padding: const EdgeInsets.only(top: 20),
        child: Row(
          children: [
            for (final (i, b) in buttons.indexed) ...[
              if (i > 0) const SizedBox(width: 8),
              if (b is LfButton && (b.kind == LfButtonKind.primary)) Expanded(child: b) else b,
            ],
          ],
        ),
      );

  // --- 态 0 · 选平台（真实选择，决定后续 Key 步行为）---
  Widget _stepPlatform() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _dots(0),
        const SizedBox(height: 14),
        _kicker('Welcome to LinguaFlow'),
        _title('选择你的模型平台'),
        _sub('BYOK：用你自己的 Key，任意平台。没有 Key？选「Ollama 本地」零 Key 完成体验。'),
        const SizedBox(height: 16),
        GridView.count(
          crossAxisCount: 3,
          mainAxisSpacing: 8,
          crossAxisSpacing: 8,
          // 2.05：给 compact 卡（logo 24 + 名称）留足高度，避免 600px 测试视口下溢出
          childAspectRatio: 2.05,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          children: [
            for (final (i, p) in kOnboardingCatalog.indexed)
              PlatCard(
                item: p,
                selected: i == selectedPlat,
                compact: true,
                onTap: () => setState(() => _applyPlatform(i)),
              ),
          ],
        ),
        _actions([
          LfButton(label: '稍后再说', onPressed: () => setStateAt(3)),
          LfButton(label: '下一步', kind: LfButtonKind.primary, onPressed: () => setStateAt(1)),
        ]),
      ],
    );
  }

  /// 表单小输入行（真实 TextField）。
  Widget _field({
    required String label,
    required TextEditingController ctl,
    bool obscure = false,
    bool requiredField = false,
    String? hint,
  }) {
    final s = LfScheme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(label, style: TextStyle(fontSize: LfDimens.fs2xs, fontWeight: FontWeight.w600, color: s.text2)),
            if (requiredField)
              Text(' *', style: TextStyle(fontSize: LfDimens.fs2xs, color: s.error)),
            const SizedBox(width: 6),
            if (hint != null)
              Expanded(
                child: Text(
                  hint,
                  style: TextStyle(fontSize: LfDimens.fs2xs, color: s.text3),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
          ],
        ),
        const SizedBox(height: 5),
        TextField(
          controller: ctl,
          obscureText: obscure,
          style: TextStyle(fontSize: LfDimens.fsSm, color: s.text),
          decoration: InputDecoration(
            isDense: true,
            contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(LfDimens.rInput),
              borderSide: BorderSide(color: s.dividerStrong),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(LfDimens.rInput),
              borderSide: BorderSide(color: s.dividerStrong),
            ),
          ),
        ),
      ],
    );
  }

  /// 测试结果内联条（成功绿 / 失败红 + 原始返回，绝不静默）。
  Widget? _testResultBar() {
    final s = LfScheme.of(context);
    final r = _testResult;
    if (r == null) return null;
    if (r.success) {
      return Container(
        width: double.infinity,
        margin: const EdgeInsets.only(top: 8),
        padding: const EdgeInsets.all(9),
        decoration: BoxDecoration(
          color: s.success.withValues(alpha: 0.10),
          borderRadius: BorderRadius.circular(LfDimens.rCard),
          border: Border.all(color: s.success.withValues(alpha: 0.4)),
        ),
        child: Row(
          children: [
            LfIcons.icon('check', size: 12, color: s.success),
            const SizedBox(width: 7),
            Expanded(
              child: Text(
                '连接成功 · ${r.latencyMs ?? 0}ms · ${_savedProfile != null ? (_isOllama ? '已保存（本地模型，零 Key）' : '已保存，Key 已存入系统密钥串') : '已保存'}',
                style: TextStyle(fontSize: LfDimens.fsXs, color: s.text),
              ),
            ),
          ],
        ),
      );
    }
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(top: 8),
      padding: const EdgeInsets.all(9),
      decoration: BoxDecoration(
        color: s.error.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(LfDimens.rCard),
        border: Border.all(color: s.error.withValues(alpha: 0.45)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              LfIcons.icon('warn', size: 12, color: s.error),
              const SizedBox(width: 7),
              Text(
                '测试失败 · ${r.errorCode ?? 'unknown'}（未保存，可重试或跳过）',
                style: TextStyle(fontSize: LfDimens.fsXs, fontWeight: FontWeight.w600, color: s.error),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            '模型方返回：${r.errorMessage ?? '（无响应体）'}',
            style: TextStyle(fontSize: LfDimens.fs2xs, color: s.error, height: 1.5),
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  // --- 态 1 · 填 Key（真实：testConnection → addProfileWithKey）---
  Widget _stepKey() {
    final s = LfScheme.of(context);
    final testing = _testing || _checkingLocal;
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _dots(1),
        const SizedBox(height: 14),
        Center(child: _kicker('BYOK')),
        Center(child: _title(_isOllama ? '接通本地模型' : '填入 API Key')),
        Center(child: _sub(_isOllama
            ? '本地模型无需任何 Key；请求不出本机，离线可用。'
            : 'Key 只存本机系统密钥串；请求直连模型方，不经我方服务器。')),
        const SizedBox(height: 16),
        if (!_isOllama) ...[
          _field(
            label: 'API Key',
            requiredField: true,
            obscure: true,
            ctl: _keyCtl,
            hint: '存入系统密钥串，明文不落盘',
          ),
          const SizedBox(height: 6),
          Padding(
            padding: const EdgeInsets.only(bottom: 2),
            child: Row(
              children: [
                Text('申请链接：', style: TextStyle(fontSize: LfDimens.fs2xs, color: s.text3)),
                for (final (i, n) in ['OpenAI', 'Anthropic', 'Gemini', 'DeepSeek'].indexed) ...[
                  if (i > 0) Text(' · ', style: TextStyle(fontSize: LfDimens.fs2xs, color: s.text3)),
                  InlineLink(n),
                ],
              ],
            ),
          ),
        ] else ...[
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: s.success.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(LfDimens.rCard),
              border: Border.all(color: s.success.withValues(alpha: 0.35)),
            ),
            child: Row(
              children: [
                LfIcons.icon('check', size: 12, color: s.success),
                const SizedBox(width: 7),
                Expanded(
                  child: Text(
                    '本地模型 · 无需 API Key · 数据不出本机（零 Key 也能完整体验成稿链路）',
                    style: TextStyle(fontSize: LfDimens.fsXs, color: s.success),
                  ),
                ),
              ],
            ),
          ),
        ],
        const SizedBox(height: 10),
        _field(label: 'BaseURL', ctl: _baseUrlCtl, hint: '默认官方端点 / 本地端口'),
        const SizedBox(height: 10),
        _field(label: '模型', ctl: _modelCtl, hint: '可先保留默认'),
        if (testing) ...[
          const SizedBox(height: 10),
          Row(
            children: [
              const LfSpinner(size: 10),
              const SizedBox(width: 7),
              Text(
                _checkingLocal ? '检测本地 Ollama…' : '测试连接中…',
                style: TextStyle(fontSize: LfDimens.fsXs, color: s.text2),
              ),
            ],
          ),
        ],
        if (_testResult != null) _testResultBar()!,
        _actions([
          LfButton(label: '上一步', onPressed: () => setStateAt(0)),
          if (_isOllama)
            LfButton(
              label: _checkingLocal ? '检测中…' : '检测本地连接',
              onPressed: _checkingLocal ? null : _checkLocal,
            )
          else
            LfButton(
              label: _testing ? '测试中…' : '测试连接并保存',
              onPressed: _testing ? null : _testAndSave,
            ),
          LfButton(label: _isOllama ? '跳过，直接下一步' : '跳过，先用演示流式', onPressed: () => setStateAt(2)),
          LfButton(label: '下一步', kind: LfButtonKind.primary, onPressed: () => setStateAt(2)),
        ]),
      ],
    );
  }

  // --- 态 2 · 设热键（真实：store.hotkeys 当前值 + 注册状态）---
  Widget _stepHotkeys() {
    final s = LfScheme.of(context);
    final scope = ServiceScope.maybeOf(context);
    final items = widget.store.hotkeys;
    final hkA = items.where((h) => h.id == 'hk-a').firstOrNull ?? AppStore.kDefaultHotkeys[0];
    final hkB = items.where((h) => h.id == 'hk-b').firstOrNull ?? AppStore.kDefaultHotkeys[1];
    final native = scope?.hotkeys.lastReport?.native == true;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _dots(2),
        const SizedBox(height: 14),
        _kicker('Hotkeys'),
        _title('设置你的热键'),
        _sub('两类手感必须区分：唤起键单次触发、语音键按住触发（PRD §4）。全部可改。'),
        const SizedBox(height: 16),
        Container(
          decoration: BoxDecoration(
            color: s.bgSource,
            borderRadius: BorderRadius.circular(LfDimens.rCard),
            border: Border.all(color: s.divider),
          ),
          clipBehavior: Clip.antiAlias,
          child: Column(children: [HotkeyRow(item: hkA), HotkeyRow(item: hkB)]),
        ),
        const SizedBox(height: 8),
        Text(
          '当前生效范围：${native ? '原生全局（含其他应用）' : '应用内（浏览器/预览环境无法抢占全局按键；桌面端授权后自动升级为全局）'}',
          style: TextStyle(fontSize: LfDimens.fs2xs, color: s.text3),
        ),
        _actions([
          LfButton(label: '上一步', onPressed: () => setStateAt(1)),
          LfButton(label: '下一步', kind: LfButtonKind.primary, onPressed: () => setStateAt(3)),
        ]),
      ],
    );
  }

  // --- 态 3 · 权限引导（真实自检 + 打开设置 + 回来自动刷新）---
  Widget _stepPerms() {
    final s = LfScheme.of(context);
    final nativeAvailable = ServiceScope.maybeOf(context)?.bridge.available == true;
    final hasPerms = _perms.isNotEmpty; // Web 预览降级为空 map

    Widget permCard(String iconName, String name, String kind, String desc) {
      final st = _permState(kind);
      return Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: s.bgSource,
          borderRadius: BorderRadius.circular(LfDimens.rCard),
          border: Border.all(
            color: st.granted ? s.success.withValues(alpha: 0.45) : s.divider,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: st.granted ? s.success.withValues(alpha: 0.12) : s.brandSoft,
                borderRadius: BorderRadius.circular(9),
              ),
              child: Center(
                child: LfIcons.icon(iconName, size: 17, color: st.granted ? s.success : s.brand),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(name, style: TextStyle(fontSize: LfDimens.fsSm, fontWeight: FontWeight.w600, color: s.text)),
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
                        decoration: BoxDecoration(
                          color: st.color.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          '· ${st.label}',
                          style: TextStyle(fontSize: LfDimens.fs2xs, fontWeight: FontWeight.w600, color: st.color),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(desc, style: TextStyle(fontSize: LfDimens.fs2xs, color: s.text2)),
                ],
              ),
            ),
            const SizedBox(width: 8),
            st.granted
                ? LfIcons.icon('check', size: 16, color: s.success)
                : LfButton(
                    label: '打开设置',
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    onPressed: () => unawaited(_openSettings(kind, name)),
                  ),
          ],
        ),
      );
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _dots(2),
        const SizedBox(height: 14),
        _kicker('Permissions'),
        _title('授予两个系统权限'),
        _sub('全局热键需要以下权限；只用于监听热键与读取选中文本，不做任何采集（§8 隐私）。'),
        const SizedBox(height: 16),
        permCard('accessibility', '辅助功能', 'accessibility', '监听全局热键（Fn / ⌥ 组合）并向其他应用注入文本'),
        const SizedBox(height: 8),
        permCard('mouse', '输入监控', 'inputMonitoring', '读取划词选区，实现流程 C / D'),
        const SizedBox(height: 10),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (_permChecking) ...[
              const LfSpinner(size: 10),
              const SizedBox(width: 6),
              Text('检测中…', style: TextStyle(fontSize: LfDimens.fs2xs, color: s.text2)),
            ] else ...[
              LfButton(
                label: '重新检测',
                icon: 'refresh',
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                onPressed: _refreshPerms,
              ),
              const SizedBox(width: 8),
              Text(
                hasPerms ? '授权后切回本窗口会自动重新检测' : '当前环境未接原生权限接口（Web 预览）——桌面端将真实拉起系统设置',
                style: TextStyle(fontSize: LfDimens.fs2xs, color: nativeAvailable ? s.text3 : s.warning),
              ),
            ],
          ],
        ),
        _actions([
          LfButton(label: '上一步', onPressed: () => setStateAt(2)),
          LfButton(label: '完成', kind: LfButtonKind.primary, onPressed: () => setStateAt(4)),
        ]),
      ],
    );
  }

  // --- 态 4 · 完成（真实反映本次向导结果）---
  Widget _stepDone() {
    final s = LfScheme.of(context);
    final p = _savedProfile ?? widget.store.defaultProfile;
    final configured = p != null;
    final label = configured ? '${p.platform} · ${p.model}' : '演示流式 · MockProvider';
    final sub = configured
        ? '当前默认：$label${p.keyRef != null ? '（Key 已入系统密钥串）' : '（本地 · 离线 · 零成本）'}。随时可在「模型配置」切换或新增 Provider。'
        : '未配置模型：先走演示流式兜底（绝不白屏，PRD §7）。随时可在「模型配置」接入 OpenAI / Claude / Gemini / Ollama。';
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _dots(2),
        const SizedBox(height: 20),
        Container(
          width: 56,
          height: 56,
          decoration: BoxDecoration(gradient: s.brandGrad, borderRadius: BorderRadius.circular(16)),
          child: Center(child: LfIcons.icon('check', size: 26, color: Colors.white)),
        ),
        const SizedBox(height: 12),
        _title('一切就绪'),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: _sub(sub),
        ),
        const SizedBox(height: 14),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Badge(configured ? label : '演示流式', live: configured),
            const SizedBox(width: 8),
            const Badge('零遥测'),
            const SizedBox(width: 8),
            const Badge('五端同步'),
          ],
        ),
        _actions([
          LfButton(
            label: '开始使用 · 按住 Fn 说话 →',
            kind: LfButtonKind.primary,
            onPressed: () {
              // 真实落状态：onboarded 持久化 + 选中平台记录
              widget.store.setOnboarded(_plat.name);
              setStateAt(4);
              ServiceScope.maybeOf(context)
                  ?.toasts
                  .show('首次引导完成 · ${configured ? label : '演示流式兜底'}');
            },
          ),
        ]),
      ],
    );
  }
}
