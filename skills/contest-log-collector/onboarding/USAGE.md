# 选手使用手册 — AI Coding 日志归集

<!-- install.sh 会把本文件复制到选手仓根目录,文件名 USAGE.md -->

## 这份文档是什么

你拿到组委会建好的 demo 仓后,日志归集工具已经**预装**好了。本手册告诉你:

1. 拿到仓库后第一件事做什么
2. 怎么开始用 AI 工具开发
3. **怎么把对话打包到比赛仓**(关键!)
4. 出了问题怎么办

> **核心架构**: 工具采用**两阶段**设计 — AI 对话先静默落到本机 staging 区(永远不出本机),需要提交到比赛仓时由你**主动说"打包"**才会复制到 demo 仓 logs/。这样你跟 AI 聊任何对话(包括个人项目)都不会被误传到比赛仓。

---

## 30 秒快速通关

```bash
# 1. clone 组委会发给你的 demo 仓
git clone https://github.com/<contest-org>/<your-demo-repo>
cd <your-demo-repo>

# 2. 健康检查 (必做!)
bash .claude/contest/verify-setup.sh

# 3. 跟 AI 工具协作开发
#    所有对话会自动落到 ~/.claude/contest-collector-staging/<your-login>/
#    这个路径在你电脑上,不会被推到任何 git 仓

# 4. 想把这次对话留给评委? 跟 AI 说一句:
#    "archive this session into the contest repo"
#    (或 /contest-snapshot,或 python3 tools/export-session.py --latest)

# 5. 提交代码 + 日志:
git add . && git commit -s -m "..." && git push
```

---

## 1. 拿到仓库后必做的 3 件事

### 1.1 确认 .env 信息正确

```bash
cat ~/.claude/contest-collector.env
```

应该看到:

```
TEAM_ID=contest2026-XXX
GITHUB_LOGIN=<你的 GitHub username>
```

> ⚠️ **如果 GITHUB_LOGIN 不是你**: 改成你自己的 username,否则你的 log 会归到队友名下。

### 1.2 跑健康检查脚本

```bash
bash .claude/contest/verify-setup.sh
```

任何 `[FAIL]` 项都按提示修;不会的发组委会群求助。

### 1.3 (可选) 看一眼 staging

```bash
ls ~/.claude/contest-collector-staging/<your-github-login>/
```

第一次进来应该是空的。第一次结束 AI session 后,会出现 `<date>/<tool>__<sid>.jsonl`。

---

## 2. 启用 AI 工具

支持 **4 种工具**,挑顺手的一个用就行,组委会已经把全局 hook 装好了。

### 2.1 大赛官方主推: Claude Code (CLI 或 AIoT-IDE 内嵌)

#### 用 AIoT-IDE (推荐)

1. 装 AIoT-IDE: 看大赛官方 IDE 使用文档
2. 在 AIoT-IDE 里**任意位置**(包括桌面、子目录、仓外)打开 Claude Code 插件,开始对话
3. 关闭对话 → 自动落 staging

#### 用 Claude Code CLI

```bash
claude   # 任意目录都可以,不必非得在仓里
```

退出时(`/exit` 或 Ctrl+D)自动落 staging。

### 2.2 OpenCode (CLI / TUI / VS Code 扩展)

```bash
opencode
```

OpenCode V1 plugin 已预装,session 结束自动落 staging。

### 2.3 Codex CLI

```bash
codex
```

Stop hook 自动落 staging。

### 2.4 多人组队怎么协作

**每位组员各自做以下事情**:

1. 各自 clone 自己的本地副本
2. **改 `~/.claude/contest-collector.env` 里的 GITHUB_LOGIN 为自己的 username**(很重要!)
3. 跟 AI 工具协作

各自的 staging 互不干扰,各自导出自己的 session 即可。

---

## 3. 怎么把对话打包到比赛仓 (关键!)

工具**不会**自动把对话写进比赛仓。你需要**主动说一句**才会打包。3 种方式选一个:

### 方式 A: 自然语言 (推荐)

跟 AI 说一句:

- "archive this session into the contest repo"
- "把刚才的会话存到比赛仓库"
- "package this conversation"
- "归档对话"

AI 会调用 `tools/export-session.py --latest`,把最近一次 session 从 staging 复制到 `logs/<your-login>/`。

### 方式 B: Slash Command (Claude Code)

```
/contest-snapshot
```

效果同上。

### 方式 C: 直接跑脚本

```bash
# 看看 staging 里有哪些 session
python3 tools/export-session.py --list

# 导出最近一次
python3 tools/export-session.py --latest

# 导出今天所有
python3 tools/export-session.py --today

# 导出指定 session
python3 tools/export-session.py --session <session-id>

# 导出某天起所有
python3 tools/export-session.py --since 2026-06-15

# 全部导出 (用于赛末统一打包)
python3 tools/export-session.py --all

# dry-run 预览不写文件
python3 tools/export-session.py --latest --dry-run
```

### 然后正常 commit + push

```bash
git add logs/
git commit -s -m "logs: capture session"
git push
```

或跟你的代码一起 push:

```bash
git add .   # 自然包含 logs/
git commit -s -m "feat: implement xxx"
git push
```

---

## 4. 隐私保护 — 这个工具到底采集什么

### 4.1 哪些**会**被采集到 staging

只要你跟 AI 工具(Claude Code / OpenCode / Codex / AIoT-IDE)聊天,**所有对话都会进 staging**:

- 在比赛仓里聊
- 在个人项目里聊
- 在 $HOME 聊
- ...所有场景

但 **staging 不会上传** — 它只在你电脑的 `~/.claude/contest-collector-staging/`。

### 4.2 哪些**会**进比赛仓 (= 评委能看到)

**只有你主动导出的那些 session**。

如果你跟 AI 聊了 50 轮,只导出 10 轮,**评委只能看到那 10 轮**,其他 40 轮永远只在你电脑上。

### 4.3 字段清单 (会被记录的内容)

| 字段 | 内容 |
|------|------|
| `text` | 你跟 AI 的对话正文 |
| `thinking` | AI 的思考过程(如工具暴露) |
| `tool_name` / `input` / `output` | AI 调用的工具(read/edit/bash 等) |
| `model` / `tokens_in/out` | 用了哪个模型、token 用量 |
| `seq` | session 内单调递增序号(防作弊) |

### 4.4 自动脱敏

不论是否导出,所有事件都会自动脱敏:

- `sk-*` (OpenAI / Anthropic API key)
- `ghp_*` (GitHub Personal Access Token)
- `Bearer xxx` (HTTP Authorization header)

### 4.5 哪些**不会**被采集

- ❌ 你的 shell 历史 / 环境变量 / 文件系统其他内容
- ❌ AI 工具配置以外的本地文件
- ❌ 浏览器/桌面/其他应用的活动
- ❌ 你的 API key(自动脱敏)

只采集 **AI 工具自己 session transcript 里的内容**。

### 4.6 查看自己导出后的内容

```bash
# 终端预览(彩色)
python3 tools/render-log.py logs/<your-github-login>/

# 生成 HTML 报告(浏览器打开)
python3 tools/render-log.py logs/<your-github-login>/ \
  --format html --out my-report.html
```

---

## 5. 验证工具在工作

### 5.1 看 staging 是否在累积

```bash
# 跟 AI 协作几轮后,新开终端跑:
ls -lt ~/.claude/contest-collector-staging/<your-github-login>/<today>/
```

应该看到 `.jsonl` 文件,大小随对话进展增长。

### 5.2 看 stderr 提示

每次 AI session 结束,collector 会在 stderr 输出:

```
[session-log] captured 3 event(s) -> .../claude-code__abc.jsonl
              (remember to 'git add logs/' when committing)
```

### 5.3 export 后自检合规性

```bash
python3 tools/validate-log.py logs/
```

应该输出 `ALL OK`。报错大概率是工具 bug,发组委会群报。

---

## 6. FAQ

### Q1: 我没说"打包",对话会自己上传吗?

**绝对不会**。工具物理上不会自己 push 到任何 git 仓。staging 在 `~/.claude/contest-collector-staging/`,跟 git 无关。

### Q2: 我跟 AI 聊了私事(工资/感情/其他项目),会泄漏吗?

**只要你不主动说"打包"**,这些对话**永远不会**进比赛仓。它们只存在于你电脑的 staging。

如果你担心,**可以删 staging 里对应文件**(在你导出之前):

```bash
ls ~/.claude/contest-collector-staging/<your-login>/<date>/
rm <session-id>.jsonl
```

### Q3: 我能改 staging / logs 里的内容吗?

`tools/validate-log.py` 会检测 seq 缺号、跨字段不一致、manifest 与文件对不上等手脚,**改 log 等于作弊**。

但**删除整个 session**(导出前在 staging 删除)是允许的 — 这跟"不打包"等价,评委看不到。

### Q4: 我能临时关掉日志收集吗?

**不建议**,大赛规则要求全程归集(staging 全采)。你能控制的是**导出哪些**到比赛仓,这是设计上给选手的隐私边界。

### Q5: 截止时刻怎么办?

截止时间一到,组委会会:

1. 把仓库权限从 write 降为 read(你不能再 push)
2. 触发最终 archive

**截止前几小时**:

```bash
# 看看还有多少没导出的 session
python3 tools/export-session.py --list

# 一次性全导出
python3 tools/export-session.py --all
git add logs/ && git commit -s -m "logs: final batch" && git push
```

### Q6: 工具有 bug / 没采到怎么办?

按以下顺序处理:

1. `bash .claude/contest/verify-setup.sh` 先看健康检查
2. `cat ~/.claude/contest-collector-staging/<your-login>/errors/*.err` 看是不是有错误日志
3. 实在搞不定,在大赛技术支持群报问题

### Q7: 我从仓的子目录(比如 `cd src && claude`)启动 AI 行不行?

**完全行**。新架构下 hook 是**全局**的,不论你 cwd 在哪,只要跟 Claude Code/OpenCode/Codex 聊天,都会进 staging。

### Q8: 我有多个 demo 仓(主仓 + 子模块),log 怎么归?

按大赛规则,**所有 log 统一汇集到主 demo 仓**。子模块仓不需要装日志工具,在主仓里跑 `export-session.py` 即可。

### Q9: 我用 ChatGPT / Cursor / Cody / 其他工具行不行?

**目前不支持**。本届大赛官方支持的工具是:

- Claude Code(主推,含 AIoT-IDE 内嵌)
- AIoT-IDE
- OpenCode
- Codex

用其他工具产生的对话**不会进 staging**,等同于无效工时。

### Q10: 我用了 Anthropic API / OpenAI API 直接调,行吗?

不行。直接调 API 的对话**不在 session transcript 里**,工具采不到。必须用上面 4 个工具之一。

---

## 7. 工具自带文件清单

组委会建仓时会预装这些文件:

```
<your-demo-repo>/
├── .gitignore                        # 已加日志相关排除
├── .claude/
│   ├── shared/                       # snapshot core (export 工具用)
│   ├── commands/contest-snapshot.md  # slash command
│   └── contest/verify-setup.sh       # 健康检查
├── .opencode/
│   └── plugins/contest-collector.js  # OpenCode plugin
├── tools/
│   ├── export-session.py             # 主动导出工具 (核心!)
│   ├── render-log.py                 # 日志渲染
│   └── validate-log.py               # 防作弊校验
├── schema/                           # JSONL 契约
├── USAGE.md                          # 本文件
├── JUDGE_GUIDE.md                    # 评委指南
└── logs/                             # 导出后才会有
```

另外,组委会还在你的 home 目录装了一份**全局 hook**:

```
~/.claude/
├── settings.json                       # 注入了 Stop/SessionEnd hook
├── contest-collector.env               # 你的身份 (TEAM_ID + GITHUB_LOGIN)
├── contest-shared/                     # 全局 hook
│   ├── snapshot_core.py
│   ├── get_github_login.py
│   └── contest-snapshot.sh
└── contest-collector-staging/          # staging 区 (你的所有 AI 对话)
    └── <your-github-login>/
        ├── manifest.json
        └── <date>/<tool>__<sid>.jsonl
```

**全局 hook 不会自己 push**,只在你电脑本地写文件。push 由你自己控制。

---

## 8. 反馈与支持

- 技术问题: 大赛技术支持群(组委会拉)
- 工具 bug: `https://github.com/open-vela/.claude/issues`
- 隐私 / 数据相关问题: 组委会邮箱

---

> **祝你比赛顺利!好好享受跟 AI 一起码代码的过程,日志的事我们包了。**
