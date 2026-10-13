# 会议纪要保存工具

![工具效果图](screen-shot.png)

## 功能

- 从 macOS 剪贴板读取圆宝 Markdown 会议纪要
- 支持 `fzf` 选择历史会议主题
- 支持 Alfred 弹窗输入会议主题，或用 Alfred 关键词直接传入主题
- 自动按当天日期和会议主题命名
- 自动写入 YAML 元数据，方便后续 AI 分析
- 自动处理重名文件
- 支持全文搜索历史纪要，实时预览并打印正文

## 默认保存位置

```text
~/Documents/meeting_notes
```

可通过环境变量修改：

```bash
export MEETING_NOTES_DIR="$HOME/Documents/meetings/tencent"
```

## 使用方式

### fzf 方式

1. 在圆宝中复制 Markdown 纪要。
2. 进入工具目录后运行：

```bash
./meeting-note-fzf.sh
```

3. 在 `fzf` 中选择历史会议主题，或输入新主题。
4. 文件会自动保存到 `MEETING_NOTES_DIR`。

如果想在任意目录用短命令，可在 `~/.zshrc` 中加入：

```bash
export MEETING_NOTE_TOOL_DIR="/path/to/alfred-meeting-note-workflow"
alias mn='"$MEETING_NOTE_TOOL_DIR/meeting-note-fzf.sh"'
```

之后使用：

```bash
mn
```

也可以直接传入标题，跳过 `fzf`：

```bash
mn 产品例会
```

未传标题时会进入 `fzf` 交互选择；传入标题时会直接保存，不进入 `fzf`。

如果前一天的纪要第二天才上传，可以指定会议日期：

```bash
mn --date 20260611 产品例会
```

日期会用于文件名和 YAML 元数据。支持格式包括：

```text
20260611
2026-06-11
2026/6/11
2026.6.11
2026年6月11日
```

### 快捷键方式

1. 在圆宝中复制 Markdown 纪要。
2. 触发 Alfred Workflow 热键。
3. 输入会议主题。
4. 文件会自动保存到 `MEETING_NOTES_DIR`。

导入后需要在 Alfred 中手动设置热键。

### 关键词方式

1. 在圆宝中复制 Markdown 纪要。
2. 打开 Alfred。
3. 输入：

```text
mn 产品例会
```

4. 回车保存。

### 搜索方式

在已保存的纪要里按关键词搜索（标题 + 全文），实时预览，回车打印正文：

```bash
mn search
```

进入 fzf 交互界面，左侧只显示文件名，输入关键词实时搜索（标题命中优先），右侧高亮显示匹配内容，回车把正文打印到终端。

也可以直接传入关键词作为初始查询：

```bash
mn search 预算
```

## 文件命名

```text
YYYY-MM-DD_会议主题.md
```

如果同名文件已存在，会询问处理方式：

- 覆盖
- 另存副本
- 合并
- 取消

选择合并时，会调用 Claude CLI 合并已有纪要和剪贴板里的新增纪要，并写回原文件。适用于腾讯会议因为限时中断被拆成两段纪要的场景。

选择另存副本时，会自动生成：

```text
YYYY-MM-DD_会议主题-2.md
```

## 文件内容格式

```markdown
---
date: "2026-06-03"
title: "产品例会"
source: "Tencent Meeting Yuanbao"
created_at: "2026-06-03 21:30:00"
tags:
  - meeting
  - yuanbao
---

# 产品例会

原始 Markdown 纪要内容
```

## 导入 Alfred

双击 `保存会议纪要.alfredworkflow` 导入。

导入后建议检查：

- Workflow 变量 `MEETING_NOTES_DIR`
- Hotkey 触发器的快捷键
- macOS 是否允许 Alfred 读取剪贴板、显示通知

## fzf 依赖

本工具的交互选择需要 `fzf`。如果尚未安装，可使用：

```bash
brew install fzf
```

搜索功能需要 `ripgrep`（未安装时会降级为系统 `grep`）：

```bash
brew install ripgrep
```

同名合并功能需要 Claude CLI：

```bash
claude --help
```
