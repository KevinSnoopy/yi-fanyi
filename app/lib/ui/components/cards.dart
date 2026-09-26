import 'package:flutter/material.dart' hide Badge;

import '../../core/icons/lf_icons.dart';
import '../../core/theme/tokens.dart';
import '../../models/models.dart';
import '../../providers/catalog.dart';
import 'common.dart';

/// 平台卡片网格单元 —— 原型 .plat-card（I 模型配置 / L 首次引导共用）。
class PlatCard extends StatelessWidget {
  const PlatCard({
    super.key,
    required this.item,
    required this.selected,
    this.onTap,
    this.compact = false,
  });

  final PlatformCatalogItem item;
  final bool selected;
  final VoidCallback? onTap;
  final bool compact; // 引导页 3 列紧凑模式

  @override
  Widget build(BuildContext context) {
    final s = LfScheme.of(context);
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(LfDimens.rCard),
      child: AnimatedContainer(
        duration: LfDimens.tFast,
        padding: EdgeInsets.symmetric(vertical: compact ? 12 : 14, horizontal: 8),
        decoration: BoxDecoration(
          color: s.bgWindow,
          borderRadius: BorderRadius.circular(LfDimens.rCard),
          border: Border.all(
            color: selected ? s.brand : s.dividerStrong,
            width: selected ? 1.6 : 1,
          ),
          boxShadow: selected ? s.shadowXs : null,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            LogoBox(item.logo, color: Color(item.color), size: compact ? 28 : 32),
            const SizedBox(height: 7),
            Text(
              item.name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: LfDimens.fsSm,
                fontWeight: FontWeight.w600,
                color: s.text,
              ),
            ),
            if (!compact && item.tag.isNotEmpty) ...[
              const SizedBox(height: 2),
              Text(
                item.tag,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(fontSize: LfDimens.fs2xs, color: s.text3),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// 平台卡片网格。
class PlatGrid extends StatelessWidget {
  const PlatGrid({
    super.key,
    required this.items,
    required this.selectedIndex,
    this.onSelect,
    this.columns = 4,
  });

  final List<PlatformCatalogItem> items;
  final int selectedIndex;
  final ValueChanged<int>? onSelect;
  final int columns;

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: columns,
        mainAxisSpacing: 8,
        crossAxisSpacing: 8,
        childAspectRatio: 1.35,
      ),
      itemCount: items.length,
      itemBuilder: (context, i) => PlatCard(
        item: items[i],
        selected: i == selectedIndex,
        onTap: onSelect == null ? null : () => onSelect!(i),
      ),
    );
  }
}

/// 已配置 Provider 行 —— 原型 .provider-row（logo + 名称/模型延迟 + 健康点）。
class ProviderRow extends StatelessWidget {
  const ProviderRow({
    super.key,
    required this.profile,
    this.logoChar,
    this.logoColor,
    this.onTap,
    this.onDelete,
    this.onSetDefault,
  });

  final ProviderProfile profile;
  final String? logoChar;
  final Color? logoColor;
  final VoidCallback? onTap;
  final VoidCallback? onDelete;
  final VoidCallback? onSetDefault;

  @override
  Widget build(BuildContext context) {
    final s = LfScheme.of(context);
    final item = kPlatformCatalogLookup(profile.platform);
    return Material(
      color: profile.isDefault ? s.brandSoft : Colors.transparent,
      borderRadius: BorderRadius.circular(LfDimens.rCard),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(LfDimens.rCard),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(LfDimens.rCard),
            border: Border.all(
              color: profile.isDefault ? s.brand.withValues(alpha: 0.5) : s.divider,
            ),
          ),
          child: Row(
            children: [
              LogoBox(
                logoChar ?? item?.logo ?? '·',
                color: logoColor ?? Color(item?.color ?? 0xFF86909C),
                size: 30,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            profile.platform + (profile.isDefault ? ' · 默认' : ''),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: LfDimens.fsBase,
                              fontWeight: FontWeight.w600,
                              color: s.text,
                            ),
                          ),
                        ),
                        if (profile.isDefault) ...[
                          const SizedBox(width: 6),
                          const Badge('默认', live: true),
                        ],
                      ],
                    ),
                    const SizedBox(height: 1),
                    Text(
                      '${profile.model} · ${profile.latencyMs == null ? '未测' : '${profile.latencyMs}ms'}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(fontSize: LfDimens.fsXs, color: s.text2),
                    ),
                  ],
                ),
              ),
              if (onDelete != null)
                _IconMiniButton(
                  icon: 'x',
                  tooltip: '删除',
                  onTap: onDelete!,
                ),
              StatusDot(ok: profile.healthy),
            ],
          ),
        ),
      ),
    );
  }
}

/// 迷你图标按钮（行内删除等）。
class _IconMiniButton extends StatelessWidget {
  const _IconMiniButton({required this.icon, required this.tooltip, required this.onTap});

  final String icon;
  final String tooltip;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final s = LfScheme.of(context);
    return Tooltip(
      message: tooltip,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(6),
        child: Padding(
          padding: const EdgeInsets.all(4),
          child: LfIcons.icon(icon, size: 12, color: s.text3),
        ),
      ),
    );
  }
}

/// 统计卡 —— 原型 .stat-card（今日调用 / token / 花费 / 首字延迟）。
class StatCard extends StatelessWidget {
  const StatCard({super.key, required this.value, this.unit, required this.label});

  final String value;
  final String? unit;
  final String label;

  @override
  Widget build(BuildContext context) {
    final s = LfScheme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: s.bgWindow,
        borderRadius: BorderRadius.circular(LfDimens.rCard),
        border: Border.all(color: s.divider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                value,
                style: TextStyle(
                  fontSize: LfDimens.fsXl,
                  fontWeight: FontWeight.w700,
                  color: s.text,
                  height: 1.15,
                ),
              ),
              if (unit != null) ...[
                const SizedBox(width: 3),
                Text(
                  unit!,
                  style: TextStyle(fontSize: LfDimens.fsXs, color: s.text2),
                ),
              ],
            ],
          ),
          const SizedBox(height: 3),
          Text(label, style: TextStyle(fontSize: LfDimens.fsXs, color: s.text2)),
        ],
      ),
    );
  }
}

/// 用量柱状图 —— 原型 .usage-chart（天/周/月切换 + 蓝紫渐变柱）。
class UsageChart extends StatelessWidget {
  const UsageChart({super.key, required this.data});

  /// (label, value) 列表；value 为相对高度 0-100。
  final List<(String, int)> data;

  @override
  Widget build(BuildContext context) {
    final s = LfScheme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: s.bgWindow,
        borderRadius: BorderRadius.circular(LfDimens.rCard),
        border: Border.all(color: s.divider),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          for (final (label, value) in data) ...[
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Text(
                    '$value',
                    style: TextStyle(
                      fontSize: LfDimens.fs2xs,
                      color: s.text3,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Container(
                    height: 64,
                    alignment: Alignment.bottomCenter,
                    child: FractionallySizedBox(
                      heightFactor: (value / 100).clamp(0.08, 1.0),
                      child: Container(
                        width: 22,
                        decoration: BoxDecoration(
                          gradient: s.brandGrad,
                          borderRadius: const BorderRadius.vertical(top: Radius.circular(6)),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    label,
                    style: TextStyle(fontSize: LfDimens.fs2xs, color: s.text2),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// 历史记录行 —— 原型 .history-row（时间/方向徽章/原文→译文/流程 pill/元信息）。
class HistoryRow extends StatelessWidget {
  const HistoryRow({super.key, required this.record, this.onTap});

  final HistoryRecord record;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final s = LfScheme.of(context);
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
          decoration: BoxDecoration(
            border: Border(bottom: BorderSide(color: s.divider)),
          ),
          child: Row(
            children: [
              SizedBox(
                width: 40,
                child: Text(
                  record.time,
                  style: TextStyle(fontSize: LfDimens.fsXs, color: s.text3),
                ),
              ),
              _DirBadge(record.dir),
              const SizedBox(width: 8),
              Expanded(
                child: Row(
                  children: [
                    Flexible(
                      child: Text(
                        record.source,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(fontSize: LfDimens.fsSm, color: s.text),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 5),
                      child: LfIcons.icon('inject', size: 10, color: s.text3),
                    ),
                    Flexible(
                      child: Text(
                        record.target,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(fontSize: LfDimens.fsSm, color: s.text2),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              _FlowPill(record.flow),
              const SizedBox(width: 8),
              Text(
                record.meta,
                style: TextStyle(fontSize: LfDimens.fsXs, color: s.text3),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DirBadge extends StatelessWidget {
  const _DirBadge(this.dir);

  final String dir;

  @override
  Widget build(BuildContext context) {
    final s = LfScheme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
      decoration: BoxDecoration(
        color: s.brandSoft,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        dir,
        style: TextStyle(
          fontSize: LfDimens.fs2xs,
          fontWeight: FontWeight.w600,
          color: s.brand,
        ),
      ),
    );
  }
}

class _FlowPill extends StatelessWidget {
  const _FlowPill(this.flow);

  final String flow;

  @override
  Widget build(BuildContext context) {
    final s = LfScheme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
      decoration: BoxDecoration(
        color: s.bgHover,
        borderRadius: BorderRadius.circular(LfDimens.rPill),
      ),
      child: Text(
        '流程 $flow',
        style: TextStyle(fontSize: LfDimens.fs2xs, color: s.text2),
      ),
    );
  }
}

/// 术语行 —— 原型 .term-row（source → target + 方向 flag）。
class TermRow extends StatelessWidget {
  const TermRow({super.key, required this.entry});

  final TermEntry entry;

  @override
  Widget build(BuildContext context) {
    final s = LfScheme.of(context);
    final Color flagColor = switch (entry.flag) {
      'zh' => s.warning,
      'en' => s.brand,
      _ => s.success,
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: s.divider)),
      ),
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: Text(
              entry.source,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(fontSize: LfDimens.fsSm, fontWeight: FontWeight.w500, color: s.text),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Text('→', style: TextStyle(fontSize: LfDimens.fsSm, color: s.text3)),
          ),
          Expanded(
            flex: 3,
            child: Text(
              entry.target,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(fontSize: LfDimens.fsSm, color: s.text2),
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
            decoration: BoxDecoration(
              color: flagColor.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              entry.flag.toUpperCase(),
              style: TextStyle(
                fontSize: LfDimens.fs2xs,
                fontWeight: FontWeight.w700,
                color: flagColor,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Skill 卡 —— 原型 .skill-card（六场景 + 新建全宽卡）。
class SkillCard extends StatelessWidget {
  const SkillCard({
    super.key,
    required this.skill,
    this.onTap,
    this.custom = false,
  });

  final Skill skill;
  final VoidCallback? onTap;
  final bool custom;

  @override
  Widget build(BuildContext context) {
    final s = LfScheme.of(context);
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(LfDimens.rCard),
      child: Container(
        padding: EdgeInsets.all(custom ? 12 : 14),
        decoration: BoxDecoration(
          color: custom ? s.brandSoft : s.bgWindow,
          borderRadius: BorderRadius.circular(LfDimens.rCard),
          border: Border.all(color: custom ? s.brand.withValues(alpha: 0.4) : s.divider),
        ),
        // custom（新建 Skill）：横向横条布局，高度由内容撑开，避免窄高度下塌陷
        child: custom
            ? Row(
                children: [
                  Container(
                    width: 30,
                    height: 30,
                    decoration: BoxDecoration(
                      color: s.brand.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Center(child: LfIcons.icon(skill.icon, size: 15, color: s.brand)),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          skill.name,
                          style: TextStyle(
                            fontSize: LfDimens.fsBase,
                            fontWeight: FontWeight.w600,
                            color: s.text,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          skill.meta,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(fontSize: LfDimens.fsXs, color: s.text3),
                        ),
                      ],
                    ),
                  ),
                  LfIcons.icon('chev', size: 14, color: s.text3),
                ],
              )
            : Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 34,
                    height: 34,
                    decoration: BoxDecoration(
                      color: s.brandSoft,
                      borderRadius: BorderRadius.circular(9),
                    ),
                    child: Center(child: LfIcons.icon(skill.icon, size: 16, color: s.brand)),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    skill.name,
                    style: TextStyle(
                      fontSize: LfDimens.fsBase,
                      fontWeight: FontWeight.w600,
                      color: s.text,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Expanded(
                    child: Text(
                      skill.desc,
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: LfDimens.fsXs,
                        color: s.text2,
                        height: 1.55,
                      ),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    skill.meta,
                    style: TextStyle(fontSize: LfDimens.fs2xs, color: s.text3),
                  ),
                ],
              ),
      ),
    );
  }
}

/// 热键行 —— 原型 .hotkey-row（label + 键帽 + 状态；冲突红字）。
class HotkeyRow extends StatelessWidget {
  const HotkeyRow({super.key, required this.item, this.onRebind});

  final HotkeyItem item;
  final VoidCallback? onRebind;

  @override
  Widget build(BuildContext context) {
    final s = LfScheme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
      decoration: BoxDecoration(
        color: item.hasConflict ? s.error.withValues(alpha: 0.04) : Colors.transparent,
        border: Border(bottom: BorderSide(color: s.divider)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              item.label,
              style: TextStyle(fontSize: LfDimens.fsSm, color: s.text),
            ),
          ),
          SizedBox(
            width: 108,
            child: Text(
              'Win/Linux: ${item.win}',
              style: TextStyle(fontSize: LfDimens.fs2xs, color: s.text3),
            ),
          ),
          Material(
            color: s.bgHover,
            borderRadius: BorderRadius.circular(6),
            child: InkWell(
              onTap: onRebind,
              borderRadius: BorderRadius.circular(6),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: s.dividerStrong),
                ),
                child: Text(
                  item.mac,
                  style: TextStyle(
                    fontSize: LfDimens.fsSm,
                    fontWeight: FontWeight.w600,
                    color: s.text,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),
          SizedBox(
            width: 118,
            child: Row(
              children: [
                if (!item.hasConflict) ...[
                  LfIcons.icon('check', size: 11, color: s.success),
                  const SizedBox(width: 4),
                  Text('可用', style: TextStyle(fontSize: LfDimens.fsXs, color: s.text2)),
                ] else ...[
                  LfIcons.icon('warn', size: 11, color: s.error),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      '与 ${item.conflictWith} 冲突',
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: LfDimens.fs2xs,
                        color: s.error,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
