"""debug 构建 —— 抓取 null check 完整堆栈。"""
import sys
import time
from playwright.sync_api import sync_playwright

errors = []

with sync_playwright() as pw:
    browser = pw.chromium.launch()
    ctx = browser.new_context(viewport={'width': 1280, 'height': 800}, service_workers='block')
    page = ctx.new_page()
    page.on('console', lambda m: errors.append(m.text) if m.type == 'error' else None)
    page.on('pageerror', lambda e: errors.append('PAGEERROR: ' + str(e)))
    page.goto('http://localhost:8137/#tab=A', wait_until='load')
    page.wait_for_selector('canvas', timeout=30000)
    time.sleep(4)
    browser.close()

for e in errors[:12]:
    print(e[:900])
    print('=' * 70)
print('total errors:', len(errors))
