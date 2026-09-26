"""LinguaFlow Web 冒烟测试 —— 对齐原型 smoke_v72 思路。
逐 hash 打开 15 页：① 无 JS 错误 ② Flutter 画布渲染非空白 ③ 每页截图。
"""
import json
import sys
import time
from pathlib import Path

from playwright.sync_api import sync_playwright

BASE = 'http://localhost:8137/#tab='
TABS = list('ABCDEFGHIJKLMNO')
SHOTS = Path('/root/.codebuddy/artifact/shots_flutter')
SHOTS.mkdir(parents=True, exist_ok=True)

results = []
js_errors = []

def canvas_variance(png_bytes: bytes) -> float:
    """粗略检测截图是否空白：像素字节方差过低 ≈ 纯色空白页。"""
    from PIL import Image
    import io
    img = Image.open(io.BytesIO(png_bytes)).convert('L').resize((160, 100))
    px = list(img.getdata())
    mean = sum(px) / len(px)
    return sum((v - mean) ** 2 for v in px) / len(px)

with sync_playwright() as pw:
    browser = pw.chromium.launch()
    # 屏蔽 service worker，避免缓存旧版产物
    ctx = browser.new_context(viewport={'width': 1280, 'height': 800}, service_workers='block')
    page = ctx.new_page()
    page.on('pageerror', lambda e: js_errors.append(str(e)))
    page.on('console', lambda m: js_errors.append(m.text) if m.type == 'error' else None)

    for i, tab in enumerate(TABS):
        page = ctx.new_page()  # 独立 page：hash 变化属 same-document，必须新 page 才会重新加载
        page.on('pageerror', lambda e, t=tab: js_errors.append(f'{t}: {e}'))
        page.on('console', lambda m, t=tab: js_errors.append(f'{t}: {m.text}') if m.type == 'error' else None)
        page.goto(BASE + tab)
        try:
            # 等待 Flutter 画布（flutter-view 内 canvas / flt-glass-pane）
            page.wait_for_selector('flutter-view canvas, canvas', timeout=20000)
            time.sleep(2.2)  # 等首帧动画/种子数据渲染稳定
            png = page.screenshot(path=str(SHOTS / f'{tab}.png'))
            var = canvas_variance(png)
            ok = var > 50
            results.append({'tab': tab, 'canvas_variance': round(var, 1), 'ok': ok})
        except Exception as exc:  # noqa: BLE001
            results.append({'tab': tab, 'error': str(exc)[:120], 'ok': False})
        finally:
            page.close()

    browser.close()

print(json.dumps(results, ensure_ascii=False, indent=1))
failed = [r for r in results if not r.get('ok')]
print(f'JS/Console errors: {len(js_errors)}')
for e in js_errors[:8]:
    print('  -', e[:160])
print('PASS' if not failed and not js_errors else f'FAIL pages={failed}')
sys.exit(0 if not failed and not js_errors else 1)
