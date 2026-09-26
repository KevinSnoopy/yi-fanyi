import 'package:flutter/material.dart' hide Badge;

import '../../core/icons/lf_icons.dart';
import '../../core/theme/tokens.dart';
import '../../models/models.dart';
import '../../providers/catalog.dart';
import '../components/cards.dart';
import '../components/common.dart';
import '../overlays/floating_windows.dart';
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
// L 页 · 首次引导 —— PRD §6 #10（原型 Tab L 五态向导，B.3 验收项）
// 选平台 → 填 Key（可跳过走本地试用）→ 设热键 → 权限引导 → 完成
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

class _OnboardingPageState extends State<OnboardingPage> with FlowDemoStateMixin {
  int selectedPlat = 5;

  @override
  List<String> get stateLabels => const ['选平台', '填 Key', '设热键', '权限引导', '完成'];

  @override
  void initState() {
    super.initState();
    setStateAt(0);
  }

  @override
  void replay() => setStateAt(0);

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

  // --- 态 0 · 选平台 ---
  Widget _stepPlatform() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _dots(0),
        const SizedBox(height: 14),
        _kicker('Welcome to LinguaFlow'),
        _title('选择你的模型平台'),
        _sub('BYOK：用你自己的 Key，任意平台。没有 Key？可先用本地模型零门槛体验。'),
        const SizedBox(height: 16),
        GridView.count(
          crossAxisCount: 3,
          mainAxisSpacing: 8,
          crossAxisSpacing: 8,
          childAspectRatio: 2.6,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          children: [
            for (final (i, p) in kOnboardingCatalog.indexed)
              PlatCard(
                item: p,
                selected: i == selectedPlat,
                compact: true,
                onTap: () => setState(() => selectedPlat = i),
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

  // --- 态 1 · 填 Key ---
  Widget _stepKey() {
    final s = LfScheme.of(context);
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _dots(1),
        const SizedBox(height: 14),
        Center(child: _kicker('BYOK')),
        Center(child: _title('填入 API Key')),
        Center(child: _sub('Key 只存本机系统密钥串；请求直连模型方，不经我方服务器。')),
        const SizedBox(height: 16),
        FormFieldRow(
          label: 'API Key',
          requiredField: true,
          child: Container(
            height: 34,
            padding: const EdgeInsets.symmetric(horizontal: 10),
            decoration: BoxDecoration(
              color: s.bgSource,
              borderRadius: BorderRadius.circular(LfDimens.rInput),
              border: Border.all(color: s.dividerStrong),
            ),
            alignment: Alignment.centerLeft,
            child: Text('sk-… / sk-ant-… / AIza…', style: TextStyle(fontSize: LfDimens.fsSm, color: s.text3)),
          ),
        ),
        const SizedBox(height: 6),
        Row(
          children: [
            Text('申请链接：', style: TextStyle(fontSize: LfDimens.fs2xs, color: s.text3)),
            for (final (i, n) in ['OpenAI', 'Anthropic', 'Gemini', 'DeepSeek'].indexed) ...[
              if (i > 0) Text(' · ', style: TextStyle(fontSize: LfDimens.fs2xs, color: s.text3)),
              InlineLink(n),
            ],
          ],
        ),
        const SizedBox(height: 10),
        FormFieldRow(
          label: 'BaseURL（可选，默认官方端点）',
          child: Container(
            height: 34,
            padding: const EdgeInsets.symmetric(horizontal: 10),
            decoration: BoxDecoration(
              color: s.bgSource,
              borderRadius: BorderRadius.circular(LfDimens.rInput),
              border: Border.all(color: s.dividerStrong),
            ),
            alignment: Alignment.centerLeft,
            child: Text('https://api.openai.com/v1', style: TextStyle(fontSize: LfDimens.fsSm, color: s.text3)),
          ),
        ),
        _actions([
          LfButton(label: '上一步', onPressed: () => setStateAt(0)),
          LfButton(label: '跳过，先用本地模型试用', onPressed: () => setStateAt(2)),
          LfButton(label: '下一步', kind: LfButtonKind.primary, onPressed: () => setStateAt(2)),
        ]),
      ],
    );
  }

  // --- 态 2 · 设热键 ---
  Widget _stepHotkeys() {
    final s = LfScheme.of(context);
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
          child: const Column(children: [
            HotkeyRow(item: HotkeyItem(id: 'hold', label: '按住说话', mac: '按住 Fn', win: 'Win+H')),
            HotkeyRow(item: HotkeyItem(id: 'invoke', label: '唤起悬浮窗', mac: '⌥ Space', win: '⌥ Space')),
          ]),
        ),
        _actions([
          LfButton(label: '上一步', onPressed: () => setStateAt(1)),
          LfButton(label: '下一步', kind: LfButtonKind.primary, onPressed: () => setStateAt(3)),
        ]),
      ],
    );
  }

  // --- 态 3 · 权限引导 ---
  Widget _stepPerms() {
    final s = LfScheme.of(context);
    Widget permCard(String iconName, String name, String desc) {
      return Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: s.bgSource,
          borderRadius: BorderRadius.circular(LfDimens.rCard),
          border: Border.all(color: s.divider),
        ),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(color: s.brandSoft, borderRadius: BorderRadius.circular(9)),
              child: Center(child: LfIcons.icon(iconName, size: 17, color: s.brand)),
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
                      Text('· 待授权', style: TextStyle(fontSize: LfDimens.fs2xs, fontWeight: FontWeight.w600, color: s.warning)),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(desc, style: TextStyle(fontSize: LfDimens.fs2xs, color: s.text2)),
                ],
              ),
            ),
            const SizedBox(width: 8),
            const LfButton(label: '打开设置', padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6)),
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
        permCard('accessibility', '辅助功能', '监听全局热键（Fn / ⌥ 组合）并向其他应用注入文本'),
        const SizedBox(height: 8),
        permCard('mouse', '输入监控', '读取划词选区，实现流程 C / D'),
        _actions([
          LfButton(label: '上一步', onPressed: () => setStateAt(2)),
          LfButton(label: '我已授权，完成', kind: LfButtonKind.primary, onPressed: () => setStateAt(4)),
        ]),
      ],
    );
  }

  // --- 态 4 · 完成 ---
  Widget _stepDone() {
    final s = LfScheme.of(context);
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
        _sub('当前默认：Ollama · qwen2.5:7b（本地 · 离线 · 零成本）。随时可在「模型配置」切换或新增 Provider。'),
        const SizedBox(height: 14),
        const Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          Badge('本地模型', live: true),
          SizedBox(width: 8),
          Badge('零遥测'),
          SizedBox(width: 8),
          Badge('五端同步'),
        ]),
        _actions([
          LfButton(label: '开始使用 · 按住 Fn 说话 →', kind: LfButtonKind.primary, onPressed: () {
            widget.store.onboarded = true;
            setStateAt(4);
          }),
        ]),
      ],
    );
  }
}
