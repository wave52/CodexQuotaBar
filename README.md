# Codex Quota Bar

一个原生 macOS 菜单栏小应用，用本机 Codex CLI 的只读 app-server 协议展示真实账户额度。

## 功能

- 菜单栏直接显示主要额度的剩余百分比
- 展示 Codex 返回的所有额度窗口、已用百分比和重置时间
- 周额度拆成 7 段，每段对应约一天的预算（14.3%）
- 用量条下方显示同刻度的青色时间进度条，按重置时间和实际周期计算，弹窗打开时每秒更新，百分比保留两位小数
- 每 5 分钟自动刷新，也可以手动刷新
- 不保存 Cookie、访问令牌或账户密码

## 运行要求

- macOS 14 或更高版本
- 已安装并登录 Codex CLI（`codex login status` 应显示已登录）
- Codex CLI 位于 `/usr/local/bin/codex`、`/opt/homebrew/bin/codex` 或 `~/.local/bin/codex`

## 构建

```bash
cd CodexQuotaBar
chmod +x scripts/build-app.sh
./scripts/build-app.sh
open "dist/Codex Quota Bar.app"
```

应用是本地 ad-hoc 签名。第一次打开若被 Gatekeeper 拦截，请在 Finder 中右键应用并选择“打开”。需要开机启动时，可以在“系统设置 → 通用 → 登录项”里添加它。

## 数据说明

应用调用本机 `codex app-server --stdio`，完成初始化后只请求 `account/rateLimits/read`。该协议随 Codex CLI 一起提供，但目前属于实验性 app-server 接口；若将来的 Codex 版本变更字段，应用会显示读取错误，不会用缓存数字冒充最新额度。
