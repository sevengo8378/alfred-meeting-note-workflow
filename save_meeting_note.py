#!/usr/bin/env python3
"""Save a Markdown meeting note from the macOS clipboard."""

from __future__ import annotations

import argparse
import os
import re
import shlex
import shutil
import subprocess
import sys
import unicodedata
from datetime import datetime
from pathlib import Path


DEFAULT_NOTES_DIR = "~/Documents/meeting_notes"
SOURCE_NAME = "Tencent Meeting Yuanbao"


def run_command(args: list[str]) -> str:
    result = subprocess.run(args, check=False, capture_output=True, text=True)
    return result.stdout.strip()


def notify(title: str, message: str) -> None:
    if os.environ.get("MEETING_NOTE_NO_NOTIFY") == "1":
        return
    script = (
        'display notification '
        f'{applescript_quote(message)} with title {applescript_quote(title)}'
    )
    subprocess.run(["osascript", "-e", script], check=False)


def applescript_quote(value: str) -> str:
    return '"' + value.replace("\\", "\\\\").replace('"', '\\"') + '"'


def prompt_title() -> str:
    script = """
set dialogResult to display dialog "请输入会议主题。留空则尝试从 Markdown 标题自动识别。" default answer "" buttons {"取消", "保存"} default button "保存"
text returned of dialogResult
""".strip()
    result = subprocess.run(["osascript", "-e", script], check=False, capture_output=True, text=True)
    if result.returncode != 0:
        sys.exit(0)
    return result.stdout.strip()


def clipboard_markdown() -> str:
    injected_content = os.environ.get("MEETING_NOTE_CONTENT")
    if injected_content:
        return injected_content.replace("\r\n", "\n").replace("\r", "\n").strip()

    content = run_command(["pbpaste"])
    if not content.strip():
        raise ValueError("剪贴板为空，请先复制圆宝 Markdown 纪要。")
    return content.replace("\r\n", "\n").replace("\r", "\n").strip()


def infer_title(markdown: str) -> str:
    patterns = [
        r"^\s*#\s+(.+?)\s*$",
        r"^\s*(?:会议主题|会议标题|主题|标题)\s*[:：]\s*(.+?)\s*$",
    ]
    for pattern in patterns:
        match = re.search(pattern, markdown, flags=re.MULTILINE)
        if match:
            title = clean_title(match.group(1))
            if title:
                return title
    return "未命名会议"


def clean_title(title: str) -> str:
    title = re.sub(r"\s+", " ", title).strip()
    title = title.strip("#:：-—_ \t")
    return title[:80].strip()


def slug_for_filename(title: str) -> str:
    normalized = unicodedata.normalize("NFKC", title)
    normalized = re.sub(r"[/:*?\"<>|\\\x00-\x1f]", "-", normalized)
    normalized = re.sub(r"\s+", " ", normalized).strip()
    normalized = re.sub(r"-{2,}", "-", normalized).strip(".- ")
    return normalized or "未命名会议"


def front_matter(title: str, note_date: datetime, now: datetime) -> str:
    date = note_date.strftime("%Y-%m-%d")
    created_at = now.strftime("%Y-%m-%d %H:%M:%S")
    escaped_title = title.replace('"', '\\"')
    return "\n".join(
        [
            "---",
            f'date: "{date}"',
            f'title: "{escaped_title}"',
            f'source: "{SOURCE_NAME}"',
            f'created_at: "{created_at}"',
            "tags:",
            "  - meeting",
            "  - yuanbao",
            "---",
            "",
            "",
        ]
    )


def unique_path(directory: Path, filename: str) -> Path:
    candidate = directory / filename
    if not candidate.exists():
        return candidate

    stem = candidate.stem
    suffix = candidate.suffix
    index = 2
    while True:
        next_candidate = directory / f"{stem}-{index}{suffix}"
        if not next_candidate.exists():
            return next_candidate
        index += 1


def resolve_destination(directory: Path, filename: str) -> tuple[Path, str]:
    destination = directory / filename
    if not destination.exists():
        return destination, "new"

    action = existing_file_action(destination)
    if action == "overwrite":
        return destination, action
    if action == "duplicate":
        return unique_path(directory, filename), action
    if action == "merge":
        return destination, action
    raise ValueError("已取消保存。")


def existing_file_action(destination: Path) -> str:
    configured_action = os.environ.get("MEETING_NOTE_EXISTING", "").strip().lower()
    if configured_action in {"overwrite", "duplicate", "merge", "cancel"}:
        return configured_action

    if sys.stdin.isatty():
        return prompt_existing_file_in_terminal(destination)
    return prompt_existing_file_with_dialog(destination)


def prompt_existing_file_in_terminal(destination: Path) -> str:
    prompt = f"文件已存在：{destination}\n请选择：[y] 覆盖 / [n] 另存副本 / [m] 合并 / [c] 取消："
    while True:
        choice = input(prompt).strip().lower()
        if choice in {"y", "yes", "覆盖"}:
            return "overwrite"
        if choice in {"", "n", "no", "另存", "副本"}:
            return "duplicate"
        if choice in {"m", "merge", "合并"}:
            return "merge"
        if choice in {"c", "cancel", "取消"}:
            return "cancel"


def prompt_existing_file_with_dialog(destination: Path) -> str:
    script = f"""
set dialogResult to choose from list {{"覆盖", "另存副本", "合并", "取消"}} with prompt "文件已存在：{destination}\\n请选择处理方式：" default items {{"合并"}}
if dialogResult is false then
  return "取消"
else
  return item 1 of dialogResult
end if
""".strip()
    result = subprocess.run(["osascript", "-e", script], check=False, capture_output=True, text=True)
    if result.returncode != 0:
        return "cancel"
    choice = result.stdout.strip()
    if choice == "覆盖":
        return "overwrite"
    if choice == "另存副本":
        return "duplicate"
    if choice == "合并":
        return "merge"
    return "cancel"


def parse_note_date(raw_date: str | None) -> datetime:
    value = (raw_date or os.environ.get("MEETING_NOTE_DATE", "")).strip()
    if not value:
        return datetime.now()

    normalized = unicodedata.normalize("NFKC", value)
    normalized = normalized.replace("年", "-").replace("月", "-").replace("日", "")
    normalized = re.sub(r"[./_]", "-", normalized)
    normalized = re.sub(r"\s+", "", normalized)

    candidates = [normalized]
    compact_match = re.fullmatch(r"(\d{4})(\d{2})(\d{2})", normalized)
    if compact_match:
        candidates.insert(0, "-".join(compact_match.groups()))

    for candidate in candidates:
        try:
            return datetime.strptime(candidate, "%Y-%m-%d")
        except ValueError:
            continue

    loose_match = re.fullmatch(r"(\d{4})-(\d{1,2})-(\d{1,2})", normalized)
    if loose_match:
        year, month, day = [int(part) for part in loose_match.groups()]
        return datetime(year, month, day)

    raise ValueError(f"无法识别日期：{value}。支持示例：20260611、2026-06-11、2026/6/11、2026年6月11日。")


def parse_args(argv: list[str]) -> argparse.Namespace:
    if len(argv) == 1:
        try:
            argv = shlex.split(argv[0])
        except ValueError:
            pass

    parser = argparse.ArgumentParser(description="保存剪贴板中的 Markdown 会议纪要。")
    parser.add_argument("title", nargs="*", help="会议主题；留空时会弹窗输入或从 Markdown 自动识别。")
    parser.add_argument("-d", "--date", dest="note_date", help="会议日期，例如 20260611 或 2026-06-11。")
    return parser.parse_args(argv)


def save_note(raw_title: str, markdown: str, note_date: datetime | None = None) -> Path:
    now = datetime.now()
    effective_note_date = note_date or now
    title = clean_title(raw_title) or infer_title(markdown)
    notes_dir = Path(os.environ.get("MEETING_NOTES_DIR", DEFAULT_NOTES_DIR)).expanduser()
    notes_dir.mkdir(parents=True, exist_ok=True)

    filename = f"{effective_note_date:%Y-%m-%d}_{slug_for_filename(title)}.md"
    destination, action = resolve_destination(notes_dir, filename)
    body = markdown.strip()
    if not body_starts_with_title(body, title):
        body = f"# {title}\n\n{body}"
    if destination.exists() and action == "merge":
        body = merge_existing_and_incoming(destination.read_text(encoding="utf-8"), body, title)
    content = front_matter(title, effective_note_date, now) + body + "\n"
    destination.write_text(content, encoding="utf-8")
    return destination


def strip_front_matter(markdown: str) -> str:
    text = markdown.strip()
    if not text.startswith("---\n"):
        return text
    match = re.match(r"^---\n.*?\n---\n*(.*)$", text, flags=re.DOTALL)
    return match.group(1).strip() if match else text


def merge_existing_and_incoming(existing_markdown: str, incoming_markdown: str, title: str) -> str:
    existing_body = strip_front_matter(existing_markdown)
    prompt = build_merge_prompt(existing_body, incoming_markdown, title)
    print("正在调用 Claude 合并同名纪要...", file=sys.stderr)
    merged = run_claude_merge(prompt)
    if not merged.strip():
        raise ValueError("Claude 合并结果为空，已取消写入。")
    return merged.strip()


def build_merge_prompt(existing_body: str, incoming_body: str, title: str) -> str:
    return f"""
请合并两份由腾讯会议圆宝生成的 Markdown 会议纪要。会议可能因为限时中断被拆成两段。

要求：
- 只输出合并后的 Markdown 正文，不要输出 YAML front matter。
- 保留标题：# {title}
- 合并重复的小结、待办、决议和讨论点。
- 保持事实完整，不要编造信息。
- 如果两份纪要存在时间顺序，按会议进程组织。
- 待办事项要去重，并尽量保留负责人、动作和截止时间。

## 已有纪要

{existing_body}

## 新增纪要

{incoming_body}
""".strip()


def run_claude_merge(prompt: str) -> str:
    configured_command = os.environ.get("MEETING_NOTE_MERGE_COMMAND", "").strip()
    if configured_command:
        command = shlex.split(configured_command)
    else:
        claude_path = shutil.which("claude")
        if not claude_path:
            raise ValueError("未找到 claude 命令，无法合并同名纪要。")
        command = [claude_path, "-p", "--permission-mode", "dontAsk"]

    result = subprocess.run(command, input=prompt, check=False, capture_output=True, text=True)
    if result.returncode != 0:
        stderr = result.stderr.strip() or "Claude 合并进程失败。"
        raise ValueError(stderr)
    return result.stdout


def body_starts_with_title(markdown: str, title: str) -> bool:
    first_line = markdown.splitlines()[0].strip() if markdown.strip() else ""
    match = re.match(r"^#\s+(.+?)\s*$", first_line)
    return bool(match and clean_title(match.group(1)) == title)


def main() -> int:
    args = parse_args(sys.argv[1:])
    raw_title = " ".join(args.title).strip()
    if not raw_title:
        raw_title = prompt_title()

    try:
        markdown = clipboard_markdown()
        note_date = parse_note_date(args.note_date)
        destination = save_note(raw_title, markdown, note_date)
    except Exception as exc:
        notify("会议纪要保存失败", str(exc))
        print(str(exc), file=sys.stderr)
        return 1

    message = f"已保存到 {destination}"
    notify("会议纪要已保存", message)
    print(message)
    print("\n--- 纪要内容 ---\n")
    print(destination.read_text(encoding="utf-8"))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
