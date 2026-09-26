import 'dart:async';

import 'package:flutter/material.dart' hide Badge;
import 'package:flutter/services.dart';

import '../../core/icons/lf_icons.dart';
import '../../core/theme/tokens.dart';
import '../../models/models.dart';
import '../../providers/catalog.dart';
import '../../providers/provider.dart';
import '../../services/app_store.dart';
import '../../services/hotkeys.dart';
import '../../services/service_scope.dart';
import '../components/cards.dart';
import '../components/common.dart';
import '../overlays/recorder_pill.dart' show LfSpinner;

// ==================================================================
// H · 主窗首页（历史 + 用量统计，PRD §6 #6）
// ==================================================================
class HomePage extends StatelessWidget {
  const HomePage({super.key, required this.store, this.onGoOnboarding});

  final AppStore store;
  final VoidCallback? onGoOnboarding;

  @override
  Widget build(BuildContext context) {
    final s = LfScheme.of(context);
    return ListenableBuilder(
      listenable: store,
      builder: (context, _) {
        final empty = store.history.isEmpty;
        return SingleChildScrollView(
          padding: const EdgeInsets.all(22),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const PageTitle(title: '首页', subtitle: '历史记录 · 用量统计（本地保存，不上传）'),
              if (empty)
                Center(
                  child: EmptyState(
                    iconName: 'mic',
                    title: '还没有任何记录',
                    subtitle:
                        '按住 Fn 说一句话，或用 ⌥Space 悬浮窗输入；历史与用量统计会出现在这里。绝不白屏：未配置模型时会先引导本地模型试用。',
                    actions: [
                      if (onGoOnboarding != null)
                        LfButton(
                          label: '先去完成首次引导',
                          kind: LfButtonKind.primary,
                          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
                          onPressed: onGoOnboarding,
                        ),
                    ],
                  ),
                )
              else ...[
                Row(
                  children: [
                    Expanded(child: StatCard(value: '${store.todayCalls}', unit: '次', label: '今日调用')),
                    const SizedBox(width: 10),
                    Expanded(child: StatCard(value: '${store.monthTokens}', unit: 'K tok', label: '本月 token')),
                    const SizedBox(width: 10),
                    Expanded(child: StatCard(value: '¥${store.monthCost}', label: '本月预估花费')),
                    const SizedBox(width: 10),
                    Expanded(child: StatCard(value: '${store.avgFirstTokenMs}', unit: 'ms', label: '平均首字延迟')),
                  ],
                ),
                const SectionTitle('用量 · token 趋势（天 / 周 / 月）'),
                _UsageToggleRow(),
                const SizedBox(height: 10),
                const UsageChart(data: [
                  ('周一', 34), ('周二', 52), ('周三', 41), ('周四', 66),
                  ('周五', 58), ('周六', 22), ('今日', 47),
                ]),
                const SectionTitle('历史记录（点行可回看 · 支持收藏 / 复制 / 重新注入）'),
                Container(
                  decoration: BoxDecoration(
                    color: s.bgWindow,
                    borderRadius: BorderRadius.circular(LfDimens.rCard),
                    border: Border.all(color: s.divider),
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: Column(
                    children: [
                      for (final r in store.history)
                        HistoryRow(
                          record: r,
                          onTap: () {},
                        ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        );
      },
    );
  }
}

class _UsageToggleRow extends StatefulWidget {
  @override
  State<_UsageToggleRow> createState() => _UsageToggleRowState();
}

class _UsageToggleRowState extends State<_UsageToggleRow> {
  int active = 0;

  @override
  Widget build(BuildContext context) {
    final s = LfScheme.of(context);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (final (i, label) in const ['天', '周', '月'].indexed)
          GestureDetector(
            onTap: () => setState(() => active = i),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
              decoration: BoxDecoration(
                color: active == i ? s.brand : Colors.transparent,
                borderRadius: BorderRadius.horizontal(
                  left: Radius.circular(i == 0 ? 7 : 0),
                  right: Radius.circular(i == 2 ? 7 : 0),
                ),
              ),
              child: Text(
                label,
                style: TextStyle(
                  fontSize: LfDimens.fsSm,
                  fontWeight: FontWeight.w600,
                  color: active == i ? Colors.white : s.text2,
                ),
              ),
            ),
          ),
      ],
    );
  }
}

// ==================================================================
// I · 模型配置（灵魂页面：空/列表/新增/测试失败 四态，PRD §6 #7）
// ==================================================================
class ProvidersPage extends StatefulWidget {
  const ProvidersPage({super.key, required this.store, this.onGoOnboarding});

  final AppStore store;
  final VoidCallback? onGoOnboarding;

  @override
  State<ProvidersPage> createState() => _ProvidersPageState();
}

class _ProvidersPageState extends State<ProvidersPage> {
  int view = 1; // 0 空态 / 1 列表 / 2 新增表单 / 3 测试结果
  int selectedPlat = 0;
  final _baseUrl = TextEditingController();
  final _key = TextEditingController();
  final _model = TextEditingController();
  bool _obscure = true;

  // T-021 真实测试态
  bool _testing = false;
  ConnectionTestResult? _lastTest;
  List<String> _models = const [];
  String? _modelError;

  @override
  void initState() {
    super.initState();
    _applyPlatform(0);
  }

  @override
  void dispose() {
    _baseUrl.dispose();
    _key.dispose();
    _model.dispose();
    super.dispose();
  }

  void _applyPlatform(int i) {
    selectedPlat = i;
    final d = widget.store.formDefaults(kPlatformCatalog[i].name);
    _baseUrl.text = d.baseUrl;
    _model.text = d.model;
    _key.text = '';
    _lastTest = null;
    _models = const [];
    _modelError = null;
  }

  bool get _needsKey =>
      kPlatformCatalog[selectedPlat].kind != PlatformKind.ollama;

  /// T-021 · 真实「测试连接并保存」：打模型方 /models（或 messages），
  /// 成功才写入 Key 到 SecureStore；失败展示真实错误码 + 原始返回。
  Future<void> _testAndSave() async {
    final plat = kPlatformCatalog[selectedPlat];
    final baseUrl = _baseUrl.text.trim();
    final model = _model.text.trim();
    final key = _key.text.trim();

    if (baseUrl.isEmpty || model.isEmpty || (_needsKey && key.isEmpty)) {
      setState(() {
        view = 3;
        _lastTest = ConnectionTestResult(
          success: false,
          errorCode: 'config',
          errorMessage: 'BaseURL / 模型${_needsKey ? ' / API Key' : ''} 不能为空',
        );
      });
      return;
    }

    setState(() {
      view = 3;
      _testing = true;
      _lastTest = null;
    });

    final result = await widget.store.testConnection(
      platform: plat.name,
      baseUrl: baseUrl,
      model: model,
      apiKey: key,
    );
    if (!mounted) return;

    final ok = result.success;
    if (ok) {
      await widget.store.addProfileWithKey(
        platform: plat.name,
        baseUrl: baseUrl,
        model: model,
        apiKey: key,
        healthy: true,
        latencyMs: result.latencyMs,
      );
    }
    if (!mounted) return;
    setState(() {
      _testing = false;
      _lastTest = result;
      if (ok) view = 1;
    });

    final scope = ServiceScope.maybeOf(context);
    scope?.toasts.show(ok
        ? '连接成功 · ${plat.name} · ${result.latencyMs ?? 0}ms'
        : '连接失败 · ${result.errorCode ?? 'unknown'}');
  }

  /// T-021 · 真实「拉取模型列表」。
  Future<void> _fetchModels() async {
    final plat = kPlatformCatalog[selectedPlat];
    setState(() {
      _models = const [];
      _modelError = null;
    });
    try {
      final list = await widget.store.fetchModels(
        platform: plat.name,
        baseUrl: _baseUrl.text.trim(),
        model: _model.text.trim(),
        apiKey: _key.text.trim(),
      );
      if (!mounted) return;
      setState(() {
        _models = list.take(40).toList();
        if (_models.isEmpty) _modelError = '模型方返回空列表';
      });
    } on LfProviderException catch (e) {
      if (!mounted) return;
      setState(() => _modelError = '${e.code.name} · ${_clip(e.detail, 160)}');
    } catch (e) {
      if (!mounted) return;
      setState(() => _modelError = _clip(e.toString(), 160));
    }
  }

  static String _clip(String s, int n) =>
      s.length <= n ? s : '${s.substring(0, n)}…';

  @override
  Widget build(BuildContext context) {
    final s = LfScheme.of(context);
    return ListenableBuilder(
      listenable: widget.store,
      builder: (context, _) {
        final empty = widget.store.profiles.isEmpty;
        final effectiveView = empty && view == 1 ? 0 : view;
        return SingleChildScrollView(
          padding: const EdgeInsets.all(22),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const PageTitle(
                title: '模型配置',
                subtitle: '配置完全本地保存（系统密钥串）；请求直连模型方 BaseURL，不经我方服务器（ADR-001）。',
              ),
              if (effectiveView == 0)
                Center(
                  child: EmptyState(
                    iconName: 'chip',
                    title: '还没有配置任何模型',
                    subtitle: '添加一个 Provider（OpenAI 兼容 / Claude / Gemini / Ollama…），或先体验本地模型——无需任何 Key。',
                    actions: [
                      LfButton(
                        label: ' 添加 Provider',
                        icon: 'plus',
                        kind: LfButtonKind.primary,
                        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
                        onPressed: () => setState(() => view = 2),
                      ),
                      LfButton(
                        label: '先用本地模型试用',
                        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
                        onPressed: widget.onGoOnboarding,
                      ),
                    ],
                  ),
                )
              else if (effectiveView == 1) ...[
                const SectionTitle('当前默认'),
                _CurrentModelRow(store: widget.store),
                const SectionTitle('已添加的 Provider'),
                Column(
                  children: [
                    for (final p in widget.store.profiles)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: ProviderRow(
                          profile: p,
                          onTap: () => widget.store.setDefault(p.id),
                          onDelete: () => widget.store.removeProfile(p.id),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 8),
                LfButton(
                  label: '＋ 添加 Provider',
                  full: true,
                  onPressed: () => setState(() => view = 2),
                ),
              ] else if (effectiveView == 2 || effectiveView == 3) ...[
                const SectionTitle('选择平台'),
                PlatGrid(
                  items: kPlatformCatalog,
                  selectedIndex: selectedPlat,
                  onSelect: (i) => setState(() => _applyPlatform(i)),
                ),
                const SizedBox(height: 16),
                FormFieldRow(
                  label: 'BaseURL',
                  requiredField: true,
                  hint: 'OpenAI 兼容协议；流量直连该地址，零遥测（ADR-001 §2）',
                  child: TextField(controller: _baseUrl, style: const TextStyle(fontSize: LfDimens.fsBase)),
                ),
                const SizedBox(height: 12),
                FormFieldRow(
                  label: 'API Key',
                  requiredField: true,
                  hint: '存入系统密钥串（Keychain / DPAPI / libsecret），明文不落盘 · 各平台申请链接见「首次引导」',
                  child: Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _key,
                          obscureText: _obscure,
                          style: const TextStyle(fontSize: LfDimens.fsBase),
                        ),
                      ),
                      const SizedBox(width: 8),
                      LfButton(
                        label: _obscure ? '显示' : '隐藏',
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        onPressed: () => setState(() => _obscure = !_obscure),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                FormFieldRow(
                  label: '模型',
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: TextField(controller: _model, style: const TextStyle(fontSize: LfDimens.fsBase)),
                          ),
                          const SizedBox(width: 8),
                          LfButton(
                            label: ' 拉取模型列表',
                            icon: 'refresh',
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            onPressed: _fetchModels,
                          ),
                        ],
                      ),
                      if (_modelError != null) ...[
                        const SizedBox(height: 6),
                        Text(
                          '拉取失败 · $_modelError',
                          style: TextStyle(fontSize: LfDimens.fs2xs, color: s.error),
                        ),
                      ] else if (_models.isNotEmpty) ...[
                        const SizedBox(height: 6),
                        Wrap(
                          spacing: 4,
                          runSpacing: 4,
                          children: [
                            for (final m in _models.take(12))
                              GestureDetector(
                                onTap: () => setState(() => _model.text = m),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                                  decoration: BoxDecoration(
                                    color: _model.text == m ? s.brandSoft : s.bgSource,
                                    borderRadius: BorderRadius.circular(5),
                                    border: Border.all(color: _model.text == m ? s.brand : s.divider),
                                  ),
                                  child: Text(
                                    m,
                                    style: TextStyle(
                                      fontSize: LfDimens.fs2xs,
                                      color: _model.text == m ? s.brand : s.text2,
                                    ),
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 14),
                if (effectiveView == 2)
                  LfButton(
                    label: '测试连接并保存',
                    kind: LfButtonKind.primary,
                    full: true,
                    onPressed: _testAndSave,
                  ),
                if (effectiveView == 3) ...[
                  if (_testing) ...[
                    Row(
                      children: [
                        const LfSpinner(size: 12),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            '测试中… ${_baseUrl.text.trim()}',
                            style: TextStyle(fontSize: LfDimens.fsXs, color: s.text2),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ] else if (_lastTest != null) ...[
                    if (_lastTest!.success)
                      // 成功：真实延迟来自模型方响应耗时
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: s.success.withValues(alpha: 0.10),
                          borderRadius: BorderRadius.circular(LfDimens.rCard),
                          border: Border.all(color: s.success.withValues(alpha: 0.4)),
                        ),
                        child: Row(
                          children: [
                            LfIcons.icon('check', size: 13, color: s.success),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                '连接成功 · ${_lastTest!.latencyMs ?? 0}ms · Key 已存入系统密钥串',
                                style: TextStyle(fontSize: LfDimens.fsXs, color: s.text),
                              ),
                            ),
                          ],
                        ),
                      )
                    else ...[
                      InlineError(
                        title: '测试失败 · ${_lastTest!.errorCode ?? 'unknown'}',
                        body: '模型方返回：${_clip(_lastTest!.errorMessage ?? '（无响应体）', 220)}',
                        actions: [
                          InlineLink('→ 返回修改 Key', onTap: () => setState(() => view = 2)),
                          InlineLink('→ 先用本地模型试用', onTap: widget.onGoOnboarding),
                        ],
                      ),
                      const SizedBox(height: 10),
                      LfButton(
                        label: '跳过测试，直接保存（标记为未验证）',
                        full: true,
                        onPressed: () async {
                          final plat = kPlatformCatalog[selectedPlat];
                          await widget.store.addProfileWithKey(
                            platform: plat.name,
                            baseUrl: _baseUrl.text.trim(),
                            model: _model.text.trim(),
                            apiKey: _key.text.trim(),
                            healthy: false,
                          );
                          if (!mounted) return;
                          setState(() => view = 1);
                        },
                      ),
                    ],
                  ],
                ],
              ],
            ],
          ),
        );
      },
    );
  }
}

class _CurrentModelRow extends StatelessWidget {
  const _CurrentModelRow({required this.store});

  final AppStore store;

  @override
  Widget build(BuildContext context) {
    final s = LfScheme.of(context);
    final p = store.defaultProfile;
    final item = kPlatformCatalogLookup(p?.platform ?? '');
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: s.brandSoft,
        borderRadius: BorderRadius.circular(LfDimens.rCard),
        border: Border.all(color: s.brand.withValues(alpha: 0.45)),
      ),
      child: Row(
        children: [
          LogoBox(item?.logo ?? '译', color: Color(item?.color ?? 0xFF4F7CFF), size: 36),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  p?.displayLabel ?? '演示模型（Mock）',
                  style: TextStyle(
                    fontSize: LfDimens.fsBase,
                    fontWeight: FontWeight.w700,
                    color: s.text,
                  ),
                ),
                const SizedBox(height: 1),
                Text(
                  p?.platform.contains('Ollama') == true ? '本地 · 离线 · 零成本' : '直连 ${p?.baseUrl ?? 'local://mock'}',
                  style: TextStyle(fontSize: LfDimens.fsXs, color: s.text2),
                ),
              ],
            ),
          ),
          Badge(p?.healthy == true ? '在线' : '未测', live: p?.healthy == true),
        ],
      ),
    );
  }
}

// ==================================================================
// J · 快捷键（已绑定 / 冲突检测 / 重绑录制，PRD §6 #8）
// ==================================================================
class HotkeysPage extends StatefulWidget {
  const HotkeysPage({super.key, required this.store});

  final AppStore store;

  @override
  State<HotkeysPage> createState() => _HotkeysPageState();
}

class _HotkeysPageState extends State<HotkeysPage> {
  int view = 0; // 0 已绑定 / 1 冲突检测 / 2 重绑录制中
  String? recordingId;
  HotkeyCombo? draftCombo;
  final FocusNode _recordFocus = FocusNode();

  @override
  void dispose() {
    _recordFocus.dispose();
    super.dispose();
  }

  HotkeyManager? get _manager => ServiceScope.maybeOf(context)?.hotkeys;

  void _startRecord(String id) {
    setState(() {
      recordingId = id;
      draftCombo = null;
      view = 2;
    });
    _recordFocus.requestFocus();
  }

  /// T-024 · 真实重绑录制：按下什么就绑什么（Esc 取消）。
  KeyEventResult _onRecordKey(FocusNode node, KeyEvent event) {
    if (recordingId == null || event is! KeyDownEvent) return KeyEventResult.ignored;

    if (event.logicalKey == LogicalKeyboardKey.escape) {
      setState(() {
        recordingId = null;
        view = 1;
      });
      return KeyEventResult.handled;
    }

    final pressed = HardwareKeyboard.instance.logicalKeysPressed;
    final mods = <HotkeyModifier>{};
    String? keyName;
    for (final k in pressed) {
      final m = hotkeyModifierOf(k);
      if (m != null) {
        mods.add(m);
      } else {
        keyName ??= hotkeyKeyNameOf(k);
      }
    }
    if (keyName == null) return KeyEventResult.handled; // 只按了修饰键，继续等主键

    final combo = HotkeyCombo(modifiers: mods, key: keyName);
    setState(() => draftCombo = combo);
    unawaited(_applyRebind(recordingId!, combo));
    return KeyEventResult.handled;
  }

  Future<void> _applyRebind(String id, HotkeyCombo combo) async {
    final manager = _manager;
    if (manager == null) return;
    final conflict = await manager.rebind(id, combo);
    if (!mounted) return;
    final label = manager.items.firstWhere((h) => h.id == id, orElse: () => manager.items.first).label;
    setState(() {
      recordingId = null;
      view = 1;
    });
    ServiceScope.maybeOf(context)?.toasts.show(
          conflict == null
              ? '「$label」已重绑为 ${combo.format(manager.platform)}'
              : '「$label」已保存，但冲突：${conflict.owner}',
        );
  }

  @override
  Widget build(BuildContext context) {
    final s = LfScheme.of(context);
    final scope = ServiceScope.maybeOf(context);
    final manager = scope?.hotkeys;
    return ListenableBuilder(
      listenable: widget.store,
      builder: (context, _) {
        final items = widget.store.hotkeys;
        final conflicts = manager?.detectConflicts() ?? const {};
        final recordingLabel = recordingId == null
            ? ''
            : items.firstWhere((h) => h.id == recordingId, orElse: () => items.first).label;
        return SingleChildScrollView(
          padding: const EdgeInsets.all(22),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const PageTitle(
                title: '快捷键',
                subtitle: '全部可重绑，实时冲突检测；唤起键单次触发、语音键按住触发，两类手感必须区分（PRD §4）。',
              ),
              Row(
                children: [
                  for (final (i, label) in const ['已绑定', '冲突检测', '重绑录制中'].indexed) ...[
                    _StateChip(
                      label,
                      active: view == i,
                      onTap: () => setState(() => view = i),
                    ),
                    const SizedBox(width: 6),
                  ],
                  const Spacer(),
                  if (manager != null) ...[
                    LfButton(
                      label: manager.paused ? '已禁用' : '临时禁用',
                      icon: manager.paused ? 'x' : 'pause',
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      onPressed: () async => manager.setPaused(!manager.paused),
                    ),
                    const SizedBox(width: 6),
                    LfButton(
                      label: '恢复默认',
                      icon: 'rotate',
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      onPressed: () async => manager.resetToDefaults(AppStore.kDefaultHotkeys),
                    ),
                  ],
                ],
              ),
              const SizedBox(height: 12),
              if (view == 2 && recordingId != null) ...[
                Focus(
                  autofocus: true,
                  focusNode: _recordFocus,
                  onKeyEvent: _onRecordKey,
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: s.brandSoft,
                      borderRadius: BorderRadius.circular(LfDimens.rCard),
                      border: Border.all(color: s.brand.withValues(alpha: 0.4)),
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: s.brand,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            draftCombo == null ? '…' : draftCombo!.format(manager?.platform ?? HotkeyPlatform.macOS),
                            style: const TextStyle(fontSize: LfDimens.fsSm, fontWeight: FontWeight.w700, color: Colors.white),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            '正在录制「$recordingLabel」的新组合键——请按下组合（如 ⌥ J）',
                            style: TextStyle(fontSize: LfDimens.fsSm, color: s.text),
                          ),
                        ),
                        Text(
                          'Esc 取消',
                          style: TextStyle(
                            fontSize: LfDimens.fsXs,
                            color: s.text2,
                            decoration: TextDecoration.underline,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 12),
              ],
              if (view == 1) ...[
                if (conflicts.isEmpty)
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: s.success.withValues(alpha: 0.10),
                      borderRadius: BorderRadius.circular(LfDimens.rCard),
                      border: Border.all(color: s.success.withValues(alpha: 0.4)),
                    ),
                    child: Row(
                      children: [
                        LfIcons.icon('check', size: 13, color: s.success),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            '未检测到冲突 · ${manager?.lastReport?.summary ?? ''}',
                            style: TextStyle(fontSize: LfDimens.fsXs, color: s.text),
                          ),
                        ),
                      ],
                    ),
                  )
                else
                  InlineError(
                    title: '检测到 ${conflicts.length} 处热键冲突',
                    iconName: 'warn',
                    body: conflicts.values
                        .map((c) => '· ${items.firstWhere((h) => h.id == c.hotkeyId, orElse: () => items.first).label}：${c.owner}（${c.reason}）')
                        .join('\n'),
                  ),
                const SizedBox(height: 12),
              ],
              Container(
                decoration: BoxDecoration(
                  color: s.bgWindow,
                  borderRadius: BorderRadius.circular(LfDimens.rCard),
                  border: Border.all(color: s.divider),
                ),
                clipBehavior: Clip.antiAlias,
                child: Column(
                  children: [
                    for (final k in items)
                      HotkeyRow(
                        item: k,
                        onRebind: () => _startRecord(k.id),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              Text(
                '提示：macOS 全局热键需授予「辅助功能 + 输入监控」权限，首次启动走授权引导（见「首次引导」页）。热键监听崩溃自愈，更新不丢配置（PRD §8）。\n'
                '当前生效范围：${manager?.lastReport?.native == true ? '原生全局（含其他应用）' : '应用内（浏览器/预览环境无法抢占全局按键）'}。',
                style: TextStyle(fontSize: LfDimens.fsXs, color: s.text3, height: 1.7),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _StateChip extends StatelessWidget {
  const _StateChip(this.label, {required this.active, required this.onTap});

  final String label;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final s = LfScheme.of(context);
    return Material(
      color: active ? s.brand : s.bgWindow,
      borderRadius: BorderRadius.circular(6),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(6),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(6),
            border: Border.all(color: active ? s.brand : s.dividerStrong),
          ),
          child: Text(
            label,
            style: TextStyle(
              fontSize: LfDimens.fsXs,
              fontWeight: FontWeight.w600,
              color: active ? Colors.white : s.text2,
            ),
          ),
        ),
      ),
    );
  }
}
