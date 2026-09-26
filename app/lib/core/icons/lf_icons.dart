import 'package:flutter/widgets.dart';
import 'package:flutter_svg/flutter_svg.dart';

/// 译语内联 SVG 线性图标系统 —— 原型 v7-spa app.js `ICONS` 字典 1:1 平移。
/// 24 viewBox · stroke 1.7 · round cap/join · currentColor 继承。
abstract final class LfIcons {
  static const Map<String, String> paths = {
    'home': '<path d="M3 10.5 12 3l9 7.5"/><path d="M5 9.5V20a1 1 0 0 0 1 1h12a1 1 0 0 0 1-1V9.5"/>',
    'chip': '<rect x="6" y="6" width="12" height="12" rx="2.5"/><rect x="10" y="10" width="4" height="4" rx="0.5"/><path d="M9 2.5v3M15 2.5v3M9 18.5v3M15 18.5v3M2.5 9h3M2.5 15h3M18.5 9h3M18.5 15h3"/>',
    'cmd': '<path d="M15 6v12a3 3 0 1 0 3-3H6a3 3 0 1 0 3 3V6a3 3 0 1 0-3 3h12a3 3 0 1 0-3-3"/>',
    'sparkles': '<path d="M12 3.5 13.8 9l5.5 1.8-5.5 1.8L12 18.1l-1.8-5.5L4.7 10.8 10.2 9z"/><path d="M19 15.5l.8 2.2 2.2.8-2.2.8-.8 2.2-.8-2.2-2.2-.8 2.2-.8z"/>',
    'mic': '<rect x="9" y="2.5" width="6" height="11.5" rx="3"/><path d="M5.5 11a6.5 6.5 0 0 0 13 0M12 17.5V21M9 21h6"/>',
    'globe': '<circle cx="12" cy="12" r="9"/><path d="M3 12h18"/><path d="M12 3c2.3 2.3 3.6 5.5 3.6 9s-1.3 6.7-3.6 9c-2.3-2.3-3.6-5.5-3.6-9S9.7 5.3 12 3z"/>',
    'book': '<path d="M4 19.5A2.5 2.5 0 0 1 6.5 17H20"/><path d="M6.5 2H20v20H6.5A2.5 2.5 0 0 1 4 19.5v-15A2.5 2.5 0 0 1 6.5 2z"/>',
    'clock': '<circle cx="12" cy="12" r="9"/><path d="M12 7v5l3.2 1.9"/>',
    'shield': '<path d="M12 2.5 20 6v5c0 5-3.4 8.9-8 10.5C7.4 19.9 4 16 4 11V6z"/>',
    'shieldCheck': '<path d="M12 2.5 20 6v5c0 5-3.4 8.9-8 10.5C7.4 19.9 4 16 4 11V6z"/><path d="M8.5 11.5l2.4 2.4 4.6-4.8"/>',
    'compass': '<circle cx="12" cy="12" r="9"/><path d="M15.5 8.5l-1.8 5.2-5.2 1.8 1.8-5.2z"/>',
    'keyboard': '<rect x="2.5" y="6" width="19" height="12" rx="2"/><path d="M6.5 10h.01M10.2 10h.01M13.9 10h.01M17.6 10h.01M8 14h8"/>',
    'play': '<path d="M7.5 5.4v13.2a.6.6 0 0 0 .9.5l10.5-6.6a.6.6 0 0 0 0-1L8.4 4.9a.6.6 0 0 0-.9.5z"/>',
    'rotate': '<path d="M3 3.5V9h5.5"/><path d="M3.8 9A9 9 0 1 1 3 13.5"/>',
    'help': '<circle cx="12" cy="12" r="9"/><path d="M9.2 9.2a2.9 2.9 0 0 1 5.6 1c0 1.9-2.8 2.3-2.8 3.8"/><path d="M12 17.2h.01"/>',
    'x': '<path d="M6 6l12 12M18 6 6 18"/>',
    'check': '<path d="M4.5 12.6l5 5L19.5 6.5"/>',
    'warn': '<path d="M12 3.5 2.8 19.5h18.4z"/><path d="M12 10v4.5M12 17.5h.01"/>',
    'copy': '<rect x="9" y="9" width="12" height="12" rx="2.5"/><path d="M5.5 15H4.5A2 2 0 0 1 2.5 13V4.5a2 2 0 0 1 2-2H13a2 2 0 0 1 2 2v1"/>',
    'inject': '<path d="M12 3v11.5M6.5 9.5 12 15l5.5-5.5"/><path d="M4.5 20.5h15"/>',
    'textSelect': '<path d="M12 6.5v11"/><path d="M8 6.5h8M8 17.5h8"/><path d="M5 3.5h14M5 20.5h14" opacity="0.45"/>',
    'scan': '<path d="M4 8V6a2 2 0 0 1 2-2h2M16 4h2a2 2 0 0 1 2 2v2M20 16v2a2 2 0 0 1-2 2h-2M8 20H6a2 2 0 0 1-2-2v-2"/><path d="M4.5 12h15"/>',
    'window': '<rect x="3" y="4.5" width="18" height="15" rx="3"/><path d="M3 9h18M6.5 6.75h.01M9 6.75h.01"/>',
    'swap': '<path d="M16.5 3 21 7.5l-4.5 4.5"/><path d="M21 7.5H7"/><path d="M7.5 21 3 16.5 7.5 12"/><path d="M3 16.5h14"/>',
    'fileText': '<path d="M14 2.5H6.5a2 2 0 0 0-2 2v15a2 2 0 0 0 2 2h11a2 2 0 0 0 2-2V8z"/><path d="M14 2.5V8h5.5M9 13h6M9 17h6"/>',
    'barChart': '<path d="M6.5 20V11M12 20V4.5M17.5 20v-6"/><path d="M3 20h18"/>',
    'calendar': '<rect x="3" y="5" width="18" height="16" rx="2.5"/><path d="M8 3v4M16 3v4M3 10.5h18"/>',
    'megaphone': '<path d="M3 11v2l14 5.5v-15z"/><path d="M7.5 14.8V19a1.8 1.8 0 0 0 3.6 0v-3"/><path d="M20 9.5a3 3 0 0 1 0 5"/>',
    'mail': '<rect x="2.5" y="5" width="19" height="14" rx="2.5"/><path d="m3.5 7.5 8.5 5.8 8.5-5.8"/>',
    'code': '<path d="M8.5 7.5 4 12l4.5 4.5M15.5 7.5 20 12l-4.5 4.5"/>',
    'plus': '<path d="M12 5v14M5 12h14"/>',
    'download': '<path d="M12 3v11M7 9.5l5 5 5-5"/><path d="M4 20.5h16"/>',
    'settings': '<path d="M10.4 3h3.2l.4 2.4a7 7 0 0 1 1.7 1l2.3-.9 1.6 2.8-1.8 1.6a7 7 0 0 1 0 2l1.8 1.6-1.6 2.8-2.3-.9a7 7 0 0 1-1.7 1L13.6 21h-3.2l-.4-2.4a7 7 0 0 1-1.7-1l-2.3.9-1.6-2.8 1.8-1.6a7 7 0 0 1 0-2L4.4 10.3 6 7.5l2.3.9a7 7 0 0 1 1.7-1z"/><circle cx="12" cy="12" r="2.8"/>',
    'accessibility': '<circle cx="12" cy="4.8" r="1.9"/><path d="M4.5 9.3c2.5.8 5 1.2 7.5 1.2s5-.4 7.5-1.2"/><path d="M12 10.5v4.2l-3.2 6M12 14.7l3.2 6"/>',
    'mouse': '<rect x="7" y="2.8" width="10" height="18.4" rx="5"/><path d="M12 6.8v4.4"/>',
    'ban': '<circle cx="12" cy="12" r="9"/><path d="M5.7 5.7l12.6 12.6"/>',
    'refresh': '<path d="M21 12a9 9 0 1 1-2.6-6.3"/><path d="M21 3.5V9h-5.5"/>',
    'smile': '<circle cx="12" cy="12" r="9"/><path d="M8.5 14a4.5 4.5 0 0 0 7 0"/><path d="M9 9.5h.01M15 9.5h.01"/>',
    'windows': '<rect x="3.5" y="3.5" width="7.5" height="7.5" rx="1"/><rect x="13" y="3.5" width="7.5" height="7.5" rx="1"/><rect x="3.5" y="13" width="7.5" height="7.5" rx="1"/><rect x="13" y="13" width="7.5" height="7.5" rx="1"/>',
    'folder': '<path d="M3 7.5a2 2 0 0 1 2-2h4.2l2 2.2H19a2 2 0 0 1 2 2v8.8a2 2 0 0 1-2 2H5a2 2 0 0 1-2-2z"/>',
    'android': '<path d="M5.5 11a6.5 6.5 0 0 1 13 0z"/><path d="M7 7 5.5 4.8M17 7l1.5-2.2"/><circle cx="9.3" cy="9" r="0.3"/><circle cx="14.7" cy="9" r="0.3"/><path d="M5.5 11h13v5a2.2 2.2 0 0 1-2.2 2.2H7.7A2.2 2.2 0 0 1 5.5 16zM8.2 18.2v2.3M15.8 18.2v2.3"/>',
    'chev': '<path d="M9.5 5.5 16 12l-6.5 6.5"/>',
  };

  /// 尺寸档位（原型 .ic / .ic.sm / .ic.lg / .ic.xl）
  static const double s = 14;
  static const double sm = 12;
  static const double lg = 18;
  static const double xl = 22;

  static String _svg(String name) =>
      '<svg viewBox="0 0 24 24" fill="none" xmlns="http://www.w3.org/2000/svg">'
      '${paths[name] ?? ''}</svg>';

  /// 线性图标（stroke 1.7 / round / 继承 currentColor）
  static Widget icon(String name, {double size = s, Color? color}) => SvgPicture.string(
        _svg(name),
        width: size,
        height: size,
        colorFilter: color != null ? ColorFilter.mode(color, BlendMode.srcIn) : null,
      );

  /// 填充类图标（WiFi/电池等 UI chrome 用，很少用到）
  static Widget filled(String body, {double size = s, Color? color}) => SvgPicture.string(
        '<svg viewBox="0 0 24 24" fill="currentColor" xmlns="http://www.w3.org/2000/svg">$body</svg>',
        width: size,
        height: size,
        colorFilter: color != null ? ColorFilter.mode(color, BlendMode.srcIn) : null,
      );
}
