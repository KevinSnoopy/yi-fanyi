import 'package:flutter/material.dart';

import '../../core/icons/lf_icons.dart';
import '../../core/theme/tokens.dart';

/// 品牌渐变容器（--brand-grad：135deg 蓝→紫）。
class BrandGradBox extends StatelessWidget {
  const BrandGradBox({super.key, required this.child, this.borderRadius, this.size});

  final Widget child;
  final BorderRadius? borderRadius;
  final Size? size;

  @override
  Widget build(BuildContext context) {
    final s = LfScheme.of(context);
    return Container(
      width: size?.width,
      height: size?.height,
      decoration: BoxDecoration(
        gradient: s.brandGrad,
        borderRadius: borderRadius ?? BorderRadius.circular(LfDimens.rBtn),
      ),
      child: Center(child: child),
    );
  }
}

/// 通用按钮 —— 原型 .settings-btn（primary 蓝底白字 / ghost 白底描边 / full 通栏）。
class LfButton extends StatelessWidget {
  const LfButton({
    super.key,
    required this.label,
    this.onPressed,
    this.kind = LfButtonKind.ghost,
    this.full = false,
    this.icon,
    this.padding,
    this.textColor,
    this.borderColor,
    this.fontWeight,
  });

  final String label;
  final VoidCallback? onPressed;
  final LfButtonKind kind;
  final bool full;
  final String? icon;
  final EdgeInsetsGeometry? padding;
  final Color? textColor;
  final Color? borderColor;
  final FontWeight? fontWeight;

  @override
  Widget build(BuildContext context) {
    final s = LfScheme.of(context);
    final bool isPrimary = kind == LfButtonKind.primary;
    final Color bg = isPrimary ? s.brand : s.bgWindow;
    final Color fg = isPrimary ? Colors.white : (textColor ?? s.text);
    final Color bc = borderColor ?? (isPrimary ? s.brand : s.dividerStrong);

    final Widget child = Row(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (icon != null) ...[
          LfIcons.icon(icon!, size: LfIcons.sm, color: fg),
          const SizedBox(width: 5),
        ],
        Flexible(
          child: Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: LfDimens.fsBase,
              fontWeight: fontWeight ?? FontWeight.w500,
              color: fg,
            ),
          ),
        ),
      ],
    );

    return Material(
      color: bg,
      borderRadius: BorderRadius.circular(LfDimens.rBtn),
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(LfDimens.rBtn),
        child: Container(
          width: full ? double.infinity : null,
          padding: padding ?? const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(LfDimens.rBtn),
            border: Border.all(color: bc),
          ),
          child: child,
        ),
      ),
    );
  }
}

enum LfButtonKind { primary, ghost }

/// 开关 —— 原型 .switch（32×18 track + 14 thumb，品牌色激活）。
class LfSwitch extends StatelessWidget {
  const LfSwitch({super.key, required this.value, required this.onChanged});

  final bool value;
  final ValueChanged<bool>? onChanged;

  @override
  Widget build(BuildContext context) {
    final s = LfScheme.of(context);
    return GestureDetector(
      onTap: onChanged == null ? null : () => onChanged!(!value),
      child: AnimatedContainer(
        duration: LfDimens.tFast,
        width: 32,
        height: 18,
        padding: const EdgeInsets.all(2),
        decoration: BoxDecoration(
          color: value ? s.brand : s.text3.withValues(alpha: 0.55),
          borderRadius: BorderRadius.circular(LfDimens.rPill),
        ),
        child: AnimatedAlign(
          duration: LfDimens.tFast,
          curve: Curves.easeOut,
          alignment: value ? Alignment.centerRight : Alignment.centerLeft,
          child: Container(
            width: 14,
            height: 14,
            decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
          ),
        ),
      ),
    );
  }
}

/// `<kbd>` 样式小键帽。
class Kbd extends StatelessWidget {
  const Kbd(this.text, {super.key});

  final String text;

  @override
  Widget build(BuildContext context) {
    final s = LfScheme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
      decoration: BoxDecoration(
        color: s.bgHover,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: s.divider),
        boxShadow: [BoxShadow(color: s.divider, offset: const Offset(0, 1))],
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: LfDimens.fsXs,
          fontFamily: 'Menlo, SF Mono, monospace',
          color: s.text2,
        ),
      ),
    );
  }
}

/// 内联错误条 —— 原型 .inline-error（测试连接失败 / 热键冲突，PRD §7）。
class InlineError extends StatelessWidget {
  const InlineError({super.key, required this.title, required this.body, this.actions, this.iconName = 'x'});

  final String title;
  final String body;
  final List<Widget>? actions;
  final String iconName;

  @override
  Widget build(BuildContext context) {
    final s = LfScheme.of(context);
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: s.error.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(LfDimens.rCard),
        border: Border.all(color: s.error.withValues(alpha: 0.35)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 22,
            height: 22,
            decoration: BoxDecoration(color: s.error, shape: BoxShape.circle),
            child: Center(child: LfIcons.icon(iconName, size: 12, color: Colors.white)),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: LfDimens.fsBase,
                    fontWeight: FontWeight.w600,
                    color: s.error,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  body,
                  style: TextStyle(fontSize: LfDimens.fsSm, color: s.text2, height: 1.55),
                ),
                if (actions != null && actions!.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Wrap(spacing: 14, children: actions!),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// 错误条内文字链接（→ 返回修改 Key）。
class InlineLink extends StatelessWidget {
  const InlineLink(this.label, {super.key, this.onTap});

  final String label;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final s = LfScheme.of(context);
    return GestureDetector(
      onTap: onTap,
      child: Text(
        label,
        style: TextStyle(
          fontSize: LfDimens.fsSm,
          fontWeight: FontWeight.w600,
          color: s.brand,
          decoration: TextDecoration.none,
        ),
      ),
    );
  }
}

/// 页面标题组 —— 原型 .mw-h1 / .mw-sub / .mw-h2。
class PageTitle extends StatelessWidget {
  const PageTitle({super.key, required this.title, this.subtitle});

  final String title;
  final String? subtitle;

  @override
  Widget build(BuildContext context) {
    final s = LfScheme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(
            fontSize: LfDimens.fsXl,
            fontWeight: FontWeight.w700,
            color: s.text,
            height: 1.3,
          ),
        ),
        if (subtitle != null) ...[
          const SizedBox(height: 4),
          Text(
            subtitle!,
            style: TextStyle(fontSize: LfDimens.fsSm, color: s.text2, height: 1.5),
          ),
        ],
        const SizedBox(height: 16),
      ],
    );
  }
}

class SectionTitle extends StatelessWidget {
  const SectionTitle(this.title, {super.key});

  final String title;

  @override
  Widget build(BuildContext context) {
    final s = LfScheme.of(context);
    return Padding(
      padding: const EdgeInsets.only(top: 16, bottom: 8),
      child: Text(
        title,
        style: TextStyle(
          fontSize: LfDimens.fsBase,
          fontWeight: FontWeight.w700,
          color: s.text,
        ),
      ),
    );
  }
}

/// 设置行（label + 控件）—— 原型 .settings-row / .pref-row。
class SettingRow extends StatelessWidget {
  const SettingRow({
    super.key,
    required this.title,
    this.desc,
    required this.trailing,
    this.dense = false,
  });

  final String title;
  final String? desc;
  final Widget trailing;
  final bool dense;

  @override
  Widget build(BuildContext context) {
    final s = LfScheme.of(context);
    return Padding(
      padding: EdgeInsets.symmetric(vertical: dense ? 6 : 10),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(fontSize: LfDimens.fsBase, color: s.text),
                ),
                if (desc != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    desc!,
                    style: TextStyle(fontSize: LfDimens.fsXs, color: s.text2, height: 1.5),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: 12),
          trailing,
        ],
      ),
    );
  }
}

/// 表单字段（原型 .form-row：label + input + hint）。
class FormFieldRow extends StatelessWidget {
  const FormFieldRow({
    super.key,
    required this.label,
    required this.child,
    this.hint,
    this.requiredField = false,
  });

  final String label;
  final Widget child;
  final String? hint;
  final bool requiredField;

  @override
  Widget build(BuildContext context) {
    final s = LfScheme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              label,
              style: TextStyle(fontSize: LfDimens.fsSm, fontWeight: FontWeight.w600, color: s.text),
            ),
            if (requiredField)
              Text(' *', style: TextStyle(fontSize: LfDimens.fsSm, color: s.error)),
          ],
        ),
        const SizedBox(height: 6),
        child,
        if (hint != null) ...[
          const SizedBox(height: 5),
          Text(
            hint!,
            style: TextStyle(fontSize: LfDimens.fsXs, color: s.text3, height: 1.5),
          ),
        ],
      ],
    );
  }
}

/// 空状态（H 首页 / I 模型配置空态，PRD §7 绝不白屏）。
class EmptyState extends StatelessWidget {
  const EmptyState({
    super.key,
    required this.iconName,
    required this.title,
    required this.subtitle,
    this.actions,
  });

  final String iconName;
  final String title;
  final String subtitle;
  final List<Widget>? actions;

  @override
  Widget build(BuildContext context) {
    final s = LfScheme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 40),
      decoration: BoxDecoration(
        color: s.bgWindow,
        borderRadius: BorderRadius.circular(LfDimens.rCard),
        border: Border.all(color: s.divider),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: s.brandSoft,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Center(child: LfIcons.icon(iconName, size: 24, color: s.brand)),
          ),
          const SizedBox(height: 14),
          Text(
            title,
            style: TextStyle(fontSize: LfDimens.fsMd, fontWeight: FontWeight.w600, color: s.text),
          ),
          const SizedBox(height: 6),
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: Text(
              subtitle,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: LfDimens.fsSm,
                color: s.text2,
                height: 1.65,
              ),
            ),
          ),
          if (actions != null && actions!.isNotEmpty) ...[
            const SizedBox(height: 16),
            Wrap(spacing: 8, runSpacing: 8, alignment: WrapAlignment.center, children: actions!),
          ],
        ],
      ),
    );
  }
}

/// 状态小圆点（健康/在线指示）。
class StatusDot extends StatelessWidget {
  const StatusDot({super.key, this.ok = true, this.size = 7});

  final bool ok;
  final double size;

  @override
  Widget build(BuildContext context) {
    final s = LfScheme.of(context);
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: ok ? s.success : s.error,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: (ok ? s.success : s.error).withValues(alpha: 0.35),
            blurRadius: 4,
            spreadRadius: 1,
          ),
        ],
      ),
    );
  }
}

/// 徽章（.badge live 在线 / 普通灰）。
class Badge extends StatelessWidget {
  const Badge(this.text, {super.key, this.live = false});

  final String text;
  final bool live;

  @override
  Widget build(BuildContext context) {
    final s = LfScheme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: live ? s.success.withValues(alpha: 0.12) : s.bgHover,
        borderRadius: BorderRadius.circular(LfDimens.rPill),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: LfDimens.fsXs,
          fontWeight: FontWeight.w600,
          color: live ? s.success : s.text2,
        ),
      ),
    );
  }
}

/// 单字 Logo 容器（平台卡片 / Provider 行 / 当前默认模型）。
class LogoBox extends StatelessWidget {
  const LogoBox(this.char, {super.key, required this.color, this.size = 30, this.radius});

  final String char;
  final Color color;
  final double size;
  final double? radius;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(radius ?? size * 0.28),
      ),
      child: Center(
        child: Text(
          char,
          style: TextStyle(
            fontSize: size * 0.5,
            fontWeight: FontWeight.w700,
            color: Colors.white,
            height: 1.0,
          ),
        ),
      ),
    );
  }
}
