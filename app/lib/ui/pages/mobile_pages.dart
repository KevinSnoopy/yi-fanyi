
import 'package:flutter/material.dart';

import '../../core/icons/lf_icons.dart';
import '../../core/theme/tokens.dart';
import '../components/common.dart';
import '../components/phone_frames.dart';
import '../overlays/floating_windows.dart';
import 'flow_demos.dart';
import 'flow_page.dart' show HostTitleBar;

// ==================================================================
// G 页 · 移动端键盘 —— PRD §5（原型 Tab G 五态，B.5 验收项）
// iOS 系统键盘扩展：工具栏语种瞬切 + 输入 → 翻译 → 候选词插入
// ==================================================================
class IosKbDemoPage extends FlowDemoPage {
  const IosKbDemoPage({super.key, required super.store});

  @override
  int get stateCount => 5;

  @override
  String get hostTitle => 'iOS · 微信聊天';

  @override
  State<FlowDemoPage> createState() => _IosKbDemoPageState();
}

class _IosKbDemoPageState extends State<IosKbDemoPage> with FlowDemoStateMixin {
  static const original = '下周三能签吗？';
  static const candidates = [
    'Can we sign it by next Wednesday?',
    'Can we sign by next Wed?',
    'Shall we sign by next Wed?',
  ];

  @override
  List<String> get stateLabels => const ['键盘展开', '选语种', '输入', '翻译中', '候选词'];

  @override
  void initState() {
    super.initState();
    replay();
  }

  @override
  void replay() {
    setStateAt(0);
    schedule(() => setStateAt(1), const Duration(milliseconds: 1500));
    schedule(() => setStateAt(2), const Duration(milliseconds: 3000));
    schedule(() => setStateAt(3), const Duration(milliseconds: 4500));
    schedule(() => setStateAt(4), const Duration(milliseconds: 6000));
  }

  @override
  Widget build(BuildContext context) {
    final s = LfScheme.of(context);
    return Stack(
      children: [
        Column(
          children: [
            HostTitleBar(title: widget.hostTitle),
            Expanded(child: Container(color: s.bgSource, alignment: Alignment.center)),
          ],
        ),
        Positioned(
          left: 0,
          right: 0,
          top: 46,
          bottom: 8,
          child: Center(
            child: PhoneFrame(
              child: Column(
                children: [
                  const PhoneStatusBar(time: '9:41'),
                  const Expanded(child: WechatThread(name: '给 Daniel', incoming: 'Great, let\'s set up a call.')),
                  _IosInputRow(text: stateIdx >= 2 ? original : null),
                  IosKeyboard(
                    state: stateIdx,
                    typingText: switch (stateIdx) {
                      2 => original,
                      3 => null,
                      4 => null,
                      _ => null,
                    },
                    candidates: stateIdx >= 4 ? candidates : const [],
                  ),
                ],
              ),
            ),
          ),
        ),
        Positioned(top: 44, right: 16, child: demoControls()),
      ],
    );
  }
}

/// 微信气泡区（G 用白绿混排、O 用灰绿混排）。
class WechatThread extends StatelessWidget {
  const WechatThread({super.key, required this.name, required this.incoming});

  final String name;
  final String incoming;

  @override
  Widget build(BuildContext context) {
    const green = Color(0xFF95EC69);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
      decoration: const BoxDecoration(
        gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Colors.white, Color(0xFFF5F5F5)]),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text('微信 · $name', style: TextStyle(fontSize: LfDimens.fs2xs, color: Colors.grey.shade500)),
          const SizedBox(height: 10),
          const Align(
            alignment: Alignment.centerRight,
            child: _WxBubble(text: '如果价格合适，我们愿意直接推进。', color: green),
          ),
          const SizedBox(height: 8),
          Align(
            alignment: Alignment.centerLeft,
            child: _WxBubble(text: incoming, color: Colors.white, border: true),
          ),
        ],
      ),
    );
  }
}

class _WxBubble extends StatelessWidget {
  const _WxBubble({required this.text, required this.color, this.border = false});

  final String text;
  final Color color;
  final bool border;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(maxWidth: 220),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(8),
        border: border ? Border.all(color: const Color(0xFFEEEEEE)) : null,
      ),
      child: Text(text, style: const TextStyle(fontSize: 13, color: Colors.black, height: 1.4)),
    );
  }
}

/// phone-input-row —— 麦克风 + 输入框 + 表情。
class _IosInputRow extends StatelessWidget {
  const _IosInputRow({this.text});

  final String? text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFFF7F7F7),
        border: Border(top: BorderSide(color: Colors.grey.shade300)),
      ),
      child: Row(
        children: [
          Container(
            width: 30,
            height: 30,
            decoration: BoxDecoration(color: Colors.white, shape: BoxShape.circle, border: Border.all(color: Colors.grey.shade300)),
            child: Center(child: LfIcons.icon('mic', size: 15, color: Colors.black54)),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Container(
              height: 32,
              padding: const EdgeInsets.symmetric(horizontal: 10),
              alignment: Alignment.centerLeft,
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(6), border: Border.all(color: Colors.grey.shade300)),
              child: Text(
                text ?? '',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 13, color: Colors.black),
              ),
            ),
          ),
          const SizedBox(width: 8),
          LfIcons.icon('smile', size: 20, color: Colors.black54),
        ],
      ),
    );
  }
}

// ==================================================================
// M 页 · 移动 App 主页 + 隐私锁 —— PRD §6 #11（原型 Tab M 三态，B.4）
// App 主页 → FaceID 锁定覆盖 → 解锁成功 banner
// ==================================================================
class IosAppDemoPage extends FlowDemoPage {
  const IosAppDemoPage({super.key, required super.store});

  @override
  int get stateCount => 3;

  @override
  String get hostTitle => 'iOS · 译语 App';

  @override
  State<FlowDemoPage> createState() => _IosAppDemoPageState();
}

class _IosAppDemoPageState extends State<IosAppDemoPage> with FlowDemoStateMixin {
  @override
  List<String> get stateLabels => const ['App 主页', '隐私锁 · FaceID', '解锁成功'];

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
            Expanded(child: Container(color: s.bgSource, alignment: Alignment.center)),
          ],
        ),
        Positioned(
          left: 0,
          right: 0,
          top: 46,
          bottom: 8,
          child: Center(
            child: Stack(
              children: [
                const PhoneFrame(
                  child: Column(
                    children: [
                      PhoneStatusBar(time: '9:41'),
                      Expanded(child: _IosAppHome()),
                    ],
                  ),
                ),
                // 态 1 · 锁定覆盖
                if (stateIdx == 1)
                  Positioned.fill(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(29),
                      child: const LockScreen(compact: true),
                    ),
                  ),
                // 态 2 · 解锁成功 banner
                if (stateIdx == 2)
                  const Positioned(
                    top: 64,
                    left: 0,
                    right: 0,
                    child: Center(
                      child: _UnlockDoneBanner(),
                    ),
                  ),
              ],
            ),
          ),
        ),
        Positioned(top: 44, right: 16, child: demoControls()),
      ],
    );
  }
}

/// iOS App 主页（原型 pa-*：hero + 配置卡 + 键盘卡 + 隐私卡）。
class _IosAppHome extends StatelessWidget {
  const _IosAppHome();

  @override
  Widget build(BuildContext context) {
    final s = LfScheme.of(context);
    Widget paRow(String iconName, String name, String meta, {Widget? trailing}) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
        child: Row(
          children: [
            Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(color: s.brandSoft, borderRadius: BorderRadius.circular(6)),
              child: Center(child: LfIcons.icon(iconName, size: 12, color: s.brand)),
            ),
            const SizedBox(width: 8),
            Text(name, style: TextStyle(fontSize: LfDimens.fsSm, color: s.text)),
            const Spacer(),
            Text(meta, style: TextStyle(fontSize: LfDimens.fs2xs, color: s.text3)),
            if (trailing != null) ...[
              const SizedBox(width: 8),
              trailing,
            ] else ...[
              const SizedBox(width: 4),
              Text('›', style: TextStyle(fontSize: LfDimens.fsMd, color: s.text3)),
            ],
          ],
        ),
      );
    }

    Widget paCard(String title, List<Widget> rows) {
      return Container(
        margin: const EdgeInsets.only(bottom: 10),
        decoration: BoxDecoration(
          color: s.bgWindow,
          borderRadius: BorderRadius.circular(LfDimens.rCard),
          border: Border.all(color: s.divider),
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 9, 12, 3),
              child: Text(title, style: TextStyle(fontSize: LfDimens.fs2xs, fontWeight: FontWeight.w700, color: s.text3)),
            ),
            ...rows,
          ],
        ),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // hero
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(gradient: s.brandGrad, borderRadius: BorderRadius.circular(11)),
                  child: const Center(child: Text('译', style: TextStyle(color: Colors.white, fontSize: 17, fontWeight: FontWeight.w700))),
                ),
                const SizedBox(width: 10),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('译语', style: TextStyle(fontSize: LfDimens.fsMd, fontWeight: FontWeight.w700, color: s.text)),
                    Text('BYOK · 零采集 · 五端同步', style: TextStyle(fontSize: LfDimens.fs2xs, color: s.text3)),
                  ],
                ),
              ],
            ),
          ),
          paCard('当前配置', [
            paRow('chip', '默认模型', 'Ollama · qwen2.5:7b'),
            paRow('globe', '语言方向', '中文 → English'),
          ]),
          paCard('键盘', [
            paRow('keyboard', '引导开启译语键盘', '未启用'),
            paRow('book', '键盘术语表', '通用 · 8 条'),
          ]),
          paCard('隐私与安全', [
            paRow(
              'shield',
              '隐私锁',
              'FaceID',
              trailing: LfSwitch(value: true, onChanged: (_) {}),
            ),
            paRow('ban', '零遥测', '始终开启，不可关闭'),
          ]),
        ],
      ),
    );
  }
}

/// 解锁成功小 banner（M 态 2）。
class _UnlockDoneBanner extends StatelessWidget {
  const _UnlockDoneBanner();

  @override
  Widget build(BuildContext context) {
    final s = LfScheme.of(context);
    return RiseIn(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
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
              width: 22,
              height: 22,
              decoration: BoxDecoration(color: s.success.withValues(alpha: 0.14), shape: BoxShape.circle),
              child: Center(child: LfIcons.icon('check', size: 12, color: s.success)),
            ),
            const SizedBox(width: 8),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('FaceID 验证通过', style: TextStyle(fontSize: LfDimens.fsSm, fontWeight: FontWeight.w600, color: s.text)),
                Text('0.3s · 无遥测', style: TextStyle(fontSize: LfDimens.fs2xs, color: s.text2)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
