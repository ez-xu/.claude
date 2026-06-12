---
name: contest-log-collector
description: "为 openvela AI 大赛归集 AI Coding 日志,采用 staging + 显式导出 双层架构。后台 hook 把所有 session 静默写到选手机器本地 staging (~/.claude/contest-collector-staging/),完全不进选手仓。选手说'帮我打包这次会话/把这个 session 存到比赛仓库/contest-snapshot'时,AI 调用 export-session.py 把指定 session 从 staging 复制到选手仓的 logs/<github_login>/,选手 git push 时跟代码一起上去。Trigger: 大赛 AI 日志收集、contest log、AI Coding 日志、打包对话、archive session、归档会话、export session、把会话存到仓库、保存这次对话、把这个 session 提交、contest-snapshot."
---

# Contest Log Collector — openvela AI 大赛 AI Coding 日志归集

为 openvela AI 大赛提供 AI Coding 日志归集能力,**两阶段、选手知情同意**。

## 核心架构

```
       ┌─────────────────────────────────────────────────────┐
       │ 阶段 1 (后台采集): 选手机器本地 staging              │
       │ 路径: ~/.claude/contest-collector-staging/<login>/   │
       │ 不出本机,不进任何 git 仓                             │
       └─────────────────────────────────────────────────────┘
                              │
                              │ 选手说"打包这次会话" / 跑 /contest-snapshot
                              │ / 直接执行 export-session.py
                              ↓
       ┌─────────────────────────────────────────────────────┐
       │ 阶段 2 (选手主动导出): demo 仓 logs/<login>/          │
       │ 选手 git push 时跟代码一起上 GitHub                  │
       └─────────────────────────────────────────────────────┘
```

**关键安全特性**: 选手个人项目跟 AI 聊的对话也会进 staging,但 staging **永远不上传**,选手不主动导出 = 选手仓里啥都没有。

## 选手怎么触发"打包"

支持 3 种方式,挑顺手的:

### 1. 自然语言(推荐 — Claude Code / OpenCode 都支持)

直接对 AI 说:

- "帮我打包这次会话"
- "把这个 session 存到比赛仓库"
- "归档刚才的对话"
- "archive this session"

AI 会读到本 SKILL,自动调用 `tools/export-session.py --latest`。

### 2. Slash command(Claude Code 支持)

```
/contest-snapshot
```

定义在 `.claude/commands/contest-snapshot.md`,触发与上面相同。

### 3. 直接跑脚本(任何工具都行)

```bash
# 导出最近一次 session
python3 tools/export-session.py --latest

# 导出今天所有 session
python3 tools/export-session.py --today

# 列出 staging 里所有 session
python3 tools/export-session.py --list

# 导出指定 session
python3 tools/export-session.py --session <session-id>
```

## 目录结构

```
contest-log-collector/
├── SKILL.md                       # 本文件
├── commands/
│   └── contest-snapshot.md        # slash command 定义
├── onboarding/
│   ├── install.sh                 # 主入口
│   ├── verify-setup.sh            # 健康检查
│   ├── JUDGE_GUIDE.md             # 评委指南 (装到选手仓根)
│   └── USAGE.md                   # 选手手册 (装到选手仓根)
├── adapters/
│   ├── opencode/collector.js      # OpenCode V1 plugin
│   ├── shared/                    # Claude Code + Codex 共用
│   │   ├── snapshot_core.py
│   │   ├── get_github_login.py
│   │   └── get_github_login.js
├── schema/
│   ├── event.schema.json
│   └── manifest.schema.json
└── tools/
    ├── export-session.py          # 选手主动导出工具 (核心)
    ├── render-log.py              # 评委渲染工具
    └── validate-log.py            # 防作弊校验
```

## 组委会预装(建仓时)

```bash
git clone --depth 1 -b dev-ai-contest-2026 \
  https://github.com/open-vela/.claude.git /tmp/clt
cd <选手仓路径>
bash /tmp/clt/skills/contest-log-collector/onboarding/install.sh \
  --team-id contest2026-042 \
  --github-login <login>
git add -A && git commit -m "init: contest-log-collector preinstalled"
git push
```

`install.sh` 安装项:

- **本机**:
  - `~/.claude/contest-collector.env` — 选手身份(TEAM_ID + GITHUB_LOGIN)
  - `~/.claude/contest-shared/` — snapshot core + 全局 hook 脚本
  - `~/.claude/settings.json` — 注册 Stop / SessionEnd hook(deep merge,保留原有配置)
  - `~/.claude/contest-collector-staging/` — staging 区
- **选手仓**:
  - `.claude/shared/` — snapshot core(给 export 工具用)
  - `.claude/commands/contest-snapshot.md` — slash command
  - `.opencode/plugins/contest-collector.js` — OpenCode plugin
  - `tools/export-session.py` + `render-log.py` + `validate-log.py`
  - `schema/event.schema.json` + `manifest.schema.json`
  - `JUDGE_GUIDE.md` — 评委指南
  - `USAGE.md` — 选手手册
  - `.gitignore` — 已加日志相关排除

## 数据契约

JSONL 每条事件必含字段:

- `schema_version` — 当前 1.0
- `session_id` — AI 工具内部 session ID
- `team_id` — 对应仓库的官方匿名编号
- `github_login` — 当前组员 GitHub username
- `tool` — opencode / claude-code / codex / kiro
- `seq` — session 内单调递增(防作弊核心)
- `ts` — ISO 8601 UTC 时间戳
- `role` — user / assistant / tool / system

## 安全特性

- **隐私默认安全**: staging 在本机,不主动导出 → 任何对话不进选手仓
- **自动脱敏**: 默认正则覆盖 `sk-*` (API key) / `ghp_*` (GitHub token) / `Bearer *` (auth header)
- **TEAM_ID 缺失主动拒绝**: 防止数据归属错乱
- **多人组天然安全**: staging 按 `<github_login>/` 一人一目录,组员之间互不干扰

## 工具兼容性

| 工具 | 形态 | 状态 |
|------|------|------|
| Claude Code (大赛主推) | CLI / AIoT-IDE 内嵌 | ✅ 完全支持(包括 slash command) |
| AIoT-IDE | VS Code fork + Claude Code 插件 | ✅ 完全支持 |
| OpenCode | CLI / TUI / VS Code 扩展 | ✅ 完全支持 |
| Codex | CLI | ✅ 自然语言触发 |
| Kiro | IDE | ⏸️ 暂未实现 |

## License

Apache 2.0,跟仓库其他 skills 一致。
