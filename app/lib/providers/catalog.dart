/// 平台目录 —— I 模型配置页 / L 首次引导共用的 8 平台卡片数据
/// （原型 renderI PLATS / renderL WIZ_PLATS 的数据源，PRD §5.3 ④）。
library;

import 'package:flutter/foundation.dart';

@immutable
class PlatformCatalogItem {
  const PlatformCatalogItem({
    required this.name,
    required this.logo,
    required this.color,
    required this.tag,
    required this.kind,
    this.keyHint,
  });

  final String name;
  final String logo; // 卡片上的单字 Logo
  final int color; // ARGB
  final String tag; // 模型系列提示
  final PlatformKind kind;
  final String? keyHint; // Key 前缀提示（sk-… 等）
}

enum PlatformKind { openAICompatible, anthropic, gemini, ollama, custom }

/// 8 平台卡片（新增 Provider 表单网格，顺序对齐原型 PLATS）。
const List<PlatformCatalogItem> kPlatformCatalog = [
  PlatformCatalogItem(
      name: 'OpenAI', logo: 'O', color: 0xFF10A37F, tag: 'gpt-4o 系',
      kind: PlatformKind.openAICompatible, keyHint: 'sk-…'),
  PlatformCatalogItem(
      name: 'Anthropic', logo: 'C', color: 0xFFD97757, tag: 'claude 系',
      kind: PlatformKind.anthropic, keyHint: 'sk-ant-…'),
  PlatformCatalogItem(
      name: 'Gemini', logo: 'G', color: 0xFF4285F4, tag: 'gemini 系',
      kind: PlatformKind.gemini, keyHint: 'AIza…'),
  PlatformCatalogItem(
      name: 'DeepSeek', logo: 'D', color: 0xFF4D6BFE, tag: 'deepseek-chat',
      kind: PlatformKind.openAICompatible, keyHint: 'sk-…'),
  PlatformCatalogItem(
      name: '通义', logo: '通', color: 0xFF615CED, tag: 'qwen 系',
      kind: PlatformKind.openAICompatible, keyHint: 'sk-…'),
  PlatformCatalogItem(
      name: '火山方舟', logo: '火', color: 0xFF0D5EF4, tag: 'doubao 系',
      kind: PlatformKind.openAICompatible, keyHint: 'ak-…'),
  PlatformCatalogItem(
      name: 'Ollama', logo: 'O', color: 0xFF1A1A1A, tag: '本地 · 离线',
      kind: PlatformKind.ollama),
  PlatformCatalogItem(
      name: '自定义', logo: '＋', color: 0xFF86909C, tag: 'OpenAI 兼容',
      kind: PlatformKind.custom, keyHint: 'sk-…'),
];

/// 首次引导平台卡（原型 WIZ_PLATS，6 项）。
const List<PlatformCatalogItem> kOnboardingCatalog = [
  PlatformCatalogItem(name: 'OpenAI', logo: 'O', color: 0xFF10A37F, tag: '', kind: PlatformKind.openAICompatible),
  PlatformCatalogItem(name: 'Anthropic', logo: 'C', color: 0xFFD97757, tag: '', kind: PlatformKind.anthropic),
  PlatformCatalogItem(name: 'Gemini', logo: 'G', color: 0xFF4285F4, tag: '', kind: PlatformKind.gemini),
  PlatformCatalogItem(name: 'DeepSeek', logo: 'D', color: 0xFF4D6BFE, tag: '', kind: PlatformKind.openAICompatible),
  PlatformCatalogItem(name: '通义', logo: '通', color: 0xFF615CED, tag: '', kind: PlatformKind.openAICompatible),
  PlatformCatalogItem(name: 'Ollama 本地', logo: 'O', color: 0xFF1A1A1A, tag: '', kind: PlatformKind.ollama),
];
