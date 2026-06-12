# 选手使用手册 — AI Coding 日志自动归集

<!-- install.sh 会把本文件复制到选手仓根目录,文件名 USAGE.md -->

## 这份文档是什么

你拿到组委会建好的 demo 仓后,日志归集工具已经**预装**好了。本手册告诉你:

1. 拿到仓库后第一件事做什么(2 分钟)
2. 怎么开始用 AI 工具开发
3. 日志怎么跟代码一起 push 上去
4. 出了问题怎么办

> **核心承诺**: collector 只把日志写到 `logs/` 目录,**不会自动 commit 或 push**。你像平时一样写代码、`git push`,日志会跟代码一起上去。

---

## 30 秒快速通关

```bash
# 1. clone 组委会发给你的 demo 仓
git clone https://github.com/<contest-org>/<your-demo-repo>
cd <your-demo-repo>

# 2. 健康检查 (必做!)
bash .claude/contest/verify-setup.sh

# 3. 看到 "ALL OK" 就可以开始用 AI 工具开发了

# 4. 跟 AI 协作完写完代码后,正常 git push 就行:
git add .
git commit -s -m "你的提交信息"
git push
```

`git add .` 默认会把 `logs/` 目录带上,无需额外操作。

---

## 1. 拿到仓库后必做的 3 件事

### 1.1 确认 .env 信息正确

```bash
cat .env | grep -E '^(TEAM_ID|GITHUB_LOGIN)'
```

应该看到:

```
TEAM_ID=contest2026-XXX           # 组委会分配的官方匿名编号
GITHUB_LOGIN=<你的 GitHub username>
```

> ⚠️ **如果 GITHUB_LOGIN 不是你**: 你大概率拿到了队友的仓配置。改成你自己的 username,否则你的 log 会归到队友名下。

### 1.2 跑健康检查脚本

```bash
bash .claude/contest/verify-setup.sh
```

任何 `[FAIL]` 项都按提示修;不会的发组委会群求助。

### 1.3 (可选) 看一眼 logs/ 目录

```bash
ls logs/
```

第一次进来应该是空的。第一次跟 AI 工具结束 session 后,会自动出现:

```
logs/<your-github-login>/<date>/<tool>__<session-id>.jsonl
```

---

## 2. 启用 AI 工具

支持 **4 种工具**,挑你顺手的一个用就行,组委会已经把 hook 全部预装好了。

### 2.1 大赛官方主推: Claude Code (CLI 或 AIoT-IDE 内嵌)

#### 用 AIoT-IDE (推荐)

1. 装 AIoT-IDE: 看大赛官方 IDE 使用文档(组委会群里有链接)
2. 在 AIoT-IDE 里打开你的 demo 仓目录
3. 打开 Claude Code 插件(右侧边栏),开始对话
4. 收工时**关闭 AIoT-IDE 窗口** 或 **结束 Claude Code 对话** → 日志自动落 `logs/`

#### 用 Claude Code CLI

```bash
cd <your-demo-repo>
claude
```

退出时(`/exit` 或 Ctrl+D)自动归集。

> ✅ **验证**: 第一次结束 session 后,跑 `ls logs/<your-github-login>/`,应该看到当天日期目录,里面有 `.jsonl` 文件。

### 2.2 OpenCode (CLI / TUI / VS Code 扩展)

```bash
cd <your-demo-repo>
opencode
```

OpenCode V1 plugin 已经预装在 `.opencode/plugins/contest-collector.js`,session 结束自动归集。

### 2.3 Codex CLI

```bash
cd <your-demo-repo>
codex
```

Stop hook 自动归集。

### 2.4 多人组队怎么协作

**每位组员各自做以下事情**:

1. 各自 clone 自己的本地副本
2. **改 .env 里的 GITHUB_LOGIN 为自己的 username**(很重要!)
3. 跟 AI 工具协作

日志会按 `logs/<github-login>/` 一人一目录区分,**多人组员之间天然不冲突** — 因为各自只写自己的目录。每位组员 push 自己代码时,带上自己 `logs/<own_login>/` 即可。

---

## 3. 怎么把日志 commit 上去

跟你正常 push 代码的流程一样,**记得让 `logs/` 跟着进入 commit**:

```bash
# 看 git 状态,应该能看到 logs/<your-github-login>/<date>/*.jsonl 待 stage
git status

# 推荐写法 — 一把全 stage
git add .

# 或者精确写法 — 别忘了 logs/
git add src/ logs/

# commit + push
git commit -s -m "feat: implement xxx"
git push
```

**关键**: 只要你**正常做代码 commit**,`git add .` 就会带上 `logs/`,无需额外操作。

> 💡 **如果你单独跑了一晚上 AI 但不想立刻 push 代码**: 可以单独 commit 日志:
> ```bash
> git add logs/
> git commit -s -m "logs: capture session yyyy-mm-dd"
> git push
> ```

---

## 4. 日志包含什么 / 隐私保护

### 4.1 日志包含

| 字段 | 内容 | 评分用途 |
|------|------|----------|
| `text` | 你跟 AI 的对话正文 | 看你是怎么提问、怎么迭代的 |
| `thinking` | AI 的思考过程(如工具暴露) | 看 AI 推理过程 |
| `tool_name` / `input` / `output` | AI 调用的工具(read/edit/bash 等) | 看 AI 的实际操作链 |
| `model` / `tokens_in/out` | 用了哪个模型、token 用量 | 资源使用统计 |
| `seq` | session 内单调递增序号 | 防作弊核心 |

### 4.2 自动脱敏

工具会自动正则识别并脱敏:

- `sk-*` (OpenAI / Anthropic API key 格式)
- `ghp_*` (GitHub Personal Access Token)
- `Bearer xxx` (HTTP Authorization header)

脱敏后写入 `redacted_count` 字段,评委可以看到"脱敏了几处",但看不到原文。

### 4.3 哪些东西**不会**被收集

- ❌ 你的 shell 历史 / 环境变量 / 文件系统其他内容
- ❌ AI 工具配置以外的本地文件
- ❌ 你的 Mify / Anthropic / OpenAI API key(自动脱敏)
- ❌ 浏览器/桌面/其他应用的活动

只收集 **AI 工具自己 session transcript 里的内容**。

### 4.4 想看自己的 log

```bash
# 终端预览(彩色)
python3 tools/render-log.py logs/<your-github-login>/

# 生成 HTML 报告(浏览器打开)
python3 tools/render-log.py logs/<your-github-login>/ \
  --format html --out my-report.html
```

---

## 5. 怎么验证日志真的在归集

### 5.1 实时检查文件

```bash
# 跟 AI 协作几轮后,新开终端跑:
ls -lt logs/<your-github-login>/<today-date>/
```

应该看到一个或多个 `.jsonl` 文件,大小随对话进展增长。

### 5.2 查看 stderr 提示

每次 AI session 结束,collector 会在 stderr 输出一行:

```
[session-log] captured 3 event(s) -> logs/yanxingyu17/2026-06-15/claude-code__abc.jsonl
              (remember to 'git add logs/' when committing)
```

**没看到这行 = 没采到**。检查:
- `.env` 里 `TEAM_ID` 是否设了
- AI 工具是不是从 demo 仓**目录或子目录**启动的

### 5.3 自检合规性

```bash
python3 tools/validate-log.py logs/
```

应该输出 `ALL OK`。如果报错,大概率是工具 bug,发组委会群报。

### 5.4 检查 GitHub 远端

`git push` 之后打开 `https://github.com/<contest-org>/<your-demo-repo>/tree/main/logs`,应该能在浏览器里看到你的目录和最新文件。

---

## 6. FAQ

### Q1: collector 会不会跟我自己 push 代码冲突?

**不会**。collector 只往 `logs/` 目录写文件,**不会自己 commit,也不会自己 push**。

你的 `git push` 跟 collector 工作完全独立。只要你提交代码时记得 `git add .`,日志就会跟代码一起进入这次 commit,push 时一起上去。

### Q2: 我能不能临时关掉日志收集?

**不建议**。大赛规则要求全程归集,中断会被评委质疑。

如果**真的**有敏感场景(比如演示时需要输入私人 token):

1. 那段对话改用其他途径(微信/飞书直接问队友)
2. 或者换个不在 demo 仓的目录跑 AI 工具

### Q3: 日志会被公开吗?

- **比赛期间**: 仓库 public(按官方提交指南要求),但选手仓只对组委会和评委集中查看
- **比赛结束**: 由组委会决定归档策略

### Q4: 我能改 logs/ 里的内容吗?

❌ **绝对不要改**。`tools/validate-log.py` 会检测 seq 缺号、跨字段不一致、manifest 与文件对不上等手脚,**改 log 等于作弊**。

### Q5: 工具有 bug / 没采到 log 怎么办?

按以下顺序处理:

1. `bash .claude/contest/verify-setup.sh` 先看健康检查
2. `cat logs/<your-github-login>/errors/*.err` 看是不是有错误日志
3. 实在搞不定,在大赛技术支持群报问题,提供:
   - 你的 TEAM_ID
   - 用的 AI 工具(Claude Code / OpenCode / Codex / AIoT-IDE)
   - 错误信息截图

### Q6: 我从仓的子目录(比如 `cd src && claude`)启动 AI 行不行?

**行**。组委会同时装了**全局 hook**(`~/.claude/contest-shared/`),不论你 cwd 是仓根、子目录,还是从桌面图标启动 IDE,都能正确把日志写到 `logs/<your-github-login>/`。

唯一不工作的场景: cwd **完全不在 demo 仓内**(比如在 `$HOME` 跟 AI 聊天)。这种情况 collector silent exit,什么都不写 — 这是设计上的安全行为,避免污染你跟 AI 的其他个人项目对话。

### Q7: 我有多个 demo 仓(主仓 + 子模块),log 怎么归?

按大赛规则,**所有 log 统一汇集到主 demo 仓**。子模块仓不需要装日志工具,在主仓里跑 AI 即可。

### Q8: 我用 ChatGPT / Cursor / Cody / 其他工具行不行?

**目前不支持**。本届大赛官方支持的工具是:

- Claude Code(主推,含 AIoT-IDE 内嵌)
- AIoT-IDE
- OpenCode
- Codex

用其他工具产生的对话**不会被归集**,等同于无效工时。

### Q9: 我用了 Anthropic API / OpenAI API 直接调,不用工具,行吗?

不行。直接调 API 的对话**不在 session transcript 里**,工具采不到。必须用上面 4 个工具之一。

### Q10: 截止时刻仓库会发生什么?

截止时间一到,组委会会:

1. 把仓库权限从 write 降为 read(你不能再 push)
2. 触发最终 archive(打 release tag,生成快照)

**截止前几小时**:确保你最后一次 AI session 已正常结束,跑一次 `git status` 确认 `logs/` 全部已 commit、`git push` 一次确保上去了。

---

## 7. 工具自带文件清单

组委会建仓时会预装这些文件,**你不需要改它们**:

```
<your-demo-repo>/
├── .env                              # TEAM_ID + GITHUB_LOGIN (你需要确认 login)
├── .gitignore                        # 已加日志相关排除
├── .claude/
│   ├── settings.json                 # Claude Code hooks 配置
│   ├── hooks/contest-snapshot.sh     # 仓内 Stop / SessionEnd hook
│   ├── shared/                       # snapshot core + github_login 探测
│   └── contest/verify-setup.sh       # 健康检查
├── .opencode/
│   └── plugins/contest-collector.js  # OpenCode plugin
├── tools/
│   ├── render-log.py                 # 日志渲染(终端/Markdown/HTML)
│   └── validate-log.py               # 防作弊校验
├── schema/
│   ├── event.schema.json             # JSONL 事件契约
│   └── manifest.schema.json          # 索引契约
├── USAGE.md                          # 本文件
├── JUDGE_GUIDE.md                    # 评委指南
└── logs/                             # 你的日志会自动出现在这里
```

另外,组委会还在你的 home 目录装了一份**全局 hook**:

```
~/.claude/
├── settings.json                     # 注入了 Stop/SessionEnd hook
└── contest-shared/                   # 全局 hook 自带的 snapshot core
    ├── snapshot_core.py
    ├── get_github_login.py
    └── contest-snapshot.sh
```

全局 hook 只在 demo 仓内生效(检查 `.env` 里的 `TEAM_ID=team-*` 行),你跟 AI 聊**其他个人项目**完全不受影响。

---

## 8. 反馈与支持

- 技术问题: 大赛技术支持群(组委会拉)
- 工具 bug: `https://github.com/open-vela/.claude/issues`
- 隐私 / 数据相关问题: 组委会邮箱

---

> **祝你比赛顺利!好好享受跟 AI 一起码代码的过程,日志的事我们包了。**
