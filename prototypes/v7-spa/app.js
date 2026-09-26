/* ========================================================================
   译语 v6 · 13 页全量演示原型 · 行为层
   - 所有数据 mock，无真实网络/ASR
   - 每个流程通过 render() 渲染到 #stageOverlay 或宿主窗口（page-mode）
   - 每个流程有"演示控制"面板：可切换状态、重放
   - v6 在 v5 基础上新增 Tab H-M 六页 + Popover 最近译文（PRD §6 全量）
   ======================================================================== */

(() => {
  "use strict";

  // ---- DOM 引用 ----
  const $ = (sel, root = document) => root.querySelector(sel);
  const $$ = (sel, root = document) => Array.from(root.querySelectorAll(sel));

  const els = {
    popover: $("#lingualPopover"),
    popoverIcon: $("#lingualIcon"),
    popoverCopy: $("#popoverCopy"),
    popoverInject: $("#popoverInject"),
    hostApp: document.querySelector(".host-app"),
    hostInput: $("#hostInput"),
    hostThread: $("#hostThread"),
    hostTitle: $("#hostTitle"),
    overlay: $("#stageOverlay"),
    canvas: $("#stageCanvas"),
    stageTabs: $$(".stage-tab"),
    demoControls: $("#demoControls"),
    demoStateRow: $("#demoStateRow"),
    demoPlay: $("#demoPlay"),
    demoReset: $("#demoReset"),
    demoHint: $("#demoHint"),
    settings: $("#settings"),
    settingsClose: $("#settingsClose"),
    settingsTabs: $$(".settings-tab"),
    settingsPanes: $$(".settings-pane"),
    termTabs: $$(".term-tab"),
    termList: $("#termList"),
    hotkeyList: $("#hotkeyList"),
    menubarClock: $("#menubarClock"),
    popoverItems: $$(".popover-item[data-trigger]"),
    tourToggle: $("#tourToggle"),
    tourPanel: $("#tourPanel"),
    tourClose: $("#tourClose"),
  };

  // ============================================================
  // 通用工具
  // ============================================================
  const sleep = (ms) => new Promise((r) => setTimeout(r, ms));

  const clear = (el) => { while (el.firstChild) el.removeChild(el.firstChild); };

  const h = (tag, attrs, ...children) => {
    const node = document.createElement(tag);
    for (const [k, v] of Object.entries(attrs || {})) {
      if (k === "class") node.className = v;
      else if (k === "style" && typeof v === "object") Object.assign(node.style, v);
      else if (k === "innerHTML") node.innerHTML = v;
      else if (k.startsWith("on") && typeof v === "function") node.addEventListener(k.slice(2).toLowerCase(), v);
      else if (k === "dataset" && typeof v === "object") for (const [dk, dv] of Object.entries(v)) node.dataset[dk] = dv;
      else if (v !== null && v !== undefined) node.setAttribute(k, v);
    }
    for (const c of children.flat()) {
      if (c == null || c === false) continue;
      node.appendChild(typeof c === "string" ? document.createTextNode(c) : c);
    }
    return node;
  };

  const showHint = (text, ms = 3000) => {
    els.demoHint.textContent = text;
    els.demoHint.hidden = false;
    clearTimeout(showHint._t);
    if (ms) showHint._t = setTimeout(() => { els.demoHint.hidden = true; }, ms);
  };

  // ============================================================
  // v7.1 · 内联 SVG 线性图标系统（替代 emoji：统一风格 / 跨平台一致）
  // 24 viewBox · stroke 1.7 · round cap/join · currentColor 继承
  // ============================================================
  const ICONS = {
    home: '<path d="M3 10.5 12 3l9 7.5"/><path d="M5 9.5V20a1 1 0 0 0 1 1h12a1 1 0 0 0 1-1V9.5"/>',
    chip: '<rect x="6" y="6" width="12" height="12" rx="2.5"/><rect x="10" y="10" width="4" height="4" rx="0.5"/><path d="M9 2.5v3M15 2.5v3M9 18.5v3M15 18.5v3M2.5 9h3M2.5 15h3M18.5 9h3M18.5 15h3"/>',
    cmd: '<path d="M15 6v12a3 3 0 1 0 3-3H6a3 3 0 1 0 3 3V6a3 3 0 1 0-3 3h12a3 3 0 1 0-3-3"/>',
    sparkles: '<path d="M12 3.5 13.8 9l5.5 1.8-5.5 1.8L12 18.1l-1.8-5.5L4.7 10.8 10.2 9z"/><path d="M19 15.5l.8 2.2 2.2.8-2.2.8-.8 2.2-.8-2.2-2.2-.8 2.2-.8z"/>',
    mic: '<rect x="9" y="2.5" width="6" height="11.5" rx="3"/><path d="M5.5 11a6.5 6.5 0 0 0 13 0M12 17.5V21M9 21h6"/>',
    globe: '<circle cx="12" cy="12" r="9"/><path d="M3 12h18"/><path d="M12 3c2.3 2.3 3.6 5.5 3.6 9s-1.3 6.7-3.6 9c-2.3-2.3-3.6-5.5-3.6-9S9.7 5.3 12 3z"/>',
    book: '<path d="M4 19.5A2.5 2.5 0 0 1 6.5 17H20"/><path d="M6.5 2H20v20H6.5A2.5 2.5 0 0 1 4 19.5v-15A2.5 2.5 0 0 1 6.5 2z"/>',
    clock: '<circle cx="12" cy="12" r="9"/><path d="M12 7v5l3.2 1.9"/>',
    shield: '<path d="M12 2.5 20 6v5c0 5-3.4 8.9-8 10.5C7.4 19.9 4 16 4 11V6z"/>',
    shieldCheck: '<path d="M12 2.5 20 6v5c0 5-3.4 8.9-8 10.5C7.4 19.9 4 16 4 11V6z"/><path d="M8.5 11.5l2.4 2.4 4.6-4.8"/>',
    compass: '<circle cx="12" cy="12" r="9"/><path d="M15.5 8.5l-1.8 5.2-5.2 1.8 1.8-5.2z"/>',
    keyboard: '<rect x="2.5" y="6" width="19" height="12" rx="2"/><path d="M6.5 10h.01M10.2 10h.01M13.9 10h.01M17.6 10h.01M8 14h8"/>',
    play: '<path d="M7.5 5.4v13.2a.6.6 0 0 0 .9.5l10.5-6.6a.6.6 0 0 0 0-1L8.4 4.9a.6.6 0 0 0-.9.5z"/>',
    rotate: '<path d="M3 3.5V9h5.5"/><path d="M3.8 9A9 9 0 1 1 3 13.5"/>',
    help: '<circle cx="12" cy="12" r="9"/><path d="M9.2 9.2a2.9 2.9 0 0 1 5.6 1c0 1.9-2.8 2.3-2.8 3.8"/><path d="M12 17.2h.01"/>',
    x: '<path d="M6 6l12 12M18 6 6 18"/>',
    check: '<path d="M4.5 12.6l5 5L19.5 6.5"/>',
    warn: '<path d="M12 3.5 2.8 19.5h18.4z"/><path d="M12 10v4.5M12 17.5h.01"/>',
    copy: '<rect x="9" y="9" width="12" height="12" rx="2.5"/><path d="M5.5 15H4.5A2 2 0 0 1 2.5 13V4.5a2 2 0 0 1 2-2H13a2 2 0 0 1 2 2v1"/>',
    inject: '<path d="M12 3v11.5M6.5 9.5 12 15l5.5-5.5"/><path d="M4.5 20.5h15"/>',
    textSelect: '<path d="M12 6.5v11"/><path d="M8 6.5h8M8 17.5h8"/><path d="M5 3.5h14M5 20.5h14" opacity="0.45"/>',
    scan: '<path d="M4 8V6a2 2 0 0 1 2-2h2M16 4h2a2 2 0 0 1 2 2v2M20 16v2a2 2 0 0 1-2 2h-2M8 20H6a2 2 0 0 1-2-2v-2"/><path d="M4.5 12h15"/>',
    window: '<rect x="3" y="4.5" width="18" height="15" rx="3"/><path d="M3 9h18M6.5 6.75h.01M9 6.75h.01"/>',
    swap: '<path d="M16.5 3 21 7.5l-4.5 4.5"/><path d="M21 7.5H7"/><path d="M7.5 21 3 16.5 7.5 12"/><path d="M3 16.5h14"/>',
    fileText: '<path d="M14 2.5H6.5a2 2 0 0 0-2 2v15a2 2 0 0 0 2 2h11a2 2 0 0 0 2-2V8z"/><path d="M14 2.5V8h5.5M9 13h6M9 17h6"/>',
    barChart: '<path d="M6.5 20V11M12 20V4.5M17.5 20v-6"/><path d="M3 20h18"/>',
    calendar: '<rect x="3" y="5" width="18" height="16" rx="2.5"/><path d="M8 3v4M16 3v4M3 10.5h18"/>',
    megaphone: '<path d="M3 11v2l14 5.5v-15z"/><path d="M7.5 14.8V19a1.8 1.8 0 0 0 3.6 0v-3"/><path d="M20 9.5a3 3 0 0 1 0 5"/>',
    mail: '<rect x="2.5" y="5" width="19" height="14" rx="2.5"/><path d="m3.5 7.5 8.5 5.8 8.5-5.8"/>',
    code: '<path d="M8.5 7.5 4 12l4.5 4.5M15.5 7.5 20 12l-4.5 4.5"/>',
    plus: '<path d="M12 5v14M5 12h14"/>',
    download: '<path d="M12 3v11M7 9.5l5 5 5-5"/><path d="M4 20.5h16"/>',
    settings: '<path d="M10.4 3h3.2l.4 2.4a7 7 0 0 1 1.7 1l2.3-.9 1.6 2.8-1.8 1.6a7 7 0 0 1 0 2l1.8 1.6-1.6 2.8-2.3-.9a7 7 0 0 1-1.7 1L13.6 21h-3.2l-.4-2.4a7 7 0 0 1-1.7-1l-2.3.9-1.6-2.8 1.8-1.6a7 7 0 0 1 0-2L4.4 10.3 6 7.5l2.3.9a7 7 0 0 1 1.7-1z"/><circle cx="12" cy="12" r="2.8"/>',
    accessibility: '<circle cx="12" cy="4.8" r="1.9"/><path d="M4.5 9.3c2.5.8 5 1.2 7.5 1.2s5-.4 7.5-1.2"/><path d="M12 10.5v4.2l-3.2 6M12 14.7l3.2 6"/>',
    mouse: '<rect x="7" y="2.8" width="10" height="18.4" rx="5"/><path d="M12 6.8v4.4"/>',
    ban: '<circle cx="12" cy="12" r="9"/><path d="M5.7 5.7l12.6 12.6"/>',
    refresh: '<path d="M21 12a9 9 0 1 1-2.6-6.3"/><path d="M21 3.5V9h-5.5"/>',
    smile: '<circle cx="12" cy="12" r="9"/><path d="M8.5 14a4.5 4.5 0 0 0 7 0"/><path d="M9 9.5h.01M15 9.5h.01"/>',
    windows: '<rect x="3.5" y="3.5" width="7.5" height="7.5" rx="1"/><rect x="13" y="3.5" width="7.5" height="7.5" rx="1"/><rect x="3.5" y="13" width="7.5" height="7.5" rx="1"/><rect x="13" y="13" width="7.5" height="7.5" rx="1"/>',
    folder: '<path d="M3 7.5a2 2 0 0 1 2-2h4.2l2 2.2H19a2 2 0 0 1 2 2v8.8a2 2 0 0 1-2 2H5a2 2 0 0 1-2-2z"/>',
    android: '<path d="M5.5 11a6.5 6.5 0 0 1 13 0z"/><path d="M7 7 5.5 4.8M17 7l1.5-2.2"/><circle cx="9.3" cy="9" r="0.3"/><circle cx="14.7" cy="9" r="0.3"/><path d="M5.5 11h13v5a2.2 2.2 0 0 1-2.2 2.2H7.7A2.2 2.2 0 0 1 5.5 16zM8.2 18.2v2.3M15.8 18.2v2.3"/>',
  };

  // icon(name, sizeClass) → <span class="ic ..."><svg>…</svg></span>
  function icon(name, size) {
    return h("span", {
      class: `ic${size ? " " + size : ""}`,
      "aria-hidden": "true",
      innerHTML: `<svg viewBox="0 0 24 24">${ICONS[name] || ""}</svg>`,
    });
  }

  // ============================================================
  // 菜单栏时钟
  // ============================================================
  function tickClock() {
    const d = new Date();
    const days = ["周日", "周一", "周二", "周三", "周四", "周五", "周六"];
    const hh = String(d.getHours()).padStart(2, "0");
    const mm = String(d.getMinutes()).padStart(2, "0");
    els.menubarClock.textContent = `${days[d.getDay()]} ${hh}:${mm}`;
    els.menubarClock.dateTime = d.toISOString();
  }
  tickClock();
  setInterval(tickClock, 30_000);

  // ============================================================
  // 菜单栏 Popover 开关
  // ============================================================
  function togglePopover(force) {
    const isOpen = !els.popover.hidden;
    const next = force === undefined ? !isOpen : force;
    els.popover.hidden = !next;
    els.popoverIcon.setAttribute("aria-expanded", String(next));
  }
  els.popoverIcon.addEventListener("click", (e) => {
    e.stopPropagation();
    togglePopover();
  });
  document.addEventListener("click", (e) => {
    if (!els.popover.hidden && !els.popover.contains(e.target)) togglePopover(false);
  });
  document.addEventListener("keydown", (e) => {
    if (e.key === "Escape" && !els.popover.hidden) togglePopover(false);
  });
  // Popover 流程入口：点流程跳到对应 Tab
  els.popoverItems.forEach((btn) => {
    btn.addEventListener("click", () => {
      const tab = btn.dataset.trigger;
      switchTab(tab);
      togglePopover(false);
    });
  });

  // v6 · Popover 最近一条译文：复制 / 注入（PRD §6 #13 / ADR-005）
  if (els.popoverCopy) {
    els.popoverCopy.addEventListener("click", () => {
      showHint("已复制译文到剪贴板（演示）", 2200);
      togglePopover(false);
    });
  }
  if (els.popoverInject) {
    els.popoverInject.addEventListener("click", () => {
      togglePopover(false);
      switchTab("A");
      showHint("已注入到当前输入框（演示 → 切到流程 A）", 2600);
    });
  }

  // v6 · 走查指南面板
  function toggleTour(force) {
    const next = force === undefined ? els.tourPanel.hidden : force;
    els.tourPanel.hidden = !next;
    els.tourToggle.setAttribute("aria-expanded", String(next));
  }
  if (els.tourToggle) {
    els.tourToggle.addEventListener("click", () => toggleTour());
    els.tourClose.addEventListener("click", () => toggleTour(false));
    document.addEventListener("keydown", (e) => {
      if (e.key === "Escape" && !els.tourPanel.hidden) toggleTour(false);
    });
  }

  // ============================================================
  // 演示 Tab 切换
  // ============================================================
  let currentTab = "A";
  let currentDemo = null;       // 当前激活的演示实例
  let currentDemoTab = null;    // v7.2：setPageMode 用的当前 Tab（先于 currentDemo 赋值）
  let currentStateIdx = 0;      // 当前演示状态索引
  let currentStates = [];       // 当前演示的状态列表
  const playTimers = new Set(); // 全部在途延时回调（切页统一清理，防孤儿回调跨页污染）

  // 演示用延时：登记到 playTimers，到期自动移除
  function schedule(fn, ms) {
    const id = setTimeout(() => { playTimers.delete(id); fn(); }, ms);
    playTimers.add(id);
    return id;
  }

  function switchTab(tab) {
    currentTab = tab;
    els.stageTabs.forEach((t) => {
      const active = t.dataset.tab === tab;
      t.classList.toggle("active", active);
      t.setAttribute("aria-selected", String(active));
    });
    renderDemo(tab);
  }

  els.stageTabs.forEach((t) => t.addEventListener("click", () => switchTab(t.dataset.tab)));

  // ============================================================
  // 演示控制面板
  // ============================================================
  function setDemoControls(states, onPlay, onReset) {
    currentStates = states || [];
    currentStateIdx = 0;
    clear(els.demoStateRow);
    currentStates.forEach((label, i) => {
      const b = h("button", { type: "button" }, `${i + 1}. ${label}`);
      b.addEventListener("click", () => {
        currentStateIdx = i;
        updateControlsActive();
        runState(i);
      });
      els.demoStateRow.appendChild(b);
    });
    els.demoPlay.onclick = () => {
      onPlay && onPlay();
    };
    els.demoReset.onclick = () => {
      onReset && onReset();
    };
    updateControlsActive();
  }

  function updateControlsActive() {
    const btns = els.demoStateRow.children;
    for (let i = 0; i < btns.length; i++) {
      btns[i].classList.toggle("active", i === currentStateIdx);
    }
  }

  function runState(i) {
    // 各 demo 自己在 render 时挂这个
    if (window.__runState) window.__runState(i);
  }

  // ============================================================
  // 渲染分发
  // ============================================================
  // H/I/J/K 为"整页模式"：内容铺满宿主窗口（隐藏底部输入框）
  const PAGE_MODE_TABS = new Set(["H", "I", "J", "K"]);
  // v7.2：G/M/N/O 为"全场景模式"（手机/桌面整体在 overlay 中），隐藏宿主窗口避免鬼影
  const GHOST_TABS = new Set(["G", "M", "N", "O"]);

  function setPageMode(on) {
    els.hostApp.classList.toggle("page-mode", !!on);
    els.hostApp.classList.toggle("ghost", GHOST_TABS.has(currentDemoTab));
  }

  function renderDemo(tab) {
    clear(els.overlay);
    cancelDemo();
    currentDemoTab = tab;
    setPageMode(PAGE_MODE_TABS.has(tab));

    const renderer = {
      A: renderA,
      B: renderB,
      C: renderC,
      D: renderD,
      E: renderE,
      F: renderF,
      G: renderG,
      H: renderH,
      I: renderI,
      J: renderJ,
      K: renderK,
      L: renderL,
      M: renderM,
      N: renderN,
      O: renderO,
    }[tab];

    if (renderer) {
      currentDemo = tab;
      renderer();
    } else {
      currentDemo = null;
    }
  }

  function cancelDemo() {
    for (const id of playTimers) clearTimeout(id);
    playTimers.clear();
    // v7.1 修复：不再置空 window.__runState。
    // 原实现导致 renderX() 末尾初始化态（内含 cancelDemo）清掉刚赋值的
    // __runState，「演示控制」单切状态按钮全程失效；其生命周期由
    // renderDemo → renderer() 重新赋值管理，清定时器职责与它无关。
  }

  // ============================================================
  // 流程 A · 按住说话 → 润色成稿落框（v7 定位对齐 Typeless/Chatterfly）
  // PRD §2.1（v3.2）：默认同语言成稿，翻译是 pill 右侧开关（默认关）
  // 状态：录音中 → 成稿中（开关开=翻译中） → 预览（1.2s 可改） → 已落框
  // ============================================================
  function renderA() {
    els.hostTitle.textContent = "微信 · 给李总的消息";
    els.hostInput.value = "";
    els.hostInput.disabled = false;
    els.hostInput.placeholder = "按住 Fn 说话，松手成稿写进这里…";
    // v7.2：补 2 条上下文消息，让「已落框」回复有对话语境
    els.hostThread.innerHTML = `
      <div class="msg msg-them"><div class="msg-meta">李总 · 14:28</div><div class="msg-bubble">小陈，报价单我让财务核过了，没问题。</div></div>
      <div class="msg msg-them"><div class="msg-meta">李总 · 14:29</div><div class="msg-bubble">确认一下，这周能把合同定下来吗？</div></div>`;

    let transOn = false;   // 翻译开关（默认关：成稿为主，Typeless Dictate 范式）

    const STATES = ["录音中", "成稿中", "预览", "已落框"];

    setDemoControls(STATES, autoPlay, resetA);

    // 口语原话（演示输入）
    // 成稿结果（开关关）：同语言书面化，去口头禅、理逻辑
    const draftZh = "那个报价我确认没问题，下周三之前可以签合同。";
    const finalZh = "那个报价我确认没问题，下周三之前可以把合同签了。";
    // 翻译结果（开关开）：中→英（双语写回可配，演示「仅译文」模式）
    const draftEn = "Confirmed, no problem with the quote. We can sign the contract before next Wednesday.";
    const finalEn = "Confirmed, no problem with the quote. We can sign the contract before next Wednesday.";

    // pill 右侧翻译开关（v7 新组件：PRD §2.1 关键规则①）
    function transSwitch() {
      return h("button", {
        class: `bar-trans-switch ${transOn ? "on" : ""}`,
        type: "button",
        title: "翻译开关：关=同语言成稿（默认），开=写入英文",
        "aria-pressed": String(transOn),
        onclick: () => { transOn = !transOn; barAt(currentStateIdx); },
      }, h("span", { class: "ts-label" }, "译"), h("span", { class: "ts-track", "aria-hidden": "true" }, h("span", { class: "ts-thumb" })));
    }

    function barAt(stateIdx) {
      cancelDemo();
      clear(els.overlay);
      const bar = h("div", { class: "bar bar-enter bar-pill", dataset: { state: stateIdx, trans: transOn ? "1" : "0" } });

      if (stateIdx === 0) {
        // 录音中
        bar.append(
          h("span", { class: "mic-dot", "aria-hidden": "true" }),
          h("span", { class: "bar-wave", "aria-hidden": "true" }, ...Array.from({ length: 10 }, () => h("span"))),
          h("span", { class: "bar-text", dataset: { lang: "zh" } }, h("span", { class: "chars" }, "0:02")),
          transSwitch(),
        );
      } else if (stateIdx === 1) {
        // 成稿中（开关开时显示「翻译中」）；ADR-008：处理态取消操作可见
        bar.append(
          h("span", { class: "bar-spinner", "aria-hidden": "true" }),
          h("span", { class: "bar-text" }, transOn ? "翻译中…" : "成稿中…", h("span", { class: "chars" }, " 已输出 8 字")),
          h("span", { class: "bar-action" }, "Esc 取消"),
          transSwitch(),
        );
      } else if (stateIdx === 2) {
        // 预览：1.2s 窗口（成稿文本 / 译文）
        bar.classList.add("bar-preview");
        bar.append(
          h("span", { class: "bar-text text-fade-in" }, transOn ? draftEn : draftZh, h("span", { class: "bar-cursor" })),
          h("span", { class: "bar-action" }, "✓ 1.2s"),
          h("span", { class: "bar-action" }, "✗ 重说"),
          transSwitch(),
        );
      } else if (stateIdx === 3) {
        // 已落框：bar 淡出，textarea 显示成稿（/译文）
        els.hostInput.value = transOn ? finalEn : finalZh;
        bar.append(
          h("span", { class: "mic-dot", style: { background: "var(--success)", boxShadow: "0 0 0 4px rgba(43,164,113,0.2)" }, "aria-hidden": "true" }),
          h("span", { class: "bar-text" }, transOn ? "✓ 已写入输入框 · 中→EN" : "✓ 已写入输入框 · 成稿"),
        );
        // bar 1.5s 后自动淡出
        schedule(() => {
          bar.classList.add("bar-exit");
          schedule(() => bar.remove(), 250);
        }, 1500);
      }

      els.overlay.appendChild(bar);
      currentStateIdx = stateIdx;
      updateControlsActive();
    }

    function autoPlay() {
      // 自动循环：0 → 1 → 2 → 3
      barAt(0);
      schedule(() => barAt(1), 1800);
      schedule(() => barAt(2), 3400);
      schedule(() => barAt(3), 5400);
    }

    function resetA() {
      els.hostInput.value = "";
      clear(els.overlay);
      currentStateIdx = 0;
      updateControlsActive();
    }

    window.__runState = barAt;
    autoPlay();
    showHint("按住 Fn 说话 → 松手成稿写进输入框；pill 右侧「译」开关打开即中→英（PRD §2.1）", 4600);
  }

  // ============================================================
  // 流程 B · 悬浮窗输入翻译
  // PRD §2.2：鼠标旁的迷你窗
  // 状态：触发 → 加载 → 流式输出 → 完成（可复制 / 注入）
  // ============================================================
  function renderB() {
    els.hostTitle.textContent = "Slack · 工程频道";
    els.hostInput.value = "本周三之前能敲定报价吗？合同下周五前要签。";
    els.hostThread.innerHTML = `
      <div class="msg msg-them">
        <div class="msg-meta">Daniel · 14:28</div>
        <div class="msg-bubble">Hi Kevin, can you confirm the quote by Wednesday? We want to sign the contract before next Friday.</div>
      </div>`;

    const STATES = ["触发", "加载", "流式", "完成"];
    const sourceText = "本周三之前能敲定报价吗？合同下周五前要签。";
    const fullTarget = "Can we finalize the quote by this Wednesday? The contract needs to be signed by next Friday.";

    setDemoControls(STATES, runB, resetB);

    function miniAt(stateIdx) {
      cancelDemo();
      clear(els.overlay);
      const mini = h("div", { class: "mini-window mini-window-enter", style: { top: "40%", left: "55%" } });

      const head = h("div", { class: "mini-head" },
        h("span", { class: "mini-lang" }, "中", h("button", { type: "button" }, "→"), " English"),
        h("span", { style: { color: "var(--text-2)", fontSize: "11px" } }, "Ollama · qwen2.5:7b · 0ms"),
      );
      mini.appendChild(head);

      const src = h("div", { class: "mini-source" }, sourceText);
      mini.appendChild(src);

      const tgt = h("div", { class: "mini-target" });
      if (stateIdx === 0) {
        tgt.textContent = "…";
        tgt.style.color = "var(--text-3)";
      } else if (stateIdx === 1) {
        tgt.appendChild(h("span", { class: "bar-spinner", style: { width: "12px", height: "12px" } }));
        tgt.appendChild(document.createTextNode(" 翻译中…"));
      } else if (stateIdx === 2) {
        // 流式：先显示部分，然后展开
        tgt.classList.add("mini-streaming");
        tgt.innerHTML = `<span class="streamed-text">Can we finalize the quote by this Wed</span><span class="bar-cursor"></span>`;
      } else if (stateIdx === 3) {
        tgt.textContent = fullTarget;
        tgt.classList.add("text-fade-in");
      }
      mini.appendChild(tgt);

      const foot = h("div", { class: "mini-foot" },
        h("div", { class: "mini-actions" },
          h("button", { type: "button", title: "复制" }, icon("copy", "sm"), "复制"),
          h("button", { type: "button", title: "替换输入框" }, icon("inject", "sm"), "注入"),
          h("button", { type: "button", class: "primary", title: "关闭" }, icon("check", "sm"), "完成"),
        ),
        h("span", { style: { color: "var(--text-3)" } }, stateIdx === 3 ? "178ms · 0 ¥" : "…"),
      );
      mini.appendChild(foot);

      els.overlay.appendChild(mini);
      currentStateIdx = stateIdx;
      updateControlsActive();
    }

    function runB() {
      miniAt(0);
      schedule(() => miniAt(1), 600);
      schedule(() => miniAt(2), 1500);
      schedule(() => miniAt(3), 3500);
    }

    function resetB() {
      els.hostInput.value = "本周三之前能敲定报价吗？合同下周五前要签。";
      clear(els.overlay);
      currentStateIdx = 0;
      updateControlsActive();
    }

    window.__runState = miniAt;
    runB();
    showHint("⌥ Space 唤起悬浮窗 · 流式输出 · 1 键注入到输入框", 4000);
  }

  // ============================================================
  // 流程 C · 划词翻译
  // PRD §2.3：选区上浮水印小窗
  // 状态：选词 → 渲染小窗 → 翻译 → 完成
  // ============================================================
  function renderC() {
    els.hostTitle.textContent = "Chrome · Medium 文章";
    els.hostInput.value = "请阅读以下段落并标记术语。";
    els.hostThread.innerHTML = `
      <div style="padding:24px;font-size:14px;line-height:1.7;max-width:520px">
        <h2 style="margin:0 0 12px;font-size:18px">Why useEffect Cleanup Matters</h2>
        <p style="color:var(--text-2);margin:0 0 8px">Many developers <span style="background:rgba(99,102,241,0.18);padding:0 2px;border-radius:3px" id="selWord">forget to unsubscribe</span> from event listeners. This causes <em>memory leaks</em> in single-page apps.</p>
        <p style="color:var(--text-2);margin:0">A proper cleanup function returns from useEffect. Most teams use a linter to enforce this.</p>
      </div>`;

    const STATES = ["选词", "弹窗", "翻译", "替换"];
    const word = "forget to unsubscribe";
    const translation = "忘记取消订阅";

    setDemoControls(STATES, runC, resetC);

    function cAt(stateIdx) {
      cancelDemo();
      clear(els.overlay);

      if (stateIdx >= 1) {
        const marker = h("span", { class: "selection-marker", style: { top: "calc(40% + 24px)", left: "calc(40% + 20px)" } }, "译");
        els.overlay.appendChild(marker);
      }

      if (stateIdx >= 2) {
        const pop = h("div", { class: "translate-popover mini-window-enter", style: { top: "calc(40% + 50px)", left: "calc(40% + 20px)" } },
          h("div", { class: "tp-head" },
            h("span", { class: "tp-pair" }, "EN → ZH"),
            h("span", { style: { color: "var(--text-3)" } }, stateIdx === 3 ? "68ms" : "…"),
          ),
          h("div", { class: "tp-row tp-source" }, word),
          h("div", { class: "tp-row tp-target" }, stateIdx === 2 ? "忘记取消订" : translation),
          h("div", { class: "tp-foot" },
            h("button", { type: "button" }, icon("copy", "sm"), "复制"),
            h("button", { type: "button", class: "primary" }, icon("swap", "sm"), "替换"),
          ),
        );
        els.overlay.appendChild(pop);
      }

      currentStateIdx = stateIdx;
      updateControlsActive();
    }

    function runC() {
      cAt(0);
      schedule(() => cAt(1), 700);
      schedule(() => cAt(2), 1700);
      schedule(() => cAt(3), 3000);
    }

    function resetC() {
      clear(els.overlay);
      currentStateIdx = 0;
      updateControlsActive();
    }

    window.__runState = cAt;
    runC();
    showHint("⌥ D 选词 → 弹窗 → ⤓ 替换原文", 4000);
  }

  // ============================================================
  // 流程 D · 静默替换
  // PRD §2.4：在任意输入框里写中文，自动替换为英文，不弹窗
  // 状态：打字 → 翻译 → 替换（焦点切换终止）
  // ============================================================
  function renderD() {
    els.hostTitle.textContent = "Chrome · GitHub Issue 评论";
    els.hostInput.value = "";
    els.hostThread.innerHTML = `
      <div style="padding:20px;font-size:13px;line-height:1.7">
        <div style="color:var(--text-2);margin-bottom:8px">#1827 · Add dark mode toggle</div>
        <p style="color:var(--text);margin:0 0 12px">需要给页面添加一个深色模式开关，移动端也要考虑。</p>
      </div>`;

    const STATES = ["打字中", "翻译中", "替换"];
    const original = "需要给页面添加一个深色模式开关";
    const translated = "Add a dark mode toggle to the page";

    setDemoControls(STATES, runD, resetD);

    function dAt(stateIdx) {
      cancelDemo();
      clear(els.overlay);

      if (stateIdx === 0) {
        // 用户正在打字
        els.hostInput.value = original;
        const bar = h("div", { class: "silent-bar bar-enter" },
          h("span", { class: "dot", style: { background: "var(--brand)" } }),
          h("span", { class: "progress-text" }, "静默模式 · 监听输入…"),
        );
        els.overlay.appendChild(bar);
      } else if (stateIdx === 1) {
        const bar = h("div", { class: "silent-bar bar-enter" },
          h("span", { class: "spinner", "aria-hidden": "true" }),
          h("span", { class: "progress-text" }, "翻译中 · 已处理 ", h("strong", null, original.length), " / ", h("strong", null, original.length), " 字"),
        );
        els.overlay.appendChild(bar);
      } else if (stateIdx === 2) {
        els.hostInput.value = translated;
        els.hostInput.classList.add("text-fade-in");
        const bar = h("div", { class: "silent-bar bar-enter" },
          h("span", { class: "dot ok", "aria-hidden": "true" }),
          h("span", { class: "progress-text" }, "✓ 已替换（", h("strong", null, "1.2s"), " 内静默写入）"),
          h("button", { type: "button" }, icon("rotate", "sm"), "撤回"),
        );
        els.overlay.appendChild(bar);
        schedule(() => {
          bar.classList.add("bar-exit");
          schedule(() => bar.remove(), 250);
        }, 2500);
      }

      currentStateIdx = stateIdx;
      updateControlsActive();
    }

    function runD() {
      dAt(0);
      schedule(() => dAt(1), 1400);
      schedule(() => dAt(2), 2700);
    }

    function resetD() {
      els.hostInput.value = "";
      els.hostInput.classList.remove("text-fade-in");
      clear(els.overlay);
      currentStateIdx = 0;
      updateControlsActive();
    }

    window.__runState = dAt;
    runD();
    showHint("⌥ ↩ 在任意输入框静默替换 · 焦点切换即终止", 4000);
  }

  // ============================================================
  // 流程 E · 截图 OCR
  // PRD §2.5：框选 + 双栏窗
  // 状态：框选 → 识别 → 双栏展示
  // ============================================================
  function renderE() {
    els.hostTitle.textContent = "PDF · 合同节选";
    els.hostInput.value = "";
    els.hostThread.innerHTML = `
      <div style="padding:24px;font-size:13px;line-height:1.7;color:var(--text);background:#FAFAFA;margin:16px;border-radius:8px;border:1px solid var(--divider);height:100%;box-sizing:border-box">
        <h3 style="margin:0 0 12px;font-size:14px">ARTICLE 3 · DELIVERY TERMS</h3>
        <p style="margin:0 0 8px">3.1 <strong>The Seller shall deliver the Goods within thirty (30) business days</strong> after receipt of the Purchase Order.</p>
        <p style="margin:0 0 8px">3.2 Risk of loss passes to the Buyer upon delivery to the carrier.</p>
        <p style="margin:0">3.3 Late delivery exceeding seven (7) days entitles the Buyer to terminate without penalty.</p>
      </div>`;

    const STATES = ["框选", "OCR 识别", "双栏结果"];
    const source = "The Seller shall deliver the Goods within thirty (30) business days after receipt of the Purchase Order.";
    const target = "卖方应在收到采购订单后 30 个工作日内交付货物。";

    setDemoControls(STATES, runE, resetE);

    function eAt(stateIdx) {
      cancelDemo();
      clear(els.overlay);

      if (stateIdx >= 1) {
        const mask = h("div", { class: "ocr-mask" });
        const rect = h("div", { class: "ocr-rect", dataset: { size: "536 × 168" } });
        els.overlay.append(mask, rect);
      }

      if (stateIdx >= 2) {
        const result = h("div", { class: "ocr-result mini-window-enter" },
          h("div", { class: "ocr-col" },
            h("div", { class: "ocr-col-label" },
              h("span", null, "原文"),
              h("button", { type: "button" }, icon("copy", "sm"), "复制"),
            ),
            h("div", { class: "ocr-col-body ocr-source" }, source),
          ),
          h("div", { class: "ocr-col" },
            h("div", { class: "ocr-col-label" },
              h("span", null, "译文 · 中文"),
              h("button", { type: "button" }, icon("copy", "sm"), "复制"),
            ),
            h("div", { class: "ocr-col-body ocr-target" }, target),
          ),
          h("div", { style: { display: "flex", gap: "6px", marginTop: "8px" } },
            h("button", { type: "button", class: "settings-btn ghost full" }, icon("inject", "sm"), " 注入"),
            h("button", { type: "button", class: "settings-btn primary full" }, icon("check", "sm"), " 完成"),
          ),
        );
        els.overlay.appendChild(result);
      } else if (stateIdx === 1) {
        // OCR 扫描中
        const scanning = h("div", { class: "ocr-result mini-window-enter", style: { opacity: "0.9" } },
          h("div", { class: "ocr-col" },
            h("div", { class: "ocr-col-label" },
              h("span", null, "识别中…"),
              h("span", { style: { color: "var(--text-3)" } }, "Mistral OCR · 1.2s"),
            ),
            h("div", { class: "ocr-col-body ocr-source", style: { color: "var(--text-3)" } },
              h("span", { class: "bar-spinner", style: { width: "12px", height: "12px", display: "inline-block", verticalAlign: "middle", marginRight: "6px" } }),
              "扫描中…",
            ),
          ),
        );
        els.overlay.appendChild(scanning);
      }

      currentStateIdx = stateIdx;
      updateControlsActive();
    }

    function runE() {
      eAt(0);
      schedule(() => eAt(1), 1200);
      schedule(() => eAt(2), 2700);
    }

    function resetE() {
      clear(els.overlay);
      currentStateIdx = 0;
      updateControlsActive();
    }

    window.__runState = eAt;
    runE();
    showHint("⌥ S 截图 OCR · 框选 · 双栏展示", 4000);
  }

  // ============================================================
  // 流程 F · 隐私锁
  // PRD §6.2：离开时锁定主窗，回时需 FaceID/密码
  // 状态：已解锁 → 离开设备 → 自动锁定 → FaceID → 已解锁
  // ============================================================
  function renderF() {
    els.hostTitle.textContent = "译语 · 主窗口";
    els.hostInput.value = "如果你 1 分钟没动电脑，主窗口会被锁屏。";
    els.hostThread.innerHTML = `
      <div style="padding:32px 24px;text-align:center">
        <div style="margin:0 auto 12px;width:56px;height:56px;border-radius:16px;background:var(--brand-grad);color:#fff;display:flex;align-items:center;justify-content:center"><svg viewBox="0 0 24 24" width="26" height="26" fill="none" stroke="currentColor" stroke-width="1.7" stroke-linecap="round" stroke-linejoin="round"><path d="M12 2.5 20 6v5c0 5-3.4 8.9-8 10.5C7.4 19.9 4 16 4 11V6z"/><path d="M8.5 11.5l2.4 2.4 4.6-4.8"/></svg></div>
        <div style="font-size:16px;font-weight:600;margin-bottom:8px">隐私锁已激活</div>
        <div style="color:var(--text-2);font-size:13px;margin-bottom:16px">所有调用本地化 · 离开超过 1 分钟锁定</div>
        <div style="display:flex;gap:8px;justify-content:center">
          <span class="badge live">FaceID</span>
          <span class="badge">密码</span>
          <span class="badge">TouchID</span>
        </div>
      </div>`;

    const STATES = ["已解锁", "离开设备", "自动锁定", "FaceID 解锁"];

    setDemoControls(STATES, runF, resetF);

    function fAt(stateIdx) {
      cancelDemo();
      clear(els.overlay);

      if (stateIdx === 0) {
        const banner = h("div", { class: "privacy-banner bar-enter" },
          h("span", { class: "pb-icon", "aria-hidden": "true" }, icon("shieldCheck", "sm")),
          h("div", null,
            h("div", { class: "pb-title" }, "隐私锁 · 已解锁"),
            h("div", { class: "pb-sub" }, "FaceID 已通过 · 本地无密钥缓存"),
          ),
          h("button", { type: "button" }, "立即锁定"),
        );
        els.overlay.appendChild(banner);
      } else if (stateIdx === 1) {
        const banner = h("div", { class: "privacy-banner bar-enter warn" },
          h("span", { class: "pb-icon", "aria-hidden": "true" }, icon("clock", "sm")),
          h("div", null,
            h("div", { class: "pb-title" }, "检测到离开设备"),
            h("div", { class: "pb-sub" }, "Mac 合盖 / 屏幕保护程序已触发 · 倒计时 60s"),
          ),
          h("div", { class: "countdown" }, "60s"),
        );
        els.overlay.appendChild(banner);
      } else if (stateIdx === 2) {
        // 整个主舞台被锁定层覆盖
        const lock = h("div", { class: "lock-screen" },
          h("div", { class: "lock-bg", "aria-hidden": "true" }),
          h("div", { class: "lock-card" },
            h("div", { class: "lock-icon", "aria-hidden": "true" }),
            h("div", { class: "lock-brand" }, "译语"),
            h("div", { class: "lock-title" }, "主窗口已锁定"),
            h("div", { class: "lock-sub" }, "调用记录、配置、术语表已隐藏"),
            h("div", { class: "lock-face" },
              h("div", { class: "lock-face-icon", "aria-hidden": "true" }),
              h("div", null,
                h("div", { class: "lock-face-title" }, "FaceID 解锁"),
                h("div", { class: "lock-face-sub" }, "正在扫描…"),
              ),
              h("div", { class: "lock-dot" }),
            ),
            h("button", { type: "button", class: "lock-alt" }, "或输入密码"),
          ),
        );
        els.overlay.appendChild(lock);
      } else if (stateIdx === 3) {
        // 解锁中
        const banner = h("div", { class: "privacy-banner bar-enter success" },
          h("span", { class: "pb-icon", "aria-hidden": "true" }, icon("check", "sm")),
          h("div", null,
            h("div", { class: "pb-title" }, "FaceID 验证通过"),
            h("div", { class: "pb-sub" }, "解锁耗时 320ms · 未发送任何遥测"),
          ),
          h("span", { class: "pb-pill" }, "已解锁"),
        );
        els.overlay.appendChild(banner);
        schedule(() => {
          banner.classList.add("bar-exit");
          schedule(() => banner.remove(), 250);
        }, 2200);
      }

      currentStateIdx = stateIdx;
      updateControlsActive();
    }

    function runF() {
      fAt(0);
      schedule(() => fAt(1), 1500);
      schedule(() => fAt(2), 3300);
      schedule(() => fAt(3), 6000);
    }

    function resetF() {
      clear(els.overlay);
      currentStateIdx = 0;
      updateControlsActive();
    }

    window.__runState = fAt;
    runF();
    showHint("⌥⇧K 立即锁屏 · FaceID 验证 · 零遥测", 4000);
  }

  // ============================================================
  // 流程 G · 移动端键盘
  // PRD §5：iOS / Android 集成系统键盘，工具栏 + 语音按钮
  // 状态：键盘展开 → 选语种 → 输入 → 翻译 → 候选词
  // ============================================================
  function renderG() {
    els.hostTitle.textContent = "iOS · 微信聊天";
    els.hostInput.value = "我们下周三之前能敲定吗？";
    els.hostThread.innerHTML = `
      <div style="display:flex;flex-direction:column;gap:8px;padding:16px 12px;height:100%;box-sizing:border-box;background:linear-gradient(180deg,#fff 0%,#f5f5f5 100%)">
        <div style="font-size:11px;color:#999;text-align:center">微信 · 给 Daniel</div>
        <div style="background:#95EC69;align-self:flex-end;padding:10px 12px;border-radius:8px;font-size:14px;max-width:75%;color:#000">如果价格合适，我们愿意直接推进。</div>
        <div style="background:#fff;align-self:flex-start;padding:10px 12px;border-radius:8px;font-size:14px;max-width:75%;color:#000;border:1px solid #eee">Great, let's set up a call.</div>
      </div>`;

    const STATES = ["键盘展开", "选语种", "输入", "翻译中", "候选词"];
    const original = "下周三能签吗？";
    const translated = "Can we sign it by next Wednesday?";

    setDemoControls(STATES, runG, resetG);

    function gAt(stateIdx) {
      cancelDemo();
      clear(els.overlay);

      const phoneFrame = h("div", { class: "phone-frame" },
        h("div", { class: "phone-notch", "aria-hidden": "true" }),
        h("div", { class: "phone-status" }, "9:41"),
        h("div", { class: "phone-host" },
          // v7.2 修复：用 innerHTML 传参（字符串 child 会被 h() 当文本节点，导致源码显示）
          h("div", { class: "phone-thread", innerHTML: els.hostThread.innerHTML }),
          h("div", { class: "phone-input-row" },
            h("button", { class: "phone-mic", type: "button", "aria-label": "语音" }, icon("mic")),
            h("input", { type: "text", class: "phone-input", placeholder: "消息", value: stateIdx >= 2 ? original : "" }),
            h("button", { class: "phone-emoji", type: "button", "aria-label": "表情" }, icon("smile")),
          ),
        ),
      );

      // 键盘层
      const keyboard = h("div", { class: "phone-keyboard" });

      // 顶部工具栏
      const toolbar = h("div", { class: "phone-toolbar" },
        h("div", { class: "phone-toolbar-lang" },
          h("button", { type: "button", class: "lang-chip", dataset: { active: stateIdx >= 1 } }, "中"),
          h("button", { type: "button", class: "lang-chip" }, "EN"),
          h("button", { type: "button", class: "lang-arrow", "aria-hidden": "true" }, "⇄"),
          h("button", { type: "button", class: "lang-chip" }, "日"),
        ),
        h("div", { class: "phone-toolbar-mid" },
          stateIdx === 2 ? h("span", { class: "phone-typing" }, "正在输入：", h("strong", null, original)) : null,
          stateIdx === 3 ? h("span", { class: "phone-typing warn" }, "翻译中…") : null,
          stateIdx === 4 ? h("span", { class: "phone-typing ok" }, "✓ 候选就绪") : null,
        ),
        h("div", { class: "phone-toolbar-right" },
          h("button", { type: "button", title: "语种表" }, icon("globe")),
          h("button", { type: "button", title: "术语表" }, icon("book")),
          h("button", { type: "button", title: "历史" }, icon("clock")),
        ),
      );
      keyboard.appendChild(toolbar);

      // 候选词栏（仅翻译后）
      if (stateIdx >= 4) {
        const candidates = h("div", { class: "phone-candidates" },
          h("span", { class: "cand-label" }, "译"),
          h("button", { type: "button", class: "cand" }, translated),
          h("button", { type: "button", class: "cand small" }, "Can we sign by next Wed?"),
          h("button", { type: "button", class: "cand small" }, "Shall we sign by next Wed?"),
          h("span", { class: "cand-action" }, "插入"),
        );
        keyboard.appendChild(candidates);
      }

      // 键盘本体（QWERTY 简化）
      const keys = [
        ["q","w","e","r","t","y","u","i","o","p"],
        ["a","s","d","f","g","h","j","k","l"],
        ["z","x","c","v","b","n","m"],
      ];
      const kbBody = h("div", { class: "phone-kb-body" });
      keys.forEach((row, ri) => {
        const r = h("div", { class: "phone-kb-row" });
        if (ri === 2) r.appendChild(h("button", { type: "button", class: "phone-kb-shift" }, "⇧"));
        row.forEach((k) => r.appendChild(h("button", { type: "button", class: "phone-kb-key" }, k)));
        if (ri === 2) r.appendChild(h("button", { type: "button", class: "phone-kb-backspace" }, "⌫"));
        kbBody.appendChild(r);
      });
      const kbBottom = h("div", { class: "phone-kb-row bottom" },
        h("button", { type: "button", class: "phone-kb-num" }, "123"),
        h("button", { type: "button", class: "phone-kb-space" }, "space"),
        h("button", { type: "button", class: "phone-kb-enter" }, "发送"),
      );
      kbBody.appendChild(kbBottom);
      keyboard.appendChild(kbBody);

      phoneFrame.appendChild(keyboard);

      if (stateIdx === 0) {
        // 刚开始：键盘从底部升起
        keyboard.classList.add("phone-keyboard-enter");
      }
      els.overlay.appendChild(phoneFrame);

      currentStateIdx = stateIdx;
      updateControlsActive();
    }

    function runG() {
      gAt(0);
      schedule(() => gAt(1), 1500);
      schedule(() => gAt(2), 3000);
      schedule(() => gAt(3), 4500);
      schedule(() => gAt(4), 6000);
    }

    function resetG() {
      clear(els.overlay);
      currentStateIdx = 0;
      updateControlsActive();
    }

    window.__runState = gAt;
    runG();
    showHint("iOS 系统键盘扩展 · 中英日瞬切（Android 键盘见 Tab O）", 4000);
  }

  // ============================================================
  // v6 共用 · 设置主窗左侧导航（Tab H/I/J/K 整页模式）
  // 侧边项可点击直达对应演示 Tab（PRD §5.3 ④）
  // ============================================================
  function buildSideNav(activeKey) {
    const link = (key, ico, label) =>
      h("button", {
        class: `mw-side-link ${activeKey === key ? "active" : ""}`,
        type: "button",
        onclick: key !== activeKey ? () => switchTab(key) : undefined,
      }, h("span", { class: "lk-ico" }, ico), label);

    return h("div", { class: "mw-sidebar" },
      h("div", { class: "mw-side-title" }, h("span", { class: "mw-side-logo" }, "译"), "译语"),
      link("H", icon("home"), "首页 · 历史与用量"),
      link("I", icon("chip"), "模型配置"),
      link("J", icon("cmd"), "快捷键"),
      link("K", icon("sparkles"), "偏好 / 术语 / Skills"),
      h("div", { class: "mw-side-sep" }),
      link("F", icon("shield"), "隐私安全"),
      link("L", icon("compass"), "首次引导"),
      h("div", { class: "mw-side-sep" }),
      h("button", { class: "mw-side-link", type: "button", onclick: () => switchTab("A") }, h("span", { class: "lk-ico" }, icon("mic")), "回到语音输入"),
    );
  }

  // ============================================================
  // v6 · Tab H · 主窗口首页（历史 + 用量统计）
  // PRD §6 #6；状态：列表 + 用量 / 空状态
  // ============================================================
  function renderH() {
    els.hostTitle.textContent = "译语 · 主窗口 — 首页";
    els.hostInput.value = "";

    const STATES = ["列表 + 用量", "空状态（首次使用）"];
    setDemoControls(STATES, null, () => hAt(0));

    const HISTORY = [
      { time: "14:32", dir: "中→英", src: "那个报价我确认没问题，下周三之前可以签合同。", tgt: "Confirmed, no problem with the quote. We can sign before next Wednesday.", meta: "86 字 · 1.1s", from: "A" },
      { time: "14:21", dir: "中→英", src: "本周三之前能敲定报价吗？", tgt: "Can we finalize the quote by this Wednesday?", meta: "38 字 · 0.9s", from: "B" },
      { time: "13:58", dir: "英→中", src: "forget to unsubscribe", tgt: "忘记取消订阅", meta: "3 词 · 0.3s", from: "C" },
      { time: "13:41", dir: "中→英", src: "需要给页面添加一个深色模式开关", tgt: "Add a dark mode toggle to the page", meta: "31 字 · 1.0s", from: "D" },
      { time: "11:20", dir: "OCR", src: "The Seller shall deliver the Goods within thirty (30) business days…", tgt: "卖方应在收到采购订单后 30 个工作日内交付货物。", meta: "112 字 · 2.4s", from: "E" },
      { time: "10:07", dir: "中→英", src: "发票抬头请写：译语科技有限公司", tgt: "Please make the invoice out to LinguaFlow Technology Co., Ltd.", meta: "52 字 · 1.2s", from: "A" },
    ];

    function hAt(stateIdx) {
      cancelDemo();
      clear(els.overlay);
      els.hostThread.innerHTML = "";

      const content = h("div", { class: "mw-content" });
      if (stateIdx === 1) {
        content.append(
          h("div", { class: "mw-h1" }, "首页"),
          h("div", { class: "mw-sub" }, "历史记录 · 用量统计（本地保存，不上传）"),
          h("div", { class: "empty-state" },
            h("div", { class: "empty-icon" }, icon("mic")),
            h("div", { class: "empty-title" }, "还没有任何记录"),
            h("div", { class: "empty-sub" }, "按住 Fn 说一句话，或用 ⌥Space 悬浮窗输入；历史与用量统计会出现在这里。绝不白屏：未配置模型时会先引导本地模型试用。"),
            h("button", { class: "settings-btn primary", type: "button", style: { width: "auto", padding: "8px 18px" }, onclick: () => switchTab("L") }, "先去完成首次引导"),
          ),
        );
      } else {
        content.append(
          h("div", { class: "mw-h1" }, "首页"),
          h("div", { class: "mw-sub" }, "历史记录 · 用量统计（本地保存，不上传）"),
          h("div", { class: "stat-cards" },
            h("div", { class: "stat-card" }, h("div", { class: "stat-num" }, "42", h("small", null, "次")), h("div", { class: "stat-label" }, "今日调用")),
            h("div", { class: "stat-card" }, h("div", { class: "stat-num" }, "128.4", h("small", null, "K tok")), h("div", { class: "stat-label" }, "本月 token")),
            h("div", { class: "stat-card" }, h("div", { class: "stat-num" }, "¥6.42"), h("div", { class: "stat-label" }, "本月预估花费")),
            h("div", { class: "stat-card" }, h("div", { class: "stat-num" }, "480", h("small", null, "ms")), h("div", { class: "stat-label" }, "平均首字延迟")),
          ),
          h("div", { class: "mw-h2" }, "用量 · token 趋势（天 / 周 / 月）"),
          h("div", { class: "usage-toggle" },
            h("button", { class: "active", type: "button" }, "天"),
            h("button", { type: "button" }, "周"),
            h("button", { type: "button" }, "月"),
          ),
          h("div", { class: "usage-chart" },
            ...[["周一", 34], ["周二", 52], ["周三", 41], ["周四", 66], ["周五", 58], ["周六", 22], ["今日", 47]].map(([d, v]) =>
              h("div", { class: "chart-col" },
                h("span", { class: "chart-val" }, String(v)),
                h("div", { class: "chart-bar", style: { height: `${v}%` } }),
                h("span", { class: "chart-day" }, d),
              )
            ),
          ),
          h("div", { class: "mw-h2" }, "历史记录（点行可回看 · 支持收藏 / 复制 / 重新注入）"),
          h("div", { class: "history-list" },
            ...HISTORY.map((r) =>
              h("button", { class: "history-row", type: "button", onclick: () => showHint("回看详情（演示：字段见 pages-specs / T-012）", 2400) },
                h("span", { class: "hr-time" }, r.time),
                h("span", { class: "dir-badge" }, r.dir),
                h("span", { class: "hr-text" },
                  h("span", { class: "hr-src" }, r.src),
                  h("span", { class: "hr-arrow" }, "→"),
                  h("span", { class: "hr-tgt" }, r.tgt),
                ),
                h("span", { class: "src-pill" }, `流程 ${r.from}`),
                h("span", { class: "hr-meta" }, r.meta),
              )
            ),
          ),
        );
      }

      els.hostThread.appendChild(h("div", { class: "page-view" }, buildSideNav("H"), content));
      currentStateIdx = stateIdx;
      updateControlsActive();
    }

    window.__runState = hAt;
    hAt(0);
    showHint("主窗首页：左侧导航直达各设置页 · 用量按天/周/月（B.2 验收项）", 4200);
  }

  // ============================================================
  // v6 · Tab I · 模型配置（灵魂页面）
  // PRD §6 #7、§5.3 ④；状态：空 / 已配 / 新增 / 测试中→失败
  // ============================================================
  function renderI() {
    els.hostTitle.textContent = "译语 · 模型配置";
    els.hostInput.value = "";

    const STATES = ["空态（未配置）", "已配置列表", "新增 Provider", "测试中 → 失败"];
    setDemoControls(STATES, null, () => iAt(0));

    const PLATS = [
      { name: "OpenAI", logo: "O", bg: "#10A37F", tag: "gpt-4o 系" },
      { name: "Anthropic", logo: "C", bg: "#D97757", tag: "claude 系" },
      { name: "Gemini", logo: "G", bg: "#4285F4", tag: "gemini 系" },
      { name: "DeepSeek", logo: "D", bg: "#4D6BFE", tag: "deepseek-chat" },
      { name: "通义", logo: "通", bg: "#615CED", tag: "qwen 系" },
      { name: "火山方舟", logo: "火", bg: "#0D5EF4", tag: "doubao 系" },
      { name: "Ollama", logo: "O", bg: "#1A1A1A", tag: "本地 · 离线" },
      { name: "自定义", logo: "＋", bg: "#86909C", tag: "OpenAI 兼容" },
    ];

    const PROVIDERS = [
      { name: "OpenAI", model: "gpt-4o-mini · 342ms", logo: "O", bg: "#10A37F", live: true },
      { name: "Claude", model: "claude-sonnet-4 · 512ms", logo: "C", bg: "#D97757", live: true },
      { name: "Ollama（本地）", model: "qwen2.5:7b · 0ms", logo: "O", bg: "#1A1A1A", live: true },
    ];

    function iAt(stateIdx) {
      cancelDemo();
      clear(els.overlay);
      els.hostThread.innerHTML = "";

      const content = h("div", { class: "mw-content" });
      content.append(h("div", { class: "mw-h1" }, "模型配置"));
      content.append(h("div", { class: "mw-sub" }, "配置完全本地保存（系统密钥串）；请求直连模型方 BaseURL，不经我方服务器（ADR-001）。"));

      if (stateIdx === 0) {
        // 空态：绝不白屏 → 本地模型一键体验
        content.append(
          h("div", { class: "empty-state" },
            h("div", { class: "empty-icon" }, icon("chip")),
            h("div", { class: "empty-title" }, "还没有配置任何模型"),
            h("div", { class: "empty-sub" }, "添加一个 Provider（OpenAI 兼容 / Claude / Gemini / Ollama…），或先体验本地模型——无需任何 Key。"),
            h("div", { style: { display: "flex", gap: "8px" } },
              h("button", { class: "settings-btn primary", type: "button", style: { width: "auto", padding: "8px 18px" }, onclick: () => iAt(2) }, icon("plus", "sm"), " 添加 Provider"),
              h("button", { class: "settings-btn ghost", type: "button", style: { width: "auto", padding: "8px 18px" }, onclick: () => switchTab("L") }, "先用本地模型试用"),
            ),
          ),
        );
      } else {
        // 已配列表（② 状态公共部分）
        content.append(
          h("div", { class: "mw-h2" }, "当前默认"),
          h("div", { class: "current-model" },
            h("div", { class: "cm-logo" }, "O"),
            h("div", { class: "cm-info" },
              h("div", { class: "cm-name" }, "Ollama · qwen2.5:7b"),
              h("div", { class: "cm-meta" }, "本地 · 离线 · 零成本"),
            ),
            h("span", { class: "badge live" }, "在线"),
          ),
          h("div", { class: "mw-h2" }, "已添加的 Provider"),
          h("div", { class: "provider-list" },
            ...PROVIDERS.map((p) =>
              h("div", { class: "provider-row" },
                h("div", { class: "pr-logo", style: { background: p.bg } }, p.logo),
                h("div", { class: "pr-info" },
                  h("div", { class: "pr-name" }, p.name),
                  h("div", { class: "pr-host" }, p.model),
                ),
                h("span", { class: "dot ok", "aria-label": "健康" }),
              )
            ),
          ),
          h("button", { class: "settings-btn ghost full", type: "button", onclick: () => iAt(2) }, icon("plus", "sm"), " 添加 Provider"),
        );
      }

      if (stateIdx === 2 || stateIdx === 3) {
        // 新增 Provider：平台卡片网格 + 表单
        content.append(
          h("div", { class: "mw-h2" }, "选择平台"),
          h("div", { class: "plat-grid" },
            ...PLATS.map((p, i) =>
              h("button", { class: `plat-card ${i === 0 ? "selected" : ""}`, type: "button" },
                h("span", { class: "plat-logo", style: { background: p.bg } }, p.logo),
                h("span", { class: "plat-name" }, p.name),
                h("span", { class: "plat-tag" }, p.tag),
              )
            ),
          ),
          h("div", { class: "form-grid" },
            h("div", { class: "form-row" },
              h("label", { class: "form-label" }, "BaseURL", h("span", { class: "req" }, "*")),
              h("input", { class: "form-input", type: "text", value: "https://api.openai.com/v1", placeholder: "https://api.openai.com/v1 或自定义兼容端点" }),
              h("span", { class: "form-hint" }, "OpenAI 兼容协议；流量直连该地址，零遥测（ADR-001 §2）"),
            ),
            h("div", { class: "form-row" },
              h("label", { class: "form-label" }, "API Key", h("span", { class: "req" }, "*")),
              h("div", { class: "form-inline" },
                h("input", { class: "form-input", type: "password", value: "sk-proj-••••••••••••••••••••••••", placeholder: "sk-…" }),
                h("button", { class: "settings-btn ghost", type: "button", style: { width: "auto", padding: "8px 12px", marginTop: "0" } }, "显示"),
              ),
              h("span", { class: "form-hint" }, "存入系统密钥串（Keychain / DPAPI / libsecret），明文不落盘 · <a>如何申请 OpenAI Key？</a>"),
            ),
            h("div", { class: "form-row" },
              h("label", { class: "form-label" }, "模型"),
              h("div", { class: "form-inline" },
                h("select", { class: "select", style: { flex: "1" } },
                  h("option", null, "gpt-4o-mini"),
                  h("option", null, "gpt-4o"),
                  h("option", null, "o3-mini"),
                ),
                h("button", { class: "settings-btn ghost", type: "button", style: { width: "auto", padding: "8px 12px", marginTop: "0" } }, icon("refresh", "sm"), " 拉取模型列表"),
              ),
            ),
            stateIdx === 2
              ? h("button", { class: "settings-btn primary full", type: "button", onclick: () => iAt(3) }, "测试连接并保存")
              : null,
          ),
        );
      }

      if (stateIdx === 3) {
        // 测试中 → 失败（内联错误条，§7 异常处理）
        content.append(
          h("div", { style: { marginTop: "10px", display: "flex", flexDirection: "column", gap: "8px" } },
            h("div", { class: "settings-row" },
              h("span", { class: "settings-label" }, "测试连接"),
              h("span", { style: { display: "inline-flex", alignItems: "center", gap: "6px", color: "var(--text-2)", fontSize: "12px" } },
                h("span", { class: "bar-spinner", style: { width: "12px", height: "12px" } }), "请求中… https://api.openai.com/v1/models"),
            ),
            h("div", { class: "inline-error" },
              h("span", { class: "ie-icon" }, icon("x", "sm")),
              h("div", { class: "ie-body" },
                h("div", { class: "ie-title" }, "测试失败 · 401 Invalid API Key"),
                h("div", null, "模型方返回：Incorrect API key provided. 请检查 Key 是否复制完整、账号是否欠费。"),
                h("div", { style: { marginTop: "4px" } },
                  h("span", { class: "ie-link", onclick: () => iAt(2) }, "→ 返回修改 Key"),
                  "　",
                  h("span", { class: "ie-link", onclick: () => switchTab("L") }, "→ 先用本地模型试用"),
                ),
              ),
            ),
          ),
        );
      }

      els.hostThread.appendChild(h("div", { class: "page-view" }, buildSideNav("I"), content));
      currentStateIdx = stateIdx;
      updateControlsActive();
    }

    window.__runState = iAt;
    iAt(1);
    showHint("灵魂页面：8 平台卡片 + BaseURL/Key/模型下拉 + 测试连接四态（DoD B.2）", 4200);
  }

  // ============================================================
  // v6 · Tab J · 快捷键设置
  // PRD §6 #8、§4；状态：已绑定 / 冲突检测 / 重绑录制中
  // ============================================================
  function renderJ() {
    els.hostTitle.textContent = "译语 · 快捷键设置";
    els.hostInput.value = "";

    const STATES = ["已绑定", "冲突检测", "重绑录制中"];
    setDemoControls(STATES, null, () => jAt(0));

    const KEYS = [
      { label: "按住说话（流程 A）", mac: "按住 Fn", win: "按住 Fn", conflict: false },
      { label: "唤起悬浮窗（流程 B）", mac: "⌥ Space", win: "Alt Space", conflict: false },
      { label: "划词翻译（流程 C）", mac: "⌥ D", win: "Ctrl Alt D", conflict: false },
      { label: "静默替换（流程 D）", mac: "⌥ ↩", win: "Ctrl Alt ↩", conflict: false },
      { label: "截图 OCR（流程 E）", mac: "⌥ S", win: "Ctrl Alt S", conflict: true, with: "macOS 截屏 ⌥⇧S" },
      { label: "打开主窗口", mac: "双击 ⌥", win: "双击 Ctrl", conflict: false },
      { label: "临时禁用全部热键", mac: "⌥ ⇧ P", win: "Ctrl Alt P", conflict: false },
      { label: "隐私锁", mac: "⌥ ⇧ K", win: "Ctrl Alt K", conflict: false },
    ];

    function jAt(stateIdx) {
      cancelDemo();
      clear(els.overlay);
      els.hostThread.innerHTML = "";

      const content = h("div", { class: "mw-content" });
      content.append(
        h("div", { class: "mw-h1" }, "快捷键"),
        h("div", { class: "mw-sub" }, "全部可重绑，实时冲突检测；唤起键单次触发、语音键按住触发，两类手感必须区分（PRD §4）。"),
      );

      if (stateIdx === 2) {
        content.append(
          h("div", { class: "recording-banner" },
            h("span", { class: "rb-key" }, "…"),
            h("span", null, "正在录制「截图 OCR」的新组合键——请按下组合（如 ", h("kbd", null, "⌥"), h("kbd", null, "J"), "）"),
            h("span", { class: "rb-esc" }, "Esc 取消"),
          ),
        );
      }
      if (stateIdx === 1) {
        content.append(
          h("div", { class: "inline-error" },
            h("span", { class: "ie-icon" }, icon("warn", "sm")),
            h("div", { class: "ie-body" },
              h("div", { class: "ie-title" }, "检测到 2 处热键冲突"),
              h("div", null, "「截图 OCR」与 macOS 系统截屏冲突；Windows 下 Ctrl+Alt+A 与微信截图冲突。冲突热键不会全局生效，请在下方重绑。"),
            ),
          ),
        );
      }

      content.append(
        h("div", { style: { height: "10px" } }),
        h("div", { class: "hk-page-list" },
          ...KEYS.map((k) => {
            const showConflict = stateIdx === 1 && k.conflict;
            return h("div", { class: `hotkey-row ${showConflict ? "conflict" : ""}` },
              h("span", { class: "hk-label" }, k.label),
              h("span", { style: { fontSize: "10.5px", color: "var(--text-3)", width: "92px" } }, `Win/Linux: ${k.win}`),
              h("button", { class: "hk-key", type: "button", title: "点击重新录制", onclick: () => jAt(2) }, k.mac),
              h("span", { class: `hk-status ${showConflict ? "err" : "ok"}` },
                showConflict ? `与 ${k.with} 冲突` : "可用"),
            );
          }),
        ),
        h("div", { class: "form-hint", style: { marginTop: "10px", lineHeight: "1.7" } },
          "提示：macOS 全局热键需授予「辅助功能 + 输入监控」权限，首次启动走授权引导（见 Tab L 权限引导态）。热键监听崩溃自愈，更新不丢配置（§8）。"),
      );

      els.hostThread.appendChild(h("div", { class: "page-view" }, buildSideNav("J"), content));
      currentStateIdx = stateIdx;
      updateControlsActive();
    }

    window.__runState = jAt;
    jAt(1);
    showHint("冲突检测：红字提示占用方；点任意键位进入重绑录制态（B.2 验收项）", 4200);
  }

  // ============================================================
  // v6 · Tab K · 翻译偏好 / 术语表 / Skills
  // PRD §6 #9（三个子页）；术语表 P0 / 风格 P1（§3）
  // ============================================================
  function renderK() {
    els.hostTitle.textContent = "译语 · 翻译偏好 / 术语表 / Skills";
    els.hostInput.value = "";

    const STATES = ["翻译偏好", "术语表", "Skills 模板"];
    setDemoControls(STATES, null, () => kAt(0));

    function termRows(name) {
      const items = TERMS[name] || [];
      return h("div", { class: "term-list" },
        ...items.slice(0, 8).map((t) =>
          h("div", { class: "term-row" },
            h("span", { class: "term-source" }, t.src),
            h("span", { class: "term-arrow", "aria-hidden": "true" }, "→"),
            h("span", { class: "term-target" }, t.tgt),
            h("span", { class: `term-flag ${t.flag === "zh" ? "zh" : t.flag === "both" ? "both" : ""}` }, t.flag.toUpperCase()),
          )
        ),
      );
    }

    function kAt(stateIdx) {
      cancelDemo();
      clear(els.overlay);
      els.hostThread.innerHTML = "";

      const content = h("div", { class: "mw-content" });
      content.append(
        h("div", { class: "subnav", role: "tablist" },
          h("button", { class: stateIdx === 0 ? "active" : "", type: "button", onclick: () => kAt(0) }, "翻译偏好"),
          h("button", { class: stateIdx === 1 ? "active" : "", type: "button", onclick: () => kAt(1) }, "术语表"),
          h("button", { class: stateIdx === 2 ? "active" : "", type: "button", onclick: () => kAt(2) }, "Skills"),
        ),
      );

      if (stateIdx === 0) {
        content.append(
          h("div", { class: "mw-h2" }, "默认语言方向"),
          h("div", { class: "form-inline" },
            h("button", { class: "settings-btn ghost", type: "button", style: { width: "auto", padding: "7px 14px", marginTop: "0", fontWeight: "600", color: "var(--brand)", borderColor: "var(--brand)" } }, "中文"),
            h("button", { class: "settings-btn ghost", type: "button", style: { width: "auto", padding: "7px 10px", marginTop: "0" } }, "⇄"),
            h("button", { class: "settings-btn ghost", type: "button", style: { width: "auto", padding: "7px 14px", marginTop: "0", fontWeight: "600" } }, "English"),
            h("span", { class: "form-hint" }, "悬浮窗 / 键盘内可临时互换"),
          ),
          h("div", { class: "mw-h2" }, "翻译风格（P1）"),
          h("div", { class: "style-grid" },
            ...[["直译", "忠实原文结构"], ["意译", "地道自然表达"], ["商务", "正式书面语气"], ["口语", "轻松聊天风格"]].map(([n, d], i) =>
              h("label", { class: "radio-card" },
                h("input", { type: "radio", name: "style", ...(i === 2 ? { checked: "" } : {}) }),
                h("div", { class: "rc-body" },
                  h("div", { class: "rc-name" }, n),
                  h("div", { class: "rc-meta" }, d),
                ),
              )
            ),
          ),
          h("div", { class: "mw-h2" }, "行为"),
          h("div", { class: "pref-row" },
            h("div", null,
              h("div", { class: "pref-name" }, "语言自动检测"),
              h("div", { class: "pref-desc" }, "源语言不确定时自动识别，检测失败回退默认方向"),
            ),
            h("label", { class: "switch" }, h("input", { type: "checkbox", checked: "" }), h("span", { class: "sw-track" }), h("span", { class: "sw-thumb" })),
          ),
          h("div", { class: "pref-row" },
            h("div", null,
              h("div", { class: "pref-name" }, "预览窗口（后悔窗口）"),
              h("div", { class: "pref-desc" }, "1.2 秒后自动写入 / 总是预览 / 直接写入"),
            ),
            h("select", { class: "select" },
              h("option", null, "1.2 秒后自动写入"),
              h("option", null, "总是预览"),
              h("option", null, "直接写入"),
            ),
          ),
          h("div", { class: "pref-row" },
            h("div", null,
              h("div", { class: "pref-name" }, "双语写回"),
              h("div", { class: "pref-desc" }, "写入译文时可选择附带原文（P0：流式渲染 + 双语写回）"),
            ),
            h("label", { class: "switch" }, h("input", { type: "checkbox" }), h("span", { class: "sw-track" }), h("span", { class: "sw-thumb" })),
          ),
        );
      } else if (stateIdx === 1) {
        content.append(
          h("div", { class: "mw-sub" }, "注入到 prompt，防止专名错译（P0）；支持按场景分表、CSV 导入与分享。"),
          h("div", { class: "term-tabs" },
            ...["通用", "跨境电商", "法律合同", "技术文档"].map((n, i) =>
              h("button", { class: `term-tab ${i === 0 ? "active" : ""}`, type: "button" }, `${n} · ${(TERMS[n] || []).length}`),
            ),
          ),
          termRows("通用"),
          h("div", { style: { display: "flex", gap: "8px", marginTop: "12px" } },
            h("button", { class: "settings-btn primary", type: "button", style: { width: "auto", padding: "8px 16px", marginTop: "0" } }, icon("plus", "sm"), " 添加词条"),
            h("button", { class: "settings-btn ghost", type: "button", style: { width: "auto", padding: "8px 16px", marginTop: "0" } }, icon("download", "sm"), " CSV 导入"),
            h("button", { class: "settings-btn ghost", type: "button", style: { width: "auto", padding: "8px 16px", marginTop: "0" } }, "应用范围：全部场景 ▾"),
          ),
        );
      } else {
        content.append(
          h("div", { class: "mw-sub" }, "Skill 场景模板（P1）：对齐 Chatterfly 六场景，把「成稿风格 + 术语表 + 目标格式」打包，可自定义分享。"),
          h("div", { class: "skill-grid" },
            h("button", { class: "skill-card", type: "button" },
              h("div", { class: "sk-ico" }, icon("fileText")),
              h("div", { class: "sk-name" }, "会议纪要"),
              h("div", { class: "sk-desc" }, "口头语压缩为条目式纪要，自动提炼 action items 与负责人。"),
              h("div", { class: "sk-meta" }, "内置 · 适配流程 A"),
            ),
            h("button", { class: "skill-card", type: "button" },
              h("div", { class: "sk-ico" }, icon("barChart")),
              h("div", { class: "sk-name" }, "工作汇报"),
              h("div", { class: "sk-desc" }, "碎碎念整理成「进展 / 风险 / 下一步」三段式周报口吻。"),
              h("div", { class: "sk-meta" }, "内置 · 适配流程 A"),
            ),
            h("button", { class: "skill-card", type: "button" },
              h("div", { class: "sk-ico" }, icon("calendar")),
              h("div", { class: "sk-name" }, "项目进度"),
              h("div", { class: "sk-desc" }, "按里程碑归组更新事项，标注阻塞点与责任人。"),
              h("div", { class: "sk-meta" }, "内置 · 适配流程 A"),
            ),
            h("button", { class: "skill-card", type: "button" },
              h("div", { class: "sk-ico" }, icon("megaphone")),
              h("div", { class: "sk-name" }, "营销文案"),
              h("div", { class: "sk-desc" }, "吸睛开头 + 卖点结构化，适配跨境电商 Listing 场景。"),
              h("div", { class: "sk-meta" }, "内置 · 适配流程 B"),
            ),
            h("button", { class: "skill-card", type: "button" },
              h("div", { class: "sk-ico" }, icon("mail")),
              h("div", { class: "sk-name" }, "邮件润色"),
              h("div", { class: "sk-desc" }, "正式书面语气，带称呼与落款模板，润色+翻译一次完成。"),
              h("div", { class: "sk-meta" }, "内置 · 适配流程 A/B"),
            ),
            h("button", { class: "skill-card", type: "button" },
              h("div", { class: "sk-ico" }, icon("code")),
              h("div", { class: "sk-name" }, "Vibe-Coding 提示词"),
              h("div", { class: "sk-desc" }, "把口述需求转成结构化 Prompt，含约束条件与输出格式。"),
              h("div", { class: "sk-meta" }, "内置 · 适配流程 A"),
            ),
            h("button", { class: "skill-card custom", type: "button", style: { gridColumn: "1 / -1" } },
              h("div", { class: "sk-ico" }, icon("plus")),
              h("div", { class: "sk-name" }, "新建 Skill"),
              h("div", { class: "sk-meta" }, "选择风格 / 术语表 / 输出格式"),
            ),
          ),
          h("div", { class: "form-hint", style: { marginTop: "10px" } }, "Skill 分享格式为 JSON（含术语表引用），可导入导出；不上传任何内容（ADR-001）。"),
        );
      }

      els.hostThread.appendChild(h("div", { class: "page-view" }, buildSideNav("K"), content));
      currentStateIdx = stateIdx;
      updateControlsActive();
    }

    window.__runState = kAt;
    kAt(0);
    showHint("三个子页：翻译偏好（风格 P1）/ 术语表（P0）/ Skills 模板（P1）", 4200);
  }

  // ============================================================
  // v6 · Tab L · 首次引导三步 + 权限引导
  // PRD §6 #10、§5.3 ⑥；状态：步骤1 / 2 / 3 / 权限 / 完成
  // 无强制登录；「先用本地模型试用」零门槛入口
  // ============================================================
  function renderL() {
    els.hostTitle.textContent = "译语 · 首次启动";
    els.hostInput.value = "";
    els.hostThread.innerHTML = "";

    const STATES = ["步骤 1 · 选平台", "步骤 2 · 填 Key", "步骤 3 · 设热键", "macOS 权限引导", "完成"];
    setDemoControls(STATES, null, () => lAt(0));

    const WIZ_PLATS = [
      { name: "OpenAI", logo: "O", bg: "#10A37F" },
      { name: "Anthropic", logo: "C", bg: "#D97757" },
      { name: "Gemini", logo: "G", bg: "#4285F4" },
      { name: "DeepSeek", logo: "D", bg: "#4D6BFE" },
      { name: "通义", logo: "通", bg: "#615CED" },
      { name: "Ollama 本地", logo: "O", bg: "#1A1A1A" },
    ];

    function dots(active) {
      return h("div", { class: "wiz-dots" },
        ...[0, 1, 2].map((i) =>
          h("span", { class: `wiz-dot ${i < active ? "done" : i === active ? "active" : ""}` })
        ),
      );
    }

    function lAt(stateIdx) {
      cancelDemo();
      clear(els.overlay);

      let card;
      if (stateIdx === 0) {
        card = h("div", { class: "wiz-card" },
          dots(0),
          h("div", { class: "wiz-kicker" }, "Welcome to LinguaFlow"),
          h("div", { class: "wiz-title" }, "选择你的模型平台"),
          h("div", { class: "wiz-sub" }, "BYOK：用你自己的 Key，任意平台。没有 Key？可先用本地模型零门槛体验。"),
          h("div", { class: "plat-grid", style: { gridTemplateColumns: "repeat(3, 1fr)" } },
            ...WIZ_PLATS.map((p, i) =>
              h("button", { class: `plat-card ${i === 5 ? "selected" : ""}`, type: "button" },
                h("span", { class: "plat-logo", style: { background: p.bg } }, p.logo),
                h("span", { class: "plat-name" }, p.name),
              )
            ),
          ),
          h("div", { class: "wiz-actions" },
            h("button", { class: "settings-btn ghost", type: "button", onclick: () => lAt(3) }, "稍后再说"),
            h("button", { class: "settings-btn primary", type: "button", style: { flex: "1" }, onclick: () => lAt(1) }, "下一步"),
          ),
        );
      } else if (stateIdx === 1) {
        card = h("div", { class: "wiz-card" },
          dots(1),
          h("div", { class: "wiz-kicker" }, "BYOK"),
          h("div", { class: "wiz-title" }, "填入 API Key"),
          h("div", { class: "wiz-sub" }, "Key 只存本机系统密钥串；请求直连模型方，不经我方服务器。"),
          h("div", { class: "form-grid" },
            h("div", { class: "form-row" },
              h("label", { class: "form-label" }, "API Key", h("span", { class: "req" }, "*")),
              h("input", { class: "form-input", type: "password", placeholder: "sk-… / sk-ant-… / AIza…" }),
              h("span", { class: "form-hint" }, "<a>OpenAI</a> · <a>Anthropic</a> · <a>Gemini</a> · <a>DeepSeek</a> 申请链接"),
            ),
            h("div", { class: "form-row" },
              h("label", { class: "form-label" }, "BaseURL（可选，默认官方端点）"),
              h("input", { class: "form-input", type: "text", placeholder: "https://api.openai.com/v1" }),
            ),
          ),
          h("div", { class: "wiz-actions" },
            h("button", { class: "settings-btn ghost", type: "button", onclick: () => lAt(0) }, "上一步"),
            h("button", { class: "settings-btn ghost", type: "button", onclick: () => lAt(2) }, "跳过，先用本地模型试用"),
            h("button", { class: "settings-btn primary", type: "button", style: { flex: "1" }, onclick: () => lAt(2) }, "下一步"),
          ),
        );
      } else if (stateIdx === 2) {
        card = h("div", { class: "wiz-card" },
          dots(2),
          h("div", { class: "wiz-kicker" }, "Hotkeys"),
          h("div", { class: "wiz-title" }, "设置你的热键"),
          h("div", { class: "wiz-sub" }, "两类手感必须区分：唤起键单次触发、语音键按住触发（PRD §4）。全部可改。"),
          h("div", { class: "hk-page-list", style: { padding: "4px 12px" } },
            h("div", { class: "hotkey-row" },
              h("span", { class: "hk-label" }, "按住说话"),
              h("button", { class: "hk-key", type: "button" }, "按住 Fn"),
              h("span", { class: "hk-status ok" }, "可用"),
            ),
            h("div", { class: "hotkey-row" },
              h("span", { class: "hk-label" }, "唤起悬浮窗"),
              h("button", { class: "hk-key", type: "button" }, "⌥ Space"),
              h("span", { class: "hk-status ok" }, "可用"),
            ),
          ),
          h("div", { class: "wiz-actions" },
            h("button", { class: "settings-btn ghost", type: "button", onclick: () => lAt(1) }, "上一步"),
            h("button", { class: "settings-btn primary", type: "button", style: { flex: "1" }, onclick: () => lAt(3) }, "下一步"),
          ),
        );
      } else if (stateIdx === 3) {
        card = h("div", { class: "wiz-card" },
          dots(3),
          h("div", { class: "wiz-kicker" }, "Permissions"),
          h("div", { class: "wiz-title" }, "授予两个系统权限"),
          h("div", { class: "wiz-sub" }, "全局热键需要以下权限；只用于监听热键与读取选中文本，不做任何采集（§8 隐私）。"),
          h("div", { class: "perm-card" },
            h("div", { class: "perm-ico" }, icon("accessibility")),
            h("div", { class: "perm-body" },
              h("div", { class: "perm-name" }, "辅助功能", h("span", { class: "perm-status warn" }, "· 待授权")),
              h("div", { class: "perm-desc" }, "监听全局热键（Fn / ⌥ 组合）并向其他应用注入文本"),
            ),
            h("button", { class: "settings-btn primary", type: "button", style: { width: "auto", padding: "7px 12px", marginTop: "0" } }, "打开设置"),
          ),
          h("div", { class: "perm-card" },
            h("div", { class: "perm-ico" }, icon("mouse")),
            h("div", { class: "perm-body" },
              h("div", { class: "perm-name" }, "输入监控", h("span", { class: "perm-status warn" }, "· 待授权")),
              h("div", { class: "perm-desc" }, "读取划词选区，实现流程 C / D"),
            ),
            h("button", { class: "settings-btn primary", type: "button", style: { width: "auto", padding: "7px 12px", marginTop: "0" } }, "打开设置"),
          ),
          h("div", { class: "wiz-actions" },
            h("button", { class: "settings-btn ghost", type: "button", onclick: () => lAt(2) }, "上一步"),
            h("button", { class: "settings-btn primary", type: "button", style: { flex: "1" }, onclick: () => lAt(4) }, "我已授权，完成"),
          ),
        );
      } else {
        card = h("div", { class: "wiz-card" },
          dots(3),
          h("div", { style: { textAlign: "center" } },
            h("div", { class: "about-logo", style: { margin: "0 auto 10px", display: "flex", alignItems: "center", justifyContent: "center" } }, icon("check", "xl")),
            h("div", { class: "wiz-title" }, "一切就绪"),
            h("div", { class: "wiz-sub" }, "当前默认：Ollama · qwen2.5:7b（本地 · 离线 · 零成本）。随时可在「模型配置」切换或新增 Provider。"),
            h("div", { style: { display: "flex", gap: "8px", justifyContent: "center", margin: "14px 0 4px" } },
              h("span", { class: "badge live" }, "本地模型"),
              h("span", { class: "badge" }, "零遥测"),
              h("span", { class: "badge" }, "五端同步"),
            ),
          ),
          h("div", { class: "wiz-actions" },
            h("button", { class: "settings-btn primary", type: "button", style: { flex: "1" }, onclick: () => switchTab("A") }, "开始使用 · 按住 Fn 说话 →"),
          ),
        );
      }

      els.overlay.appendChild(h("div", { class: "wizard" }, card));
      currentStateIdx = stateIdx;
      updateControlsActive();
    }

    window.__runState = lAt;
    lAt(0);
    showHint("三步引导：选平台 → 填 Key（可跳过走本地试用）→ 设热键 + macOS 权限引导（B.3）", 4200);
  }

  // ============================================================
  // v6 · Tab M · 移动 App 主页 + 隐私锁
  // PRD §6 #11（Tab F 承担桌面锁屏，本页补移动 App 主页）
  // 状态：App 主页 / FaceID 锁定 / 解锁成功
  // ============================================================
  function renderM() {
    els.hostTitle.textContent = "iOS · 译语 App";
    els.hostInput.value = "";

    const STATES = ["App 主页", "隐私锁 · FaceID", "解锁成功"];
    setDemoControls(STATES, null, () => mAt(0));

    function mAt(stateIdx) {
      cancelDemo();
      clear(els.overlay);

      const app = h("div", { class: "phone-app" },
        h("div", { class: "pa-hero" },
          h("span", { class: "pa-hero-logo" }, "译"),
          h("div", null,
            h("div", { class: "pa-hero-name" }, "译语"),
            h("div", { class: "pa-hero-sub" }, "BYOK · 零采集 · 五端同步"),
          ),
        ),
        h("div", { class: "pa-card" },
          h("div", { class: "pa-card-title" }, "当前配置"),
          h("div", { class: "pa-row" },
            h("span", { class: "pr-ico" }, icon("chip")),
            h("span", { class: "pa-name" }, "默认模型"),
            h("span", { class: "pa-meta" }, "Ollama · qwen2.5:7b"),
            h("span", { class: "pa-chevron" }, "›"),
          ),
          h("div", { class: "pa-row" },
            h("span", { class: "pr-ico" }, icon("globe")),
            h("span", { class: "pa-name" }, "语言方向"),
            h("span", { class: "pa-meta" }, "中文 → English"),
            h("span", { class: "pa-chevron" }, "›"),
          ),
        ),
        h("div", { class: "pa-card" },
          h("div", { class: "pa-card-title" }, "键盘"),
          h("div", { class: "pa-row" },
            h("span", { class: "pr-ico" }, icon("keyboard")),
            h("span", { class: "pa-name" }, "引导开启译语键盘"),
            h("span", { class: "pa-meta" }, "未启用"),
            h("span", { class: "pa-chevron" }, "›"),
          ),
          h("div", { class: "pa-row" },
            h("span", { class: "pr-ico" }, icon("book")),
            h("span", { class: "pa-name" }, "键盘术语表"),
            h("span", { class: "pa-meta" }, "通用 · 8 条"),
            h("span", { class: "pa-chevron" }, "›"),
          ),
        ),
        h("div", { class: "pa-card" },
          h("div", { class: "pa-card-title" }, "隐私与安全"),
          h("div", { class: "pa-row" },
            h("span", { class: "pr-ico" }, icon("shield")),
            h("span", { class: "pa-name" }, "隐私锁"),
            h("span", { class: "pa-meta" }, "FaceID"),
            h("label", { class: "switch" }, h("input", { type: "checkbox", checked: "" }), h("span", { class: "sw-track" }), h("span", { class: "sw-thumb" })),
          ),
          h("div", { class: "pa-row" },
            h("span", { class: "pr-ico" }, icon("ban")),
            h("span", { class: "pa-name" }, "零遥测"),
            h("span", { class: "pa-meta" }, "始终开启，不可关闭"),
          ),
        ),
      );

      const phone = h("div", { class: "phone-frame" },
        h("div", { class: "phone-notch", "aria-hidden": "true" }),
        h("div", { class: "phone-status" }, "9:41"),
        app,
      );

      if (stateIdx === 1) {
        phone.appendChild(h("div", { class: "lock-screen" },
          h("div", { class: "lock-bg", "aria-hidden": "true" }),
          h("div", { class: "lock-card", style: { width: "280px", padding: "26px 20px" } },
            h("div", { class: "lock-icon", "aria-hidden": "true" }),
            h("div", { class: "lock-title" }, "已锁定"),
            h("div", { class: "lock-sub" }, "历史 / 配置 / 术语表已隐藏"),
            h("div", { class: "lock-face" },
              h("div", { class: "lock-face-icon", "aria-hidden": "true" }),
              h("div", null,
                h("div", { class: "lock-face-title" }, "FaceID"),
                h("div", { class: "lock-face-sub" }, "正在扫描…"),
              ),
              h("div", { class: "lock-dot" }),
            ),
            h("button", { type: "button", class: "lock-alt" }, "或输入密码"),
          ),
        ));
      } else if (stateIdx === 2) {
        const banner = h("div", { class: "privacy-banner success bar-enter", style: { position: "absolute", top: "70px", left: "50%", transform: "translateX(-50%)", minWidth: "0", padding: "10px 14px" } },
          h("span", { class: "pb-icon" }, icon("check", "sm")),
          h("div", null,
            h("div", { class: "pb-title" }, "FaceID 验证通过"),
            h("div", { class: "pb-sub" }, "0.3s · 无遥测"),
          ),
        );
        phone.appendChild(banner);
        schedule(() => {
          banner.classList.add("bar-exit");
          schedule(() => banner.remove(), 250);
        }, 2000);
      }

      els.overlay.appendChild(phone);
      currentStateIdx = stateIdx;
      updateControlsActive();
    }

    window.__runState = mAt;
    mAt(0);
    showHint("移动 App 主页：键盘引导（iOS 不能自动切换）+ 隐私锁（B.4）", 4200);
  }

  // ============================================================
  // v7.2 · Tab N · Windows 端（Win11 · Fluent Design）
  // 状态：录音中 → 成稿中 → 预览 → 已落框（+ Win 通知 Toast）→ 托盘快速面板
  // 设计语言：Mica 窗口 8px 圆角 · Segoe UI · Acrylic 面板 · 居中任务栏
  // ============================================================
  function renderN() {
    els.hostTitle.textContent = "Windows 11 · 译语";
    els.hostInput.value = "";
    els.hostInput.disabled = true;
    els.hostThread.innerHTML = "";

    const STATES = ["录音中", "成稿中", "预览", "已落框", "托盘面板"];
    setDemoControls(STATES, runN, () => nAt(0));

    const draftZh = "那个报价我确认没问题，下周三之前可以签合同。";
    const finalZh = "那个报价我确认没问题，下周三之前可以把合同签了。";

    // Win11 标题栏右侧按钮（− □ ×，关闭键 hover 红）
    function winCaps() {
      return h("div", { class: "win-caps" },
        h("span", { class: "win-cap", "aria-hidden": "true", innerHTML: '<svg viewBox="0 0 10 10" width="10" height="10"><path d="M1 5h8" stroke="currentColor" stroke-width="1"/></svg>' }),
        h("span", { class: "win-cap", "aria-hidden": "true", innerHTML: '<svg viewBox="0 0 10 10" width="10" height="10"><rect x="1.5" y="1.5" width="7" height="7" fill="none" stroke="currentColor"/></svg>' }),
        h("span", { class: "win-cap close", "aria-hidden": "true", innerHTML: '<svg viewBox="0 0 10 10" width="10" height="10"><path d="M1 1l8 8M9 1L1 9" stroke="currentColor" stroke-width="1"/></svg>' }),
      );
    }

    // Win 语音成稿条（复用 pill 组件 + Fluent 皮肤）
    function winPill(stateIdx) {
      const bar = h("div", { class: "bar bar-enter bar-pill win-skin", dataset: { state: stateIdx } });
      if (stateIdx === 0) {
        bar.append(
          h("span", { class: "mic-dot", "aria-hidden": "true" }),
          h("span", { class: "bar-wave", "aria-hidden": "true" }, ...Array.from({ length: 10 }, () => h("span"))),
          h("span", { class: "bar-text", dataset: { lang: "zh" } }, "正在聆听", h("span", { class: "chars" }, " 0:02")),
          h("span", { class: "win-hk" }, "Win+H"),
        );
      } else if (stateIdx === 1) {
        bar.append(
          h("span", { class: "bar-spinner", "aria-hidden": "true" }),
          h("span", { class: "bar-text" }, "成稿中…", h("span", { class: "chars" }, " 已输出 8 字")),
          h("span", { class: "bar-action" }, "Esc 取消"),
        );
      } else if (stateIdx === 2) {
        bar.classList.add("bar-preview");
        bar.append(
          h("span", { class: "bar-text text-fade-in" }, draftZh, h("span", { class: "bar-cursor" })),
          h("span", { class: "bar-action" }, "✓ 1.2s"),
          h("span", { class: "bar-action" }, "✗ 重说"),
        );
      } else if (stateIdx === 3) {
        bar.append(
          h("span", { class: "mic-dot", style: { background: "var(--success)", boxShadow: "0 0 0 4px rgba(43,164,113,0.2)" }, "aria-hidden": "true" }),
          h("span", { class: "bar-text" }, "✓ 已写入 · 成稿"),
        );
        schedule(() => {
          bar.classList.add("bar-exit");
          schedule(() => bar.remove(), 250);
        }, 1500);
      }
      return bar;
    }

    // 任务栏（居中图标 + 右侧托盘）
    function winTaskbar() {
      const tbIcon = (label, inner, active) =>
        h("button", { type: "button", class: `win-tb-icon ${active ? "active" : ""}`, "aria-label": label, title: label, innerHTML: inner });
      return h("div", { class: "win-taskbar" },
        h("div", { class: "win-tb-center" },
          tbIcon("开始", icon("windows", "lg").innerHTML),
          tbIcon("搜索", '<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.7" stroke-linecap="round"><circle cx="11" cy="11" r="6.5"/><path d="m16 16 4.5 4.5"/></svg>'),
          tbIcon("文件资源管理器", icon("folder", "lg").innerHTML),
          tbIcon("浏览器", '<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.7"><circle cx="12" cy="12" r="9"/><path d="M12 3a13 13 0 0 1 0 18M12 3a13 13 0 0 0 0 18M3.5 9.5h17M3.5 14.5h17" opacity="0.7"/></svg>'),
          tbIcon("译语", `<span class="win-tb-applogo">译</span>`, true),
        ),
        h("div", { class: "win-tb-tray" },
          h("span", { class: "win-tray-item win-ime" }, "中"),
          h("span", { class: "win-tray-item", "aria-hidden": "true", innerHTML: '<svg viewBox="0 0 16 16" width="13" height="13" fill="currentColor"><path d="M8 2 4.5 5.5H2v5h2.5L8 14zM10.5 5.5a3.6 3.6 0 0 1 0 5M12.5 3.5a6.4 6.4 0 0 1 0 9" fill="none" stroke="currentColor" stroke-width="1.2" stroke-linecap="round" stroke-linejoin="round"/></svg>' }),
          h("span", { class: "win-tray-item", "aria-hidden": "true", innerHTML: '<svg viewBox="0 0 16 16" width="13" height="13" fill="currentColor"><path d="M8 13.5 2 7.2a8.5 8.5 0 0 1 12 0z" opacity="0.9"/></svg>' }),
          h("span", { class: "win-tray-clock" }, h("span", null, "20:10"), h("span", null, "2026/09/26")),
        ),
      );
    }

    // 托盘上方 Acrylic 快速面板（态 4）
    function winQuickPanel() {
      const row = (label, val) =>
        h("div", { class: "wqp-row" }, h("span", null, label), h("strong", null, val));
      const toggle = (label, on) =>
        h("div", { class: "wqp-row toggle" },
          h("span", null, label),
          h("label", { class: "mini-switch" },
            h("input", { type: "checkbox", ...(on ? { checked: "" } : {}), "aria-label": label }),
            h("span", { class: "ms-track" }, h("span", { class: "ms-thumb" })),
          ),
        );
      return h("div", { class: "win-quickpanel rise-in" },
        h("div", { class: "wqp-head" },
          h("span", { class: "wqp-logo" }, "译"),
          h("div", null,
            h("div", { class: "wqp-name" }, "译语"),
            h("div", { class: "wqp-sub" }, "本地优先 · 已连接"),
          ),
          h("span", { class: "popover-dot ok", "aria-label": "在线" }),
        ),
        row("模型", "Ollama · qwen2.5:7b"),
        row("语言方向", "中文 → English"),
        row("按住说话", "Win+H"),
        h("div", { class: "wqp-sep", role: "separator" }),
        toggle("开机自启", true),
        toggle("隐私锁", false),
        h("button", { type: "button", class: "wqp-open" }, icon("window", "sm"), " 打开主窗口"),
      );
    }

    // Win 通知 Toast（态 3，右下角）
    function winToast() {
      return h("div", { class: "win-toast rise-in" },
        h("span", { class: "wt-ico" }, "译"),
        h("div", { class: "wt-body" },
          h("div", { class: "wt-app" }, "译语"),
          h("div", { class: "wt-title" }, "已写入成稿"),
          h("div", { class: "wt-sub" }, finalZh),
        ),
      );
    }

    function nAt(stateIdx) {
      cancelDemo();
      clear(els.overlay);

      const desktop = h("div", { class: "win-desktop" },
        h("div", { class: "win-wallpaper", "aria-hidden": "true" }),
        h("div", { class: "win-window" },
          h("div", { class: "win-titlebar" },
            h("span", { class: "win-app-ico" }, "译"),
            h("span", { class: "win-title" }, "新邮件 · 致 Daniel"),
            winCaps(),
          ),
          h("div", { class: "win-body" },
            h("div", { class: "win-mail-row" }, h("span", { class: "win-mail-label" }, "收件人"), h("span", null, "daniel@acme.com")),
            h("div", { class: "win-mail-row" }, h("span", { class: "win-mail-label" }, "主题"), h("span", null, "Re: 报价确认")),
            h("div", { class: "win-body-text", id: "winBodyText" },
              stateIdx >= 3 ? finalZh : "",
              stateIdx >= 3 ? null : h("span", { class: "win-placeholder" }, "点击开始输入 · 按住 Win+H 说话，成稿自动写入"),
            ),
            stateIdx === 2 ? h("span", { class: "bar-cursor win-cursor", "aria-hidden": "true" }) : null,
          ),
        ),
        winTaskbar(),
        stateIdx <= 2 || stateIdx === 3 ? winPill(stateIdx) : null,
        stateIdx === 3 ? winToast() : null,
        stateIdx === 4 ? winQuickPanel() : null,
      );

      els.overlay.appendChild(desktop);
      currentStateIdx = stateIdx;
      updateControlsActive();
    }

    function runN() {
      nAt(0);
      schedule(() => nAt(1), 1800);
      schedule(() => nAt(2), 3400);
      schedule(() => nAt(3), 5400);
    }

    window.__runState = nAt;
    runN();
    showHint("Windows 11 · Win+H 按住说话 → Fluent pill 成稿 → 落入邮件正文；最后一态查看任务栏托盘快速面板", 4600);
  }

  // ============================================================
  // v7.2 · Tab O · Android 端（Material 3 / Material You）
  // 状态：键盘展开 → 语音输入 → 成稿候选 → 已落框 → App 主页
  // 设计语言：Gboard · 打孔屏 · 动态色 tonal surface · NavigationBar + FAB
  // ============================================================
  function renderO() {
    els.hostTitle.textContent = "Android · 译语";
    els.hostInput.value = "";
    els.hostInput.disabled = true;
    els.hostThread.innerHTML = "";

    const STATES = ["键盘展开", "语音输入", "成稿候选", "已落框", "App 主页"];
    setDemoControls(STATES, runO, () => oAt(0));

    const original = "下周三能签吗？";
    const draftZh = "下周三之前应该可以签合同。";
    const finalZh = "下周三之前应该可以把合同签了。";

    // Android 状态栏：左时间 · 右图标（与 iOS 相反）
    function aStatus() {
      return h("div", { class: "android-status" },
        h("span", { class: "as-time" }, "14:32"),
        h("span", { class: "as-icons", "aria-hidden": "true", innerHTML:
          '<svg viewBox="0 0 46 12" width="46" height="12" fill="currentColor"><path d="M3 9.8 6.4 6.4 9.8 9.8z"/><path d="M13.5 9.8 18 5.3l4.5 4.5z" opacity="0.85"/><rect x="28" y="3.2" width="10" height="7" rx="1.8" fill="none" stroke="currentColor"/><rect x="29.3" y="4.5" width="5.6" height="4.4" rx="0.8"/><rect x="38.8" y="5.2" width="1.5" height="2.8" rx="0.7"/></svg>' }),
      );
    }

    // Gboard 键盘（Material 动态色）
    function gboard(stateIdx) {
      const kb = h("div", { class: "gboard" });

      // 工具条：G 标识 + 建议 chips + 语音钮
      kb.appendChild(h("div", { class: "gb-toolbar" },
        h("span", { class: "gb-logo", "aria-hidden": "true" }, "G"),
        h("div", { class: "gb-chips" },
          ...(stateIdx >= 2 ? [] : [h("span", { class: "gb-chip" }, "在吗"), h("span", { class: "gb-chip" }, "好的")]),
          h("span", { class: "gb-chip brand" }, stateIdx >= 2 ? draftZh.slice(0, 9) + "…" : "收到"),
        ),
        h("button", { type: "button", class: `gb-mic ${stateIdx === 1 ? "on" : ""}`, "aria-label": "语音输入" }, icon("mic", "sm")),
      ));

      // 成稿候选（态 2）：M3 chip 双选
      if (stateIdx === 2) {
        kb.appendChild(h("div", { class: "gb-candidates rise-in" },
          h("span", { class: "gbc-label" }, "译语成稿"),
          h("button", { type: "button", class: "gb-cand primary" }, draftZh),
          h("button", { type: "button", class: "gb-cand" }, "Can we sign it by next Wednesday?"),
        ));
      }

      // 键区 / 语音全屏区
      if (stateIdx === 1) {
        kb.appendChild(h("div", { class: "gb-voice rise-in" },
          h("div", { class: "gbv-mic", "aria-hidden": "true" }, icon("mic", "lg")),
          h("div", { class: "gbv-wave", "aria-hidden": "true" }, ...Array.from({ length: 14 }, () => h("span"))),
          h("div", { class: "gbv-text" }, "正在聆听：", h("strong", null, original)),
          h("div", { class: "gbv-hint" }, "松手成稿 · 译语本地引擎 · 0 ¥"),
        ));
      } else {
        const keys = [
          ["q", "w", "e", "r", "t", "y", "u", "i", "o", "p"],
          ["a", "s", "d", "f", "g", "h", "j", "k", "l"],
          ["z", "x", "c", "v", "b", "n", "m"],
        ];
        const body = h("div", { class: "gb-keys" });
        keys.forEach((row, ri) => {
          const r = h("div", { class: "gb-key-row" });
          if (ri === 2) r.appendChild(h("button", { type: "button", class: "gb-key fn" }, "⇧"));
          row.forEach((k) => r.appendChild(h("button", { type: "button", class: "gb-key" }, k)));
          if (ri === 2) r.appendChild(h("button", { type: "button", class: "gb-key fn" }, "⌫"));
          body.appendChild(r);
        });
        body.appendChild(h("div", { class: "gb-key-row gb-bottom" },
          h("button", { type: "button", class: "gb-key fn" }, "?123"),
          h("button", { type: "button", class: "gb-key fn" }, ","),
          h("button", { type: "button", class: "gb-key space" }, "中文"),
          h("button", { type: "button", class: "gb-key fn" }, "."),
          h("button", { type: "button", class: "gb-key enter" }, "发送"),
        ));
        kb.appendChild(body);
      }

      // 手势导航条
      kb.appendChild(h("div", { class: "gb-gesture", "aria-hidden": "true" }));
      return kb;
    }

    function oAt(stateIdx) {
      cancelDemo();
      clear(els.overlay);

      // 态 4：Material You App 主页
      if (stateIdx === 4) {
        const app = h("div", { class: "phone-frame android m3-app" },
          h("span", { class: "phone-punchhole", "aria-hidden": "true" }),
          aStatus(),
          h("div", { class: "m3-top" },
            h("div", null,
              h("div", { class: "m3-title" }, "译语"),
              h("div", { class: "m3-sub" }, "BYOK · 零采集 · 本地优先"),
            ),
            h("span", { class: "m3-avatar" }, "K"),
          ),
          h("div", { class: "m3-scroll" },
            h("div", { class: "m3-card tonal" },
              h("div", { class: "m3-card-head" },
                h("span", { class: "m3-badge" }, "最近成稿"),
                h("span", { class: "m3-time" }, "刚刚 · 微信"),
              ),
              h("div", { class: "m3-src" }, "那个报价我确认没问题，下周三之前可以把合同签了。"),
              h("div", { class: "m3-tgt" }, "Confirmed, no problem with the quote. We can sign the contract before next Wednesday."),
              h("div", { class: "m3-card-actions" },
                h("button", { type: "button", class: "m3-chipbtn" }, icon("copy", "sm"), " 复制"),
                h("button", { type: "button", class: "m3-chipbtn" }, icon("refresh", "sm"), " 重说"),
              ),
            ),
            h("div", { class: "m3-card list" },
              h("div", { class: "m3-row" }, h("span", { class: "m3-ico" }, icon("chip")), h("span", { class: "m3-name" }, "模型"), h("span", { class: "m3-meta" }, "qwen2.5:7b"), h("span", { class: "m3-chevron" }, "›")),
              h("div", { class: "m3-row" }, h("span", { class: "m3-ico" }, icon("keyboard")), h("span", { class: "m3-name" }, "译语键盘"), h("span", { class: "m3-meta" }, "已启用"), h("span", { class: "m3-chevron" }, "›")),
              h("div", { class: "m3-row" }, h("span", { class: "m3-ico" }, icon("globe")), h("span", { class: "m3-name" }, "语言方向"), h("span", { class: "m3-meta" }, "中文 ⇄ English"), h("span", { class: "m3-chevron" }, "›")),
              h("div", { class: "m3-row" }, h("span", { class: "m3-ico" }, icon("shield")), h("span", { class: "m3-name" }, "隐私锁"), h("span", { class: "m3-meta" }, "指纹解锁"),
                h("label", { class: "switch" }, h("input", { type: "checkbox", checked: "" }), h("span", { class: "sw-track" }), h("span", { class: "sw-thumb" })),
              ),
            ),
          ),
          h("button", { type: "button", class: "m3-fab", "aria-label": "按住说话" }, icon("mic", "lg")),
          h("div", { class: "m3-navbar" },
            h("button", { type: "button", class: "m3-nav-item active" }, h("span", { class: "m3-nav-pill" }, icon("home")), h("span", { class: "m3-nav-label" }, "首页")),
            h("button", { type: "button", class: "m3-nav-item" }, h("span", { class: "m3-nav-pill" }, icon("clock")), h("span", { class: "m3-nav-label" }, "历史")),
            h("button", { type: "button", class: "m3-nav-item" }, h("span", { class: "m3-nav-pill" }, icon("smile")), h("span", { class: "m3-nav-label" }, "我的")),
          ),
        );
        els.overlay.appendChild(app);
        currentStateIdx = stateIdx;
        updateControlsActive();
        return;
      }

      // 态 0–3：微信 + Gboard 键盘流程
      const phone = h("div", { class: "phone-frame android" },
        h("span", { class: "phone-punchhole", "aria-hidden": "true" }),
        aStatus(),
        h("div", { class: "phone-host" },
          h("div", { class: "phone-thread", innerHTML:
            `<div style="display:flex;flex-direction:column;gap:8px;padding:14px 12px;height:100%;box-sizing:border-box;background:linear-gradient(180deg,#f8f8f8 0%,#efefef 100%)">
              <div style="font-size:11px;color:#999;text-align:center">微信 · 给李总</div>
              <div style="background:#fff;align-self:flex-start;padding:9px 12px;border-radius:4px 12px 12px 12px;font-size:13px;max-width:78%;color:#000;border:1px solid #e8e8e8">确认一下，这周能把合同定下来吗？</div>
              <div style="background:#95EC69;align-self:flex-end;padding:9px 12px;border-radius:12px 4px 12px 12px;font-size:13px;max-width:78%;color:#000">如果价格合适，我们愿意直接推进。</div>
            </div>` }),
          h("div", { class: "phone-input-row" },
            h("button", { class: "phone-mic", type: "button", "aria-label": "语音" }, icon("mic")),
            h("input", { type: "text", class: "phone-input", placeholder: "消息", value: stateIdx >= 3 ? finalZh : stateIdx >= 2 ? original : "" }),
            h("button", { class: "phone-emoji", type: "button", "aria-label": "表情" }, icon("smile")),
          ),
        ),
        gboard(stateIdx),
      );

      // 态 3：M3 Snackbar 反馈
      if (stateIdx === 3) {
        const snack = h("div", { class: "m3-snackbar rise-in" }, icon("check", "sm"), "已写入成稿 · 本地处理 · 0 ¥");
        phone.appendChild(snack);
        schedule(() => {
          snack.classList.add("rise-exit");
          schedule(() => snack.remove(), 250);
        }, 2400);
      }

      els.overlay.appendChild(phone);
      currentStateIdx = stateIdx;
      updateControlsActive();
    }

    function runO() {
      oAt(0);
      schedule(() => oAt(1), 1600);
      schedule(() => oAt(2), 3400);
      schedule(() => oAt(3), 5200);
    }

    window.__runState = oAt;
    runO();
    showHint("Android · Gboard 语音成稿 → Material You 动态色；最后一态查看译语 App 主页（NavigationBar + FAB）", 4600);
  }


  // ============================================================
  // 设置抽屉 Tab 切换
  // ============================================================
  function switchSettings(stab) {
    els.settingsTabs.forEach((t) => {
      const active = t.dataset.stab === stab;
      t.classList.toggle("active", active);
      t.setAttribute("aria-selected", String(active));
    });
    els.settingsPanes.forEach((p) => {
      const active = p.dataset.pane === stab;
      p.classList.toggle("active", active);
      p.hidden = !active;
    });
  }
  els.settingsTabs.forEach((t) => t.addEventListener("click", () => switchSettings(t.dataset.stab)));
  els.settingsClose.addEventListener("click", () => els.settings.classList.toggle("collapsed"));

  // ============================================================
  // 术语表渲染
  // ============================================================
  const TERMS = {
    "通用": [
      { src: "报价", tgt: "quote", flag: "both" },
      { src: "合同", tgt: "contract", flag: "both" },
      { src: "BYOK", tgt: "BYOK", flag: "en" },
      { src: "签字", tgt: "sign", flag: "both" },
      { src: "工作日", tgt: "business day", flag: "both" },
      { src: "里程碑", tgt: "milestone", flag: "both" },
      { src: "需求方", tgt: "Stakeholder", flag: "zh" },
      { src: "交付物", tgt: "deliverable", flag: "both" },
    ],
    "跨境电商": [
      { src: "SKU", tgt: "SKU", flag: "en" },
      { src: "选品", tgt: "product sourcing", flag: "both" },
      { src: "Listing", tgt: "商品上架页", flag: "both" },
      { src: "爆款", tgt: "blockbuster", flag: "both" },
      { src: "复购", tgt: "repurchase", flag: "both" },
      { src: "差评", tgt: "negative review", flag: "both" },
      { src: "退货率", tgt: "return rate", flag: "both" },
      { src: "客单价", tgt: "average order value", flag: "both" },
      { src: "SKU", tgt: "SKU", flag: "en" },
      { src: "FBA", tgt: "Fulfillment by Amazon", flag: "en" },
      { src: "亚马逊", tgt: "Amazon", flag: "zh" },
      { src: "广告 ACOS", tgt: "Advertising Cost of Sales", flag: "en" },
    ],
    "法律合同": [
      { src: "甲方", tgt: "Party A", flag: "both" },
      { src: "乙方", tgt: "Party B", flag: "both" },
      { src: "不可抗力", tgt: "force majeure", flag: "both" },
      { src: "违约责任", tgt: "liability for breach", flag: "both" },
      { src: "争议解决", tgt: "dispute resolution", flag: "both" },
      { src: "管辖法院", tgt: "jurisdiction", flag: "both" },
    ],
    "技术文档": [
      { src: "API", tgt: "API", flag: "en" },
      { src: "端点", tgt: "endpoint", flag: "both" },
      { src: "鉴权", tgt: "authentication", flag: "both" },
      { src: "限流", tgt: "rate limiting", flag: "both" },
      { src: "WebSocket", tgt: "WebSocket", flag: "en" },
      { src: "发布", tgt: "release", flag: "both" },
      { src: "回滚", tgt: "rollback", flag: "both" },
      { src: "灰度", tgt: "canary", flag: "both" },
      { src: "热更新", tgt: "hot reload", flag: "both" },
      { src: "副作用", tgt: "side effect", flag: "both" },
      { src: "清理函数", tgt: "cleanup function", flag: "both" },
      { src: "事件监听", tgt: "event listener", flag: "both" },
      { src: "内存泄漏", tgt: "memory leak", flag: "both" },
      { src: "依赖", tgt: "dependency", flag: "both" },
      { src: "单页应用", tgt: "single-page app", flag: "both" },
      { src: "类型守卫", tgt: "type guard", flag: "both" },
      { src: "中间件", tgt: "middleware", flag: "both" },
      { src: "加密", tgt: "encryption", flag: "both" },
      { src: "哈希", tgt: "hash", flag: "both" },
      { src: "签名", tgt: "signature", flag: "both" },
      { src: "公钥", tgt: "public key", flag: "both" },
      { src: "私钥", tgt: "private key", flag: "both" },
      { src: "会话", tgt: "session", flag: "both" },
      { src: "令牌", tgt: "token", flag: "both" },
    ],
  };

  function renderTerms(name) {
    const items = TERMS[name] || [];
    clear(els.termList);
    items.forEach((term) => {
      const flag = h("span", { class: `term-flag ${term.flag === "zh" ? "zh" : term.flag === "both" ? "both" : ""}` }, term.flag.toUpperCase());
      els.termList.appendChild(h("div", { class: "term-row" },
        h("span", { class: "term-source" }, term.src),
        h("span", { class: "term-arrow", "aria-hidden": "true" }, "→"),
        h("span", { class: "term-target" }, term.tgt),
        flag,
      ));
    });
  }

  els.termTabs.forEach((t) => t.addEventListener("click", () => {
    els.termTabs.forEach((tt) => {
      const active = tt === t;
      tt.classList.toggle("active", active);
      tt.setAttribute("aria-selected", String(active));
    });
    renderTerms(t.dataset.term);
  }));
  renderTerms("通用");

  // ============================================================
  // 热键配置 + 冲突检测
  // ============================================================
  const HOTKEYS = [
    { label: "按住说话（流程 A）", key: "Fn", conflict: false },
    { label: "悬浮窗翻译（流程 B）", key: "⌥ Space", conflict: false },
    { label: "划词翻译（流程 C）", key: "⌥ D", conflict: false },
    { label: "静默替换（流程 D）", key: "⌥ ↩", conflict: false },
    { label: "截图 OCR（流程 E）", key: "⌥ S", conflict: true, with: "macOS 截屏默认" },
    { label: "免提 toggle", key: "Fn + Space", conflict: false },
    { label: "双击 ⌥ 打开主窗口", key: "⌥ ⌥", conflict: false },
    { label: "临时禁用全部热键", key: "⌥ ⇧ P", conflict: false },
    { label: "隐私锁", key: "⌥ ⇧ K", conflict: false },
    { label: "显示/隐藏悬浮窗", key: "⌥ ⇧ L", conflict: false },
  ];

  function renderHotkeys() {
    clear(els.hotkeyList);
    HOTKEYS.forEach((hk) => {
      const row = h("div", { class: `hotkey-row ${hk.conflict ? "conflict" : ""}` },
        h("span", { class: "hk-label" }, hk.label),
        h("button", { type: "button", class: "hk-key", title: "点击重新录制" }, hk.key),
        h("span", { class: `hk-status ${hk.conflict ? "err" : "ok"}` }, hk.conflict ? `与 ${hk.with} 冲突` : "可用"),
      );
      els.hotkeyList.appendChild(row);
    });
  }
  renderHotkeys();

  // ============================================================
  // 全局键盘快捷键（演示用）：1-0 → Tab A-J；K/L/M 点 Tab 切换
  // ============================================================
  const HOTKEY_MAP = { "1": "A", "2": "B", "3": "C", "4": "D", "5": "E", "6": "F", "7": "G", "8": "H", "9": "I", "0": "J" };
  document.addEventListener("keydown", (e) => {
    if (e.target.tagName === "INPUT" || e.target.tagName === "TEXTAREA") return;
    if (e.metaKey || e.ctrlKey || e.altKey) return;
    if (HOTKEY_MAP[e.key]) switchTab(HOTKEY_MAP[e.key]);
  });

  // 初始渲染流程 A
  switchTab("A");
})();