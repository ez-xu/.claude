---
name: contest-log-collector
description: "为 openvela AI 大赛自动归集 AI Coding 日志。监听 AI 工具 (OpenCode / Claude Code / Codex / AIoT-IDE) 的 session 结束事件,把对话 trace 转成 JSONL,写入选手仓的 logs/<github_login>/<date>/。collector 只写文件不动 git,选手 commit 代码时跟 logs/ 一起 push 即可。组委会建仓时通过 onboarding/install.sh 预装到选手仓,选手零配置无感使用。Trigger: 大赛 AI 日志收集、contest log、AI Coding 日志、session 采集、对话归档、AIoT-IDE log。"
---

# Contest Log Collector — openvela AI 大赛 AI Coding 日志采集

为 openvela AI 大赛提供 AI Coding 日志自动归集能力。组委会建仓时预装,选手在 AI 工具(Claude Code / AIoT-IDE / OpenCode / Codex)中正常工作,日志自动落到 `logs/<github_login>/`,选手 push 自己代码时一起带上仓即可。

## 核心承诺

实现大赛参赛代码提交指南中的关键承诺:

> AI Coding 日志由预置插件自动归集到仓库的 `logs/` 目录,无需手动整理或打包。选手 `git commit && git push` 自己代码时,`logs/` 跟代码一起上去就行。

## 目录结构

```
contest-log-collector/
├─ SKILL.md                            # 本文件
├─ onboarding/
│  ├─ install.sh                       # 主入口 (组委会建仓时调用)
│  ├─ verify-setup.sh                  # 健康检查
│  └─ JUDGE_GUIDE.md                   # 评委查看指南 (复制到选手仓根目录)
├─ adapters/                           # 4 工具 hook/plugin
│  ├─ opencode/collector.js            # OpenCode V1 plugin
│  ├─ claude-code/                     # Claude Code Stop+SessionEnd hook
│  ├─ codex/                           # Codex Stop hook
│  └─ shared/                          # Claude+Codex 共享 Python 核心
│     ├─ snapshot_core.py
│     ├─ get_github_login.py           # 5 级优先链探测 GitHub username
│     └─ get_github_login.js
├─ schema/
│  ├─ event.schema.json                # JSONL 单条事件契约
│  └─ manifest.schema.json             # 索引文件契约
└─ tools/
   ├─ render-log.py                    # 评委本地渲染 (终端/Markdown/HTML)
   └─ validate-log.py                  # 防作弊校验 (seq 单调 + 跨字段一致)
```

## 组委会使用 (建仓时预装)

```bash
# 在 ops/create-repos.py 内对每个新建的选手仓:
git clone --depth 1 -b dev-ai-contest-2026 \
  https://github.com/open-vela/.claude.git /tmp/clt
cd <选手仓路径>
bash /tmp/clt/skills/contest-log-collector/onboarding/install.sh \
  --team-id contest2026-042 \
  --github-login <login>
git add -A && git commit -m "init: contest-log-collector preinstalled"
git push
```

`install.sh` 自动:

- 装 `.claude/hooks/contest-snapshot.sh` + `.claude/shared/{snapshot_core.py, get_github_login.py}`
- 装 `.opencode/plugins/contest-collector.js`
- 装 `tools/render-log.py` + `tools/validate-log.py` (评委用)
- 装 `JUDGE_GUIDE.md` (评委指南)
- 写 `.env` (TEAM_ID + GITHUB_LOGIN)
- 更新 `.gitignore`
- 输出 `.claude/contest-settings.snippet.json` 让组委会合并到 `.claude/settings.json`

## 选手使用

完全无感。组委会预装好后,选手只需要:

1. clone 自己的 demo 仓
2. 启动 AI 工具 (Claude Code / AIoT-IDE / OpenCode / Codex)
3. 跟 AI 协作开发

日志会自动写入 `logs/<github_login>/<date>/<tool>__<sid>.jsonl`。collector 只写文件,**不会自动 commit 或 push**。选手按官方代码提交流程正常 `git add . && git commit && git push` 时,`logs/` 跟自己的代码一起上去即可。

`git add .` 默认会包含 `logs/` 目录,无需手动指定。如果选手用 `git add <specific-files>` 精确暂存,记得也加上 `git add logs/`。

## 评委使用

每个选手仓根目录都有 `JUDGE_GUIDE.md`。摘要:

```bash
# 终端预览 (彩色)
python3 tools/render-log.py logs/<github_login>/

# 生成 HTML 评分报告
python3 tools/render-log.py logs/<github_login>/ \
  --format html --out report.html

# 防作弊校验
python3 tools/validate-log.py logs/
# ALL OK = 数据合规 / ERRORS = 选手可能改过 logs
```

## 数据契约

JSONL 每条事件必含字段:

- `schema_version` — 当前 1.0
- `session_id` — AI 工具内部 session ID
- `team_id` — 对应仓库的官方匿名编号 (如 `contest2026-042`)
- `github_login` — 当前组员 GitHub username
- `tool` — opencode / claude-code / codex / kiro
- `seq` — session 内单调递增 (防作弊核心)
- `ts` — ISO 8601 UTC 时间戳
- `role` — user / assistant / tool / system

可选字段: `text` / `thinking` / `tool_name` / `tool_call_id` / `input` / `output` / `model` / `tokens_in` / `tokens_out` / `redacted_count`

## 安全特性

- **自动脱敏**: 默认正则规则覆盖 `sk-*` (API key) / `ghp_*` (GitHub token) / `Bearer *` (auth header)
- **无截断**: 大赛跨度长,所有内容完整保留以支持后期分析
- **错误可观察**: 失败写 `errors/<ts>.err`,不静默吞
- **TEAM_ID 缺失主动拒绝**: 防止数据归属错乱
- **多人组队天然安全**: collector 只写 `logs/<github_login>/<own>` 自己的目录,组员之间互不干扰;commit 时各自 `git add logs/<own_login>/` 即可

## 工具兼容性

| 工具 | 形态 | 状态 |
|------|------|------|
| Claude Code (大赛主推) | CLI / AIoT-IDE 内嵌插件 | 完全支持 |
| AIoT-IDE (大赛主推) | VS Code fork + Claude Code 插件 | 完全支持 (复用 Claude Code adapter) |
| OpenCode | CLI / TUI / VS Code 扩展 | 完全支持 |
| Codex | CLI | 代码完成,无真实环境验证 |
| Kiro | IDE | 暂未实现 |

## License

Apache 2.0,跟仓库其他 skills 一致。
