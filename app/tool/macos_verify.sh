#!/usr/bin/env bash
# ============================================================================
# macos_verify.sh · macOS 真机一键实机验证（T-020 收尾 / Round-4 准备包①）
#
# 用途：在 **macOS 真机**（Xcode 就绪）上：
#   1. flutter build macos --debug / --release 双构建
#   2. flutter run 启动并开启 log stream 全量采集
#   3. 六项原生能力「分步引导验证」（每步打印操作/预期/失败采集项，人工执行）
#   4. 全部日志 + 结果草稿归档 logs/macos-verify-<时间戳>/
#
# 用法：
#   bash app/tool/macos_verify.sh            # 完整流程（build + run + 六步引导）
#   bash app/tool/macos_verify.sh --build-only   # 只做双构建，不启动
#   bash app/tool/macos_verify.sh --skip-build   # 跳过构建直接 run+引导
#
# 产出：logs/macos-verify-<ts>/{flutter-build-debug.log, flutter-build-release.log,
#       flutter-run.log, log-stream.log, result-draft.md}
#   —— 全部内容可直接整包贴回给 Agent 定位。
# ============================================================================
set -uo pipefail

cd "$(dirname "$0")/../.." || exit 1   # 仓库根
APP_DIR="app"
TS="$(date +%Y%m%d-%H%M%S)"
LOG_DIR="logs/macos-verify-$TS"
mkdir -p "$LOG_DIR"

RED='\033[0;31m'; GRN='\033[0;32m'; YLW='\033[0;33m'; CYN='\033[0;36m'; DIM='\033[2m'; RST='\033[0m'

log()  { printf "${CYN}[verify]${RST} %s\n" "$*"; }
step() { printf "\n${YLW}━━━━━━━━ %s ━━━━━━━━${RST}\n" "$*"; }
ok()   { printf "${GRN}  ✓ %s${RST}\n" "$*"; }
bad()  { printf "${RED}  ✗ %s${RST}\n" "$*"; }

# ---------- 0. 环境自检 ----------------------------------------------------
step "0/8 环境自检"

if [ "$(uname)" != "Darwin" ]; then
  bad "本脚本只能在 macOS 上运行（当前 uname=$(uname)）。Linux 沙箱请看 docs/macos-verify-checklist.md 的「准备包说明」。"
  exit 1
fi
ok "macOS $(sw_vers -productVersion 2>/dev/null || echo '?')"

FLUTTER="${FLUTTER:-$(command -v flutter || true)}"
if [ -z "$FLUTTER" ]; then
  bad "找不到 flutter 命令。请 export FLUTTER=/path/to/flutter 后重试。"
  exit 1
fi
FLVER="$("$FLUTTER" --version --machine 2>/dev/null | head -1 || "$FLUTTER" --version | head -1)"
ok "flutter: $FLVER"
echo "flutter=$(basename "$FLUTTER") ($FLVER)" >> "$LOG_DIR/env.txt"
xcodebuild -version >> "$LOG_DIR/env.txt" 2>&1 || true
sw_vers >> "$LOG_DIR/env.txt" 2>&1

if ! xcode-select -p >/dev/null 2>&1; then
  bad "Xcode 未选择：xcode-select --install / sudo xcode-select -s /Applications/Xcode.app"
  exit 1
fi
ok "Xcode: $(xcodebuild -version | head -1)"

MODE="${1:-full}"

# ---------- 1. debug 构建 ---------------------------------------------------
step "1/8 flutter build macos --debug"
if (cd "$APP_DIR" && "$FLUTTER" build macos --debug) 2>&1 | tee "$LOG_DIR/flutter-build-debug.log"; then
  ok "debug 构建通过"
  echo "BUILD_DEBUG=OK" >> "$LOG_DIR/env.txt"
else
  bad "debug 构建失败 —— 把 $LOG_DIR/flutter-build-debug.log 整包贴回（重点看 Swift 编译错误行）"
  echo "BUILD_DEBUG=FAIL" >> "$LOG_DIR/env.txt"
  exit 1
fi

# ---------- 2. release 构建 -------------------------------------------------
step "2/8 flutter build macos --release"
if (cd "$APP_DIR" && "$FLUTTER" build macos --release) 2>&1 | tee "$LOG_DIR/flutter-build-release.log"; then
  ok "release 构建通过"
  echo "BUILD_RELEASE=OK" >> "$LOG_DIR/env.txt"
else
  bad "release 构建失败 —— 把 $LOG_DIR/flutter-build-release.log 整包贴回"
  echo "BUILD_RELEASE=FAIL" >> "$LOG_DIR/env.txt"
  # release 失败不终止：debug 能跑就先完成能力验证
fi

if [ "$MODE" = "--build-only" ]; then
  log "--build-only 模式结束，日志在 $LOG_DIR/"
  exit 0
fi

# ---------- 3. 启动 + 日志采集 ----------------------------------------------
step "3/8 启动 app（flutter run -d macos）+ log stream 采集"
LOG_STREAM_PID=""
cleanup() {
  [ -n "$LOG_STREAM_PID" ] && kill "$LOG_STREAM_PID" 2>/dev/null
}
trap cleanup EXIT

# 系统级日志（Carbon/AX/TCC/Keychain 的系统侧记录）单独采集一路
log stream --process '译语' --style compact --level debug >> "$LOG_DIR/log-stream.log" 2>&1 &
LOG_STREAM_PID=$!

# flutter run 前台跑（用户验证期间保持）；输出实时落盘
(cd "$APP_DIR" && "$FLUTTER" run -d macos) 2>&1 | tee "$LOG_DIR/flutter-run.log" &
RUN_PID=$!
sleep 25   # 等首编 + 引擎启动
if ! kill -0 "$RUN_PID" 2>/dev/null; then
  bad "flutter run 已退出 —— 把 $LOG_DIR/flutter-run.log 整包贴回（重点看 MissingPluginException / MethodChannel 报错）"
fi
ok "app 已启动（若窗口未出现：菜单栏找「译」字图标）"

# ---------- 4-8. 六项能力分步引导 -------------------------------------------
# 每步：操作 → 预期 → 失败采集。回车继续，Ctrl+C 中止（日志已落盘）。
ask() {
  printf "${DIM}  —— 完成后回车继续（Ctrl+C 中止并保留全部日志）${RST}"
  read -r
}

RESULT="$LOG_DIR/result-draft.md"
cat > "$RESULT" << 'EOF'
# macOS 实机验证结果草稿（验证完逐项补 ✅/❌ + 现象描述，整包贴回）
EOF

step "4/8 ① Keychain 存取（linguaflow/secure · ADR-001 链路）"
cat << 'EOF'
  操作：菜单栏「译」→ 打开主窗口 → Tab I 模型配置 → 任一 Profile 填 API Key
        → 「测试连接并保存」成功后，退出 app 重启 → 再进 Tab I 看 Key 是否还在。
  终端复核（可选）：
    security find-generic-password -s "com.linguaflow.keys" | head -8
  预期：①保存成功无报错；②重启后 Key 仍在（Profile 显示已配置）；
        ③security 命令能查到 service=com.linguaflow.keys 的条目。
  失败采集：flutter-run.log 里搜「MissingPluginException」「PlatformException」；
        若①就失败 → 大概率 MethodChannel 没通（截图 Tab I 状态栏「系统密钥串/混淆降级」标识）。
EOF
echo "## ① Keychain：结果=__" >> "$RESULT"; ask

step "5/8 ② Carbon 全局热键（linguaflow/native registerHotkeys）"
cat << 'EOF'
  操作：Tab J 快捷键 → 看注册报告（状态栏「原生全局热键 N/N 生效」）；
        聚焦任意其它 app 的输入框，按下唤起热键（默认 ⌥ Space / 或配置值）。
  预期：①Tab J 显示原生注册成功（非「进程内（Web 预览）」）；②其它 app 焦点下按热键，译语有反应。
  已知风险（对照 docs/method-channel-contract.md）：热键事件目前只进 trigger.results 流、
        无 UI 消费者 → 「按了热键 UI 无反应」属于**已预期**的问题，如实记录现象即可（不要当成新 bug 排查）。
  失败采集：flutter-run.log 搜「registerHotkeys」「hotkey」；log-stream.log 搜「Carbon」「HIToolbox」。
EOF
echo "## ② Carbon 热键：结果=__" >> "$RESULT"; ask

step "6/8 ③ AX 注入写回（linguaflow/native injectText）"
cat << 'EOF'
  操作：Tab C 划词翻译 或 Tab D 静默替换 → 在「备忘录/文本编辑」里选中一段文字 → 触发流程；
        另测 Tab A 成稿后「注入」按钮（AX 直写 / 剪贴板⌘V 逐级验证）。
  预期：译文写进目标 app 输入框。三级降级各自表现分别记录：
        ①AX selectedText 直写 ②AX value 覆盖 ③剪贴板+⌘V 合成事件（沙盒下③可能被系统丢弃，
        这是 docs/method-channel-contract.md §6 的「沙盒拍板项」——如实记录第③级是否生效）。
  失败采集：系统设置 → 隐私与安全性 → 辅助功能 里「译语」是否已勾选；
        log-stream.log 搜「AXError」「Accessibility」；记录目标 app 名（备忘录/浏览器/微信 行为可能不同）。
EOF
echo "## ③ AX 注入：结果=__（注明第几级降级生效）" >> "$RESULT"; ask

step "7/8 ④ NSPanel 悬浮窗（showOverlay）"
cat << 'EOF'
  操作：Tab B 悬浮窗 → 触发「系统浮层」模式（确认状态栏显示「原生」而非「应用内」）。
  已知风险：OverlayPanelController.attachFlutterView 全工程零调用 → **浮层很可能空白/无内容**，
        属于契约核对表 §5-R1 已预期问题。请记录：①panel 是否弹出（有边框/阴影/标题「译语 · …」）；
        ②内容是否空白；③关闭后主窗口是否正常；④连续触发两次是否叠两层。
  失败采集：flutter-run.log 搜「showOverlay」「NSPanel」；现象截图。
EOF
echo "## ④ NSPanel：结果=__（空白/内容/关闭行为）" >> "$RESULT"; ask

step "8/8 ⑤ StatusBar 菜单 + ⑥ 权限引导"
cat << 'EOF'
  ⑤ StatusBar：菜单栏「译」图标点击 → Popover 弹出（420×620）→ 点击外部关闭。
        预期：Popover 正常开合；关闭后焦点归还宿主 app。
        记录：Popover 打开期间主窗口是否空白（同一 FlutterViewController 被两个宿主复用的已知疑点）。
  ⑥ 权限引导：Tab L 首次引导 → 走到权限步 → 点「打开系统设置」。
        预期：真实拉起 系统设置→隐私与安全性→辅助功能；授权后回 app，切走再切回（resumed）→ 状态自动刷新为「已授权」。
        失败采集：flutter-run.log 搜「openPermissionSettings」「x-apple.systempreferences」；
        深链落点截图（macOS 13+ 可能映射到新设置面板）。
EOF
echo "## ⑤ StatusBar：结果=__
## ⑥ 权限引导：结果=__（深链是否拉起/resumed 是否刷新）" >> "$RESULT"; ask

cleanup
printf "\n${GRN}━━━━ 验证完成 ━━━━${RST}\n归档目录：${CYN}%s${RST}\n" "$LOG_DIR"
log "请把整个目录（至少 result-draft.md + flutter-run.log + log-stream.log + env.txt）贴回给 Agent。"
ls -la "$LOG_DIR"
