import 'package:flutter/material.dart';

import '../../core/theme/tokens.dart';
import '../../models/models.dart';
import '../../services/app_store.dart';
import '../components/cards.dart';
import '../components/common.dart';

/// K 页 · 翻译偏好 / 术语表 / Skills —— PRD §6 #9（原型 Tab K 三子页）。
/// 子页状态机：0 翻译偏好 / 1 术语表 / 2 Skills。
class PrefsPage extends StatefulWidget {
  const PrefsPage({super.key, required this.store});

  final AppStore store;

  @override
  State<PrefsPage> createState() => _PrefsPageState();
}

class _PrefsPageState extends State<PrefsPage> {
  int sub = 0; // 三子页
  String termTab = '通用';

  static const List<String> termTabNames = ['通用', '跨境电商', '法律合同', '技术文档'];

  @override
  Widget build(BuildContext context) {
    final s = LfScheme.of(context);
    return ListenableBuilder(
      listenable: widget.store,
      builder: (context, _) {
        return SingleChildScrollView(
          padding: const EdgeInsets.all(22),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const PageTitle(title: '翻译偏好 / 术语表 / Skills'),
              const SizedBox(height: 12),
              _Subnav(active: sub, onChange: (i) => setState(() => sub = i)),
              const SizedBox(height: 18),
              AnimatedSwitcher(
                duration: LfDimens.tBase,
                switchInCurve: LfDimens.ease,
                child: KeyedSubtree(
                  key: ValueKey(sub),
                  child: switch (sub) {
                    1 => _buildTerms(s),
                    2 => _buildSkills(s),
                    _ => _buildPrefs(s),
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // ---------------- 子页 0 · 翻译偏好 ----------------
  Widget _buildPrefs(LfScheme s) {
    final store = widget.store;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SectionTitle('默认语言方向'),
        Row(
          children: [
            _LangBtn(label: store.sourceLang, active: true),
            const SizedBox(width: 6),
            _SwapBtn(onTap: () {
              setState(() {
                final t = store.sourceLang;
                store.sourceLang = store.targetLang;
                store.targetLang = t;
              });
            }),
            const SizedBox(width: 6),
            _LangBtn(label: store.targetLang, active: false),
            const SizedBox(width: 10),
            Text('悬浮窗 / 键盘内可临时互换', style: TextStyle(fontSize: LfDimens.fsXs, color: s.text3)),
          ],
        ),
        const SectionTitle('翻译风格（P1）'),
        Row(
          children: [
            for (final (i, e) in const [
              ('直译', '忠实原文结构'),
              ('意译', '地道自然表达'),
              ('商务', '正式书面语气'),
              ('口语', '轻松聊天风格'),
            ].indexed) ...[
              if (i > 0) const SizedBox(width: 8),
              Expanded(
                child: _RadioCard(
                  name: e.$1,
                  desc: e.$2,
                  selected: store.translateStyle == e.$1,
                  onTap: () => setState(() => store.translateStyle = e.$1),
                ),
              ),
            ],
          ],
        ),
        const SectionTitle('行为'),
        SettingRow(
          title: '语言自动检测',
          desc: '源语言不确定时自动识别，检测失败回退默认方向',
          trailing: LfSwitch(
            value: store.autoDetectLang,
            onChanged: (v) => setState(() => store.autoDetectLang = v),
          ),
        ),
        SettingRow(
          title: '预览窗口（后悔窗口）',
          desc: '1.2 秒后自动写入 / 总是预览 / 直接写入',
          trailing: _SelectBox(
            value: store.previewMode,
            options: const ['1.2 秒后自动写入', '总是预览', '直接写入'],
            onChange: (v) => setState(() => store.previewMode = v),
          ),
        ),
        SettingRow(
          title: '双语写回',
          desc: '写入译文时可选择附带原文（P0：流式渲染 + 双语写回）',
          trailing: LfSwitch(
            value: store.bilingualWriteBack,
            onChanged: (v) => setState(() => store.bilingualWriteBack = v),
          ),
        ),
      ],
    );
  }

  // ---------------- 子页 1 · 术语表 ----------------
  Widget _buildTerms(LfScheme s) {
    final store = widget.store;
    final terms = store.termsOf(termTab);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '注入到 prompt，防止专名错译（P0）；支持按场景分表、CSV 导入与分享。',
          style: TextStyle(fontSize: LfDimens.fsSm, color: s.text2),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 6,
          runSpacing: 6,
          children: [
            for (final n in termTabNames)
              _TermTab(
                label: '$n · ${store.termsOf(n).length}',
                active: n == termTab,
                onTap: () => setState(() => termTab = n),
              ),
          ],
        ),
        const SizedBox(height: 12),
        Container(
          decoration: BoxDecoration(
            color: s.bgWindow,
            borderRadius: BorderRadius.circular(LfDimens.rCard),
            border: Border.all(color: s.divider),
          ),
          clipBehavior: Clip.antiAlias,
          child: Column(
            children: [
              for (final t in terms.take(8)) TermRow(entry: t),
              if (terms.isEmpty)
                Padding(
                  padding: const EdgeInsets.all(22),
                  child: Text('本分表暂无词条 · 点「添加词条」开始', style: TextStyle(fontSize: LfDimens.fsSm, color: s.text3)),
                ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            LfButton(
              label: ' 添加词条',
              icon: 'plus',
              kind: LfButtonKind.primary,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              onPressed: () => _addTermDialog(store),
            ),
            const SizedBox(width: 8),
            const LfButton(label: ' CSV 导入', icon: 'download'),
            const SizedBox(width: 8),
            const LfButton(label: '应用范围：全部场景 ▾'),
          ],
        ),
      ],
    );
  }

  void _addTermDialog(AppStore store) {
    final src = TextEditingController();
    final tgt = TextEditingController();
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: LfScheme.of(ctx).bgWindow,
        surfaceTintColor: Colors.transparent,
        title: const Text('添加词条', style: TextStyle(fontSize: LfDimens.fsMd)),
        content: SizedBox(
          width: 360,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(controller: src, decoration: const InputDecoration(hintText: '原文（如：报价）')),
              const SizedBox(height: 10),
              TextField(controller: tgt, decoration: const InputDecoration(hintText: '译文（如：quote）')),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('取消')),
          FilledButton(
            onPressed: () {
              if (src.text.trim().isNotEmpty && tgt.text.trim().isNotEmpty) {
                store.addTerm(
                  termTab,
                  TermEntry(source: src.text.trim(), target: tgt.text.trim(), flag: 'both'),
                );
              }
              Navigator.pop(ctx);
            },
            child: const Text('添加'),
          ),
        ],
      ),
    );
  }

  // ---------------- 子页 2 · Skills ----------------
  Widget _buildSkills(LfScheme s) {
    final store = widget.store;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Skill 场景模板（P1）：对齐 Chatterfly 六场景，把「成稿风格 + 术语表 + 目标格式」打包，可自定义分享。',
          style: TextStyle(fontSize: LfDimens.fsSm, color: s.text2),
        ),
        const SizedBox(height: 14),
        LayoutBuilder(
          builder: (context, box) {
            const gap = 10.0;
            final cols = (box.maxWidth / 190).floor().clamp(2, 4);
            final cw = (box.maxWidth - gap * (cols - 1)) / cols;
            return Wrap(
              spacing: gap,
              runSpacing: gap,
              children: [
                for (final sk in store.skills)
                  SizedBox(
                    width: cw,
                    height: 150,
                    child: SkillCard(skill: sk, onTap: () {}),
                  ),
                SizedBox(
                  width: box.maxWidth,
                  height: 78,
                  child: SkillCard(
                    skill: const Skill(id: 'new', name: '新建 Skill', desc: '', icon: 'plus', meta: '选择风格 / 术语表 / 输出格式', custom: true),
                    custom: true,
                    onTap: () {},
                  ),
                ),
              ],
            );
          },
        ),
        const SizedBox(height: 10),
        Text(
          'Skill 分享格式为 JSON（含术语表引用），可导入导出；不上传任何内容（ADR-001）。',
          style: TextStyle(fontSize: LfDimens.fsXs, color: s.text3),
        ),
      ],
    );
  }
}

// ---------------- 小组件 ----------------

class _Subnav extends StatelessWidget {
  const _Subnav({required this.active, required this.onChange});

  final int active;
  final void Function(int) onChange;

  @override
  Widget build(BuildContext context) {
    final s = LfScheme.of(context);
    return Container(
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: s.bgSource,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: s.divider),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (final (i, label) in ['翻译偏好', '术语表', 'Skills'].indexed) ...[
            if (i > 0) const SizedBox(width: 2),
            InkWell(
              onTap: () => onChange(i),
              borderRadius: BorderRadius.circular(6),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                decoration: BoxDecoration(
                  color: i == active ? s.bgWindow : Colors.transparent,
                  borderRadius: BorderRadius.circular(6),
                  boxShadow: i == active ? s.shadowXs : null,
                ),
                child: Text(
                  label,
                  style: TextStyle(
                    fontSize: LfDimens.fsSm,
                    fontWeight: i == active ? FontWeight.w600 : FontWeight.w400,
                    color: i == active ? s.text : s.text2,
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _LangBtn extends StatelessWidget {
  const _LangBtn({required this.label, required this.active});

  final String label;
  final bool active;

  @override
  Widget build(BuildContext context) {
    final s = LfScheme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
      decoration: BoxDecoration(
        color: active ? s.brandSoft : s.bgWindow,
        borderRadius: BorderRadius.circular(LfDimens.rBtn),
        border: Border.all(color: active ? s.brand : s.dividerStrong),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: LfDimens.fsSm,
          fontWeight: FontWeight.w600,
          color: active ? s.brand : s.text,
        ),
      ),
    );
  }
}

class _SwapBtn extends StatelessWidget {
  const _SwapBtn({this.onTap});

  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final s = LfScheme.of(context);
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(LfDimens.rBtn),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
        decoration: BoxDecoration(
          color: s.bgWindow,
          borderRadius: BorderRadius.circular(LfDimens.rBtn),
          border: Border.all(color: s.dividerStrong),
        ),
        child: Text('⇄', style: TextStyle(fontSize: LfDimens.fsSm, color: s.text2)),
      ),
    );
  }
}

/// radio-card —— 原型 .radio-card（选中品牌描边）。
class _RadioCard extends StatelessWidget {
  const _RadioCard({
    required this.name,
    required this.desc,
    required this.selected,
    this.onTap,
  });

  final String name;
  final String desc;
  final bool selected;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final s = LfScheme.of(context);
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(LfDimens.rCard),
      child: AnimatedContainer(
        duration: LfDimens.tFast,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: selected ? s.brandSoft.withValues(alpha: 0.5) : s.bgWindow,
          borderRadius: BorderRadius.circular(LfDimens.rCard),
          border: Border.all(color: selected ? s.brand : s.divider, width: selected ? 1.5 : 1),
        ),
        child: Row(
          children: [
            Container(
              width: 14,
              height: 14,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: selected ? s.brand : Colors.transparent,
                border: Border.all(color: selected ? s.brand : s.dividerStrong, width: 1.5),
              ),
              child: selected
                  ? const Icon(Icons.check, size: 10, color: Colors.white)
                  : null,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(name, style: TextStyle(fontSize: LfDimens.fsSm, fontWeight: FontWeight.w600, color: s.text)),
                  Text(desc, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: LfDimens.fs2xs, color: s.text3)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// select 简化框 —— 原型 .select（下拉用 PopupMenu 呈现）。
class _SelectBox extends StatelessWidget {
  const _SelectBox({required this.value, required this.options, required this.onChange});

  final String value;
  final List<String> options;
  final void Function(String) onChange;

  @override
  Widget build(BuildContext context) {
    final s = LfScheme.of(context);
    return PopupMenuButton<String>(
      initialValue: value,
      onSelected: onChange,
      color: s.bgWindow,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(LfDimens.rPopover),
        side: BorderSide(color: s.divider),
      ),
      itemBuilder: (_) => [
        for (final o in options)
          PopupMenuItem(
            value: o,
            height: 34,
            child: Text(o, style: TextStyle(fontSize: LfDimens.fsSm, color: s.text)),
          ),
      ],
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        decoration: BoxDecoration(
          color: s.bgWindow,
          borderRadius: BorderRadius.circular(LfDimens.rBtn),
          border: Border.all(color: s.dividerStrong),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(value, style: TextStyle(fontSize: LfDimens.fsSm, color: s.text)),
            const SizedBox(width: 6),
            Icon(Icons.expand_more, size: 14, color: s.text3),
          ],
        ),
      ),
    );
  }
}

class _TermTab extends StatelessWidget {
  const _TermTab({required this.label, required this.active, required this.onTap});

  final String label;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final s = LfScheme.of(context);
    return Material(
      color: active ? s.brand : s.bgWindow,
      borderRadius: BorderRadius.circular(LfDimens.rPill),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(LfDimens.rPill),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 6),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(LfDimens.rPill),
            border: Border.all(color: active ? s.brand : s.divider),
          ),
          child: Text(
            label,
            style: TextStyle(
              fontSize: LfDimens.fsSm,
              fontWeight: active ? FontWeight.w600 : FontWeight.w400,
              color: active ? Colors.white : s.text2,
            ),
          ),
        ),
      ),
    );
  }
}
