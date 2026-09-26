import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../core/icons/lf_icons.dart';
import '../../core/theme/tokens.dart';

/// 手机框 —— 原型 .phone-frame（iOS 刘海 / Android 打孔，G/M/O 三页共用）。
class PhoneFrame extends StatelessWidget {
  const PhoneFrame({
    super.key,
    required this.child,
    this.android = false,
    this.width = 300,
    this.height = 620,
  });

  final Widget child;
  final bool android;
  final double width;
  final double height;

  @override
  Widget build(BuildContext context) {
    final s = LfScheme.of(context);
    return Container(
      width: width,
      height: height,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(34),
        border: Border.all(color: s.dividerStrong, width: 5),
        boxShadow: s.shadowWindow,
      ),
      child: Stack(
        children: [
          child,
          if (android)
            const Positioned(
              top: 8,
              left: 0,
              right: 0,
              child: Center(
                child: SizedBox(
                  width: 10,
                  height: 10,
                  child: DecoratedBox(
                    decoration: BoxDecoration(color: Colors.black87, shape: BoxShape.circle),
                  ),
                ),
              ),
            )
          else
            Positioned(
              top: 8,
              left: 0,
              right: 0,
              child: Center(
                child: Container(
                  width: 90,
                  height: 22,
                  decoration: BoxDecoration(
                    color: Colors.black87,
                    borderRadius: BorderRadius.circular(LfDimens.rPill),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// iOS 状态栏时间。
class PhoneStatusBar extends StatelessWidget {
  const PhoneStatusBar({super.key, this.time = '9:41', this.androidTime});

  final String time;
  final String? androidTime;

  @override
  Widget build(BuildContext context) {
    final s = LfScheme.of(context);
    return Padding(
      padding: const EdgeInsets.only(top: 12, left: 20, right: 20),
      child: Row(
        children: [
          Text(
            androidTime ?? time,
            style: TextStyle(
              fontSize: LfDimens.fsSm,
              fontWeight: FontWeight.w700,
              color: s.text,
            ),
          ),
          const Spacer(),
          if (androidTime != null) ...[
            LfIcons.icon('smile', size: 11, color: s.text2),
            const SizedBox(width: 6),
          ],
          LfIcons.icon('globe', size: 11, color: s.text2),
        ],
      ),
    );
  }
}

/// iOS 键盘（G 页）—— 工具条 + 候选译文流 + QWERTY。
class IosKeyboard extends StatelessWidget {
  const IosKeyboard({
    super.key,
    required this.state, // 0 展开 / 1 选语种 / 2 输入 / 3 翻译中 / 4 候选
    this.typingText,
    this.candidates = const [],
  });

  final int state;
  final String? typingText;
  final List<String> candidates;

  @override
  Widget build(BuildContext context) {
    final s = LfScheme.of(context);
    return Container(
      color: const Color(0xFFD1D4DA),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // 工具条
          Container(
            height: 36,
            color: const Color(0xFFE4E6EB),
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Row(
              children: [
                _LangChip('中', active: state >= 1),
                const SizedBox(width: 4),
                const _LangChip('EN'),
                const _SwapChip(),
                const SizedBox(width: 4),
                const _LangChip('日'),
                const Spacer(),
                LfIcons.icon('globe', size: 14, color: s.text2),
                const SizedBox(width: 10),
                LfIcons.icon('book', size: 14, color: s.text2),
                const SizedBox(width: 10),
                LfIcons.icon('clock', size: 14, color: s.text2),
              ],
            ),
          ),
          // 状态/候选条
          if (state == 2 && typingText != null)
            _KbBanner(
              rich: [
                const TextSpan(text: '正在输入：'),
                TextSpan(
                  text: typingText,
                  style: TextStyle(color: s.text, fontWeight: FontWeight.w700),
                ),
              ],
            )
          else if (state == 3)
            const _KbBanner(text: '翻译中…', warn: true)
          else if (state == 4)
            const _KbBanner(text: '✓ 候选就绪', ok: true),
          if (state >= 4 && candidates.isNotEmpty)
            Container(
              height: 40,
              color: const Color(0xFFECEDEF),
              padding: const EdgeInsets.symmetric(horizontal: 6),
              child: Row(
                children: [
                  Container(
                    width: 26,
                    height: 26,
                    decoration: BoxDecoration(gradient: s.brandGrad, shape: BoxShape.circle),
                    child: const Center(
                      child: Text('译', style: TextStyle(fontSize: 11, fontWeight: w7, color: Colors.white)),
                    ),
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Row(
                      children: [
                        for (var i = 0; i < candidates.length && i < 2; i++) ...[
                          Flexible(
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                              decoration: BoxDecoration(
                                color: i == 0 ? s.brand : const Color(0xFFE4E6EB),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                candidates[i],
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: LfDimens.fsXs,
                                  fontWeight: i == 0 ? FontWeight.w700 : FontWeight.w400,
                                  color: i == 0 ? Colors.white : s.text,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 6),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),
          // 键区
          const KbBody(),
        ],
      ),
    );
  }

  static const FontWeight w7 = FontWeight.w700;
}

class _LangChip extends StatelessWidget {
  const _LangChip(this.label, {this.active = false});

  final String label;
  final bool active;

  @override
  Widget build(BuildContext context) {
    final s = LfScheme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: active ? s.brandSoft2 : Colors.white,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: active ? s.brand.withValues(alpha: 0.5) : const Color(0xFFC8CBD1)),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: LfDimens.fsXs,
          fontWeight: FontWeight.w700,
          color: active ? s.brand : s.text,
        ),
      ),
    );
  }
}

class _SwapChip extends StatelessWidget {
  const _SwapChip();

  @override
  Widget build(BuildContext context) {
    final s = LfScheme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 5),
      child: LfIcons.icon('swap', size: 13, color: s.text2),
    );
  }
}

class _KbBanner extends StatelessWidget {
  const _KbBanner({this.text, this.rich, this.warn = false, this.ok = false});

  final String? text;
  final List<InlineSpan>? rich;
  final bool warn;
  final bool ok;

  @override
  Widget build(BuildContext context) {
    final s = LfScheme.of(context);
    final Color c = warn ? s.warning : (ok ? s.success : s.text2);
    return Container(
      height: 28,
      padding: const EdgeInsets.symmetric(horizontal: 10),
      color: const Color(0xFFECEDEF),
      alignment: Alignment.centerLeft,
      child: rich != null
          ? RichText(
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              text: TextSpan(
                style: TextStyle(fontSize: LfDimens.fsXs, color: c, fontFamily: 'PingFang SC'),
                children: rich,
              ),
            )
          : Text(text ?? '', style: TextStyle(fontSize: LfDimens.fsXs, color: c, fontWeight: FontWeight.w600)),
    );
  }
}

/// QWERTY 键区（iOS 风格）。
class KbBody extends StatelessWidget {
  const KbBody({super.key});

  static const _rows = [
    ['q', 'w', 'e', 'r', 't', 'y', 'u', 'i', 'o', 'p'],
    ['a', 's', 'd', 'f', 'g', 'h', 'j', 'k', 'l'],
    ['z', 'x', 'c', 'v', 'b', 'n', 'm'],
  ];

  @override
  Widget build(BuildContext context) {
    final s = LfScheme.of(context);
    Widget key(String label, {double flex = 1, Color? bg, String? fontFamily}) => Expanded(
          flex: flex ~/ 1,
          child: Container(
            margin: const EdgeInsets.all(2.5),
            decoration: BoxDecoration(
              color: bg ?? Colors.white,
              borderRadius: BorderRadius.circular(5),
              boxShadow: const [BoxShadow(color: Color(0x33000000), offset: Offset(0, 1))],
            ),
            alignment: Alignment.center,
            child: Text(
              label,
              style: TextStyle(
                fontSize: LfDimens.fsBase,
                color: s.text,
                fontFamily: fontFamily ?? 'PingFang SC',
              ),
            ),
          ),
        );

    return Padding(
      padding: const EdgeInsets.fromLTRB(3, 6, 3, 0),
      child: Column(
        children: [
          for (var r = 0; r < _rows.length; r++)
            Row(
              children: [
                if (r == 2) key('⇧', flex: 15, bg: const Color(0xFFABAEB5)),
                ..._rows[r].map((k) => key(k, flex: r == 1 ? 11 : 10)),
                if (r == 2) key('⌫', flex: 15, bg: const Color(0xFFABAEB5)),
              ],
            ),
          Row(
            children: [
              key('123', flex: 20, bg: const Color(0xFFABAEB5)),
              key('space', flex: 60),
              key('发送', flex: 20, bg: const Color(0xFFABAEB5)),
            ],
          ),
          const SizedBox(height: 4),
        ],
      ),
    );
  }
}

// ==================================================================
// Android Gboard（O 页）+ Material 3 组件
// ==================================================================
class Gboard extends StatelessWidget {
  const Gboard({
    super.key,
    required this.state, // 0 键盘 / 1 语音 / 2 成稿候选
    this.draftChip,
    this.micOn = false,
  });

  final int state;
  final String? draftChip;
  final bool micOn;

  @override
  Widget build(BuildContext context) {
    final s = LfScheme.of(context);
    const surface = Color(0xFFE8EAF0);

    return Container(
      color: surface,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // 工具条：G 标识 + chips + 语音钮
          Container(
            height: 40,
            padding: const EdgeInsets.symmetric(horizontal: 10),
            child: Row(
              children: [
                Container(
                  width: 20,
                  height: 20,
                  decoration: BoxDecoration(
                    gradient: s.brandGrad,
                    shape: BoxShape.circle,
                  ),
                  child: const Center(
                    child: Text('G', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: Colors.white)),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Row(
                    children: [
                      if (state < 2) ...[
                        const _GbChip('在吗'),
                        const SizedBox(width: 6),
                        const _GbChip('好的'),
                      ],
                      const SizedBox(width: 6),
                      Flexible(
                        child: _GbChip(
                          state >= 2 ? (draftChip != null && draftChip!.length > 9 ? '${draftChip!.substring(0, 9)}…' : draftChip ?? '收到') : '收到',
                          brand: true,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  width: 30,
                  height: 30,
                  decoration: BoxDecoration(
                    color: micOn ? s.brand : Colors.transparent,
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: LfIcons.icon('mic', size: 15, color: micOn ? Colors.white : s.text2),
                  ),
                ),
              ],
            ),
          ),
          // 成稿候选（M3 chip 双选）
          if (state == 2 && draftChip != null)
            Container(
              padding: const EdgeInsets.fromLTRB(10, 2, 10, 6),
              child: Row(
                children: [
                  Text(
                    '译语成稿',
                    style: TextStyle(fontSize: LfDimens.fs2xs, fontWeight: FontWeight.w700, color: s.brand),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                      decoration: BoxDecoration(
                        color: s.brand,
                        borderRadius: BorderRadius.circular(LfDimens.rPill),
                      ),
                      child: Text(
                        draftChip!,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontSize: LfDimens.fsXs, color: Colors.white, fontWeight: FontWeight.w600),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          // 语音全屏区 / 键区
          if (state == 1)
            _GbVoice(original: draftChip ?? '')
          else ...[
            Padding(
              padding: const EdgeInsets.fromLTRB(4, 0, 4, 0),
              child: Column(
                children: [
                  for (final row in const [
                    ['q', 'w', 'e', 'r', 't', 'y', 'u', 'i', 'o', 'p'],
                    ['a', 's', 'd', 'f', 'g', 'h', 'j', 'k', 'l'],
                    ['z', 'x', 'c', 'v', 'b', 'n', 'm'],
                  ])
                    Row(
                      children: [
                        for (final k in row)
                          Expanded(
                            child: Container(
                              height: 40,
                              margin: const EdgeInsets.all(2),
                              alignment: Alignment.center,
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(k, style: TextStyle(fontSize: LfDimens.fsBase, color: s.text)),
                            ),
                          ),
                      ],
                    ),
                  Row(
                    children: [
                      const _GbFnKey('?123', flex: 15),
                      const _GbFnKey(',', flex: 10),
                      Expanded(
                        flex: 50,
                        child: Container(
                          height: 40,
                          margin: const EdgeInsets.all(2),
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text('中文', style: TextStyle(fontSize: LfDimens.fsSm, color: s.text)),
                        ),
                      ),
                      const _GbFnKey('.', flex: 10),
                      Expanded(
                        flex: 15,
                        child: Container(
                          height: 40,
                          margin: const EdgeInsets.all(2),
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: s.brand,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: const Text('发送', style: TextStyle(fontSize: LfDimens.fsSm, color: Colors.white)),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
          // 手势导航条
          Container(
            height: 18,
            alignment: Alignment.center,
            child: Container(
              width: 90,
              height: 4,
              decoration: BoxDecoration(
                color: s.text3.withValues(alpha: 0.6),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _GbChip extends StatelessWidget {
  const _GbChip(this.label, {this.brand = false});

  final String label;
  final bool brand;

  @override
  Widget build(BuildContext context) {
    final s = LfScheme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
      decoration: BoxDecoration(
        color: brand ? s.brandSoft2 : Colors.white,
        borderRadius: BorderRadius.circular(LfDimens.rPill),
      ),
      child: Text(
        label,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          fontSize: LfDimens.fsXs,
          fontWeight: brand ? FontWeight.w700 : FontWeight.w400,
          color: brand ? s.brand : s.text2,
        ),
      ),
    );
  }
}

class _GbFnKey extends StatelessWidget {
  const _GbFnKey(this.label, {required this.flex});

  final String label;
  final int flex;

  @override
  Widget build(BuildContext context) {
    final s = LfScheme.of(context);
    return Expanded(
      flex: flex,
      child: Container(
        height: 40,
        margin: const EdgeInsets.all(2),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: const Color(0xFFD5D9E2),
          borderRadius: BorderRadius.circular(6),
        ),
        child: Text(label, style: TextStyle(fontSize: LfDimens.fsSm, color: s.text2)),
      ),
    );
  }
}

class _GbVoice extends StatelessWidget {
  const _GbVoice({required this.original});

  final String original;

  @override
  Widget build(BuildContext context) {
    final s = LfScheme.of(context);
    return Container(
      height: 190,
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(gradient: s.brandGrad, shape: BoxShape.circle),
            child: const Center(child: Icon(Icons.mic_rounded, size: 24, color: Colors.white)),
          ),
          const SizedBox(height: 12),
          const _VoiceWave(),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                '正在聆听：',
                style: TextStyle(fontSize: LfDimens.fsSm, color: s.text2),
              ),
              Text(
                original,
                style: TextStyle(fontSize: LfDimens.fsSm, fontWeight: FontWeight.w700, color: s.text),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            '松手成稿 · 译语本地引擎 · 0 ¥',
            style: TextStyle(fontSize: LfDimens.fs2xs, color: s.text3),
          ),
        ],
      ),
    );
  }
}

/// 语音波形（14 根）。
class _VoiceWave extends StatelessWidget {
  const _VoiceWave();

  @override
  Widget build(BuildContext context) {
    final s = LfScheme.of(context);
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(14, (i) {
        final h = 6 + 16 * (0.5 + 0.5 * math.sin(i * 0.85));
        return Container(
          width: 3,
          height: h,
          margin: const EdgeInsets.symmetric(horizontal: 2),
          decoration: BoxDecoration(
            color: s.brand.withValues(alpha: 0.8),
            borderRadius: BorderRadius.circular(2),
          ),
        );
      }),
    );
  }
}

// ==================================================================
// Material 3 组件（Android App 主页 O 态4 + Snackbar）
// ==================================================================
class M3Snackbar extends StatelessWidget {
  const M3Snackbar({super.key, required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    final s = LfScheme.of(context);
    return Container(
      margin: const EdgeInsets.all(12),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFF32343D),
        borderRadius: BorderRadius.circular(10),
        boxShadow: s.shadowMd,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          LfIcons.icon('check', size: 13, color: s.success),
          const SizedBox(width: 8),
          Flexible(
            child: Text(
              message,
              style: const TextStyle(fontSize: LfDimens.fsSm, color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }
}
