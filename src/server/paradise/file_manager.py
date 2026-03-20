"""
paradise/file_manager.py
Full file system operations for the session workspace.
All paths are sandboxed inside the workspace root.
"""

import json
import os
import shutil
from pathlib import Path
from typing import Callable, Optional

SendFn = Callable[[str, str, Optional[dict]], None]

# File types we can safely display as text
TEXT_EXTENSIONS = {
    ".py", ".js", ".ts", ".swift", ".sh", ".bash",
    ".md", ".txt", ".json", ".yaml", ".yml", ".toml",
    ".html", ".css", ".xml", ".csv", ".env", ".cfg",
    ".ini", ".conf", ".log", ".rs", ".go", ".rb",
    ".java", ".kt", ".c", ".cpp", ".h", ".hpp",
}


class FileManager:
    def __init__(self, workspace: Path, send_fn: SendFn):
        self.workspace = workspace
        self.send = send_fn

    # ── Sandbox helper ────────────────────────────────────────────

    def _resolve(self, path: str) -> Path:
        """Resolve path relative to workspace, never escaping it."""
        resolved = (self.workspace / path).resolve()
        if not str(resolved).startswith(str(self.workspace)):
            raise ValueError(f"Path '{path}' escapes workspace")
        return resolved

    # ── ls ────────────────────────────────────────────────────────

    async def ls(self, path: str = ".", long: bool = False):
        try:
            target = self._resolve(path)
            if not target.exists():
                await self.send("stderr", f"ls: {path}: No such file or directory\n", None)
                return

            entries = sorted(target.iterdir(), key=lambda p: (p.is_file(), p.name.lower()))
            lines = []
            file_list = []

            for e in entries:
                stat = e.stat()
                size = stat.st_size
                icon = "📁" if e.is_dir() else self._icon(e.suffix)
                if long:
                    lines.append(f"  {icon}  {size:>10,}  {e.name}")
                else:
                    lines.append(f"  {icon}  {e.name}")
                file_list.append({"name": e.name, "size": size, "is_dir": e.is_dir()})

            out = "\n".join(lines) + "\n" if lines else "  (empty)\n"
            await self.send("stdout", out, None)
            await self.send("file_list", json.dumps(file_list), {"files": file_list})

        except Exception as e:
            await self.send("stderr", f"ls error: {e}\n", None)

    # ── tree ──────────────────────────────────────────────────────

    async def tree(self, path: str = ".", max_depth: int = 3):
        try:
            target = self._resolve(path)
            lines = [f"📁 {target.name}"]
            self._tree_recurse(target, lines, "", max_depth, 0)
            await self.send("stdout", "\n".join(lines) + "\n", None)
        except Exception as e:
            await self.send("stderr", f"tree error: {e}\n", None)

    def _tree_recurse(self, path: Path, lines: list, prefix: str, max_depth: int, depth: int):
        if depth >= max_depth:
            return
        entries = sorted(path.iterdir(), key=lambda p: (p.is_file(), p.name))
        for i, e in enumerate(entries):
            connector = "└── " if i == len(entries) - 1 else "├── "
            icon = "📁" if e.is_dir() else self._icon(e.suffix)
            lines.append(f"{prefix}{connector}{icon} {e.name}")
            if e.is_dir():
                extension = "    " if i == len(entries) - 1 else "│   "
                self._tree_recurse(e, lines, prefix + extension, max_depth, depth + 1)

    # ── cat ───────────────────────────────────────────────────────

    async def cat(self, filename: str, show_lines: bool = True):
        try:
            path = self._resolve(filename)
            if not path.exists():
                await self.send("stderr", f"cat: {filename}: No such file\n", None)
                return
            if path.is_dir():
                await self.send("stderr", f"cat: {filename}: Is a directory\n", None)
                return

            # Binary file guard
            if path.suffix.lower() not in TEXT_EXTENSIONS:
                size = path.stat().st_size
                await self.send("stdout", f"[Binary file — {size:,} bytes — use 'download' to retrieve]\n", None)
                return

            content = path.read_text(errors="replace")
            lines = content.splitlines()
            out = ""
            for i, line in enumerate(lines, 1):
                out += (f"{i:4}  {line}\n" if show_lines else f"{line}\n")
            await self.send("stdout", out, None)

        except Exception as e:
            await self.send("stderr", f"cat error: {e}\n", None)

    # ── write ─────────────────────────────────────────────────────

    async def write(self, filename: str, content: str):
        try:
            path = self._resolve(filename)
            path.parent.mkdir(parents=True, exist_ok=True)
            path.write_text(content, encoding="utf-8")
            await self.send("stdout", f"✅ Written: {filename} ({len(content):,} chars)\n", None)
        except Exception as e:
            await self.send("stderr", f"write error: {e}\n", None)

    # ── mkdir ─────────────────────────────────────────────────────

    async def mkdir(self, dirname: str):
        try:
            path = self._resolve(dirname)
            path.mkdir(parents=True, exist_ok=True)
            await self.send("stdout", f"📁 Created: {dirname}\n", None)
        except Exception as e:
            await self.send("stderr", f"mkdir error: {e}\n", None)

    # ── rm ────────────────────────────────────────────────────────

    async def rm(self, target: str, recursive: bool = False):
        try:
            path = self._resolve(target)
            if not path.exists():
                await self.send("stderr", f"rm: {target}: No such file\n", None)
                return
            if path.is_dir():
                if recursive:
                    shutil.rmtree(path)
                    await self.send("stdout", f"🗑️  Removed directory: {target}\n", None)
                else:
                    await self.send("stderr", f"rm: {target}: Is a directory (use 'rm -r')\n", None)
            else:
                path.unlink()
                await self.send("stdout", f"🗑️  Removed: {target}\n", None)
        except Exception as e:
            await self.send("stderr", f"rm error: {e}\n", None)

    # ── mv ────────────────────────────────────────────────────────

    async def mv(self, src: str, dst: str):
        try:
            s = self._resolve(src)
            d = self._resolve(dst)
            shutil.move(str(s), str(d))
            await self.send("stdout", f"✅ Moved: {src} → {dst}\n", None)
        except Exception as e:
            await self.send("stderr", f"mv error: {e}\n", None)

    # ── cp ────────────────────────────────────────────────────────

    async def cp(self, src: str, dst: str):
        try:
            s = self._resolve(src)
            d = self._resolve(dst)
            if s.is_dir():
                shutil.copytree(str(s), str(d))
            else:
                shutil.copy2(str(s), str(d))
            await self.send("stdout", f"✅ Copied: {src} → {dst}\n", None)
        except Exception as e:
            await self.send("stderr", f"cp error: {e}\n", None)

    # ── find / search ─────────────────────────────────────────────

    async def search(self, pattern: str, path: str = "."):
        try:
            target = self._resolve(path)
            results = list(target.rglob(f"*{pattern}*"))
            if not results:
                await self.send("stdout", f"  (no matches for '{pattern}')\n", None)
                return
            for r in results[:50]:
                rel = r.relative_to(self.workspace)
                icon = "📁" if r.is_dir() else self._icon(r.suffix)
                await self.send("stdout", f"  {icon}  {rel}\n", None)
            if len(results) > 50:
                await self.send("stdout", f"  … and {len(results)-50} more\n", None)
        except Exception as e:
            await self.send("stderr", f"search error: {e}\n", None)

    # ── disk usage ────────────────────────────────────────────────

    async def du(self):
        total = sum(f.stat().st_size for f in self.workspace.rglob("*") if f.is_file())
        await self.send("stdout", f"📊 Workspace size: {self._fmt(total)}\n", None)

    # ── file list (for UI panel) ──────────────────────────────────

    async def file_list_json(self):
        files = []
        for f in sorted(self.workspace.rglob("*")):
            if f.is_file():
                files.append({
                    "name": f.name,
                    "path": str(f.relative_to(self.workspace)),
                    "size": f.stat().st_size,
                })
        await self.send("file_list", json.dumps(files), {"files": files})

    # ── Helpers ───────────────────────────────────────────────────

    def _icon(self, ext: str) -> str:
        ext = ext.lower()
        icons = {
            ".py": "🐍", ".js": "🟨", ".ts": "🟦", ".swift": "🔷",
            ".json": "📋", ".yaml": "⚙️", ".yml": "⚙️",
            ".md": "📝", ".txt": "📄", ".sh": "⚙️",
            ".zip": "📦", ".tar": "📦", ".gz": "📦",
            ".ipa": "📱", ".apk": "🤖", ".exe": "🪟",
            ".html": "🌐", ".css": "🎨", ".rs": "🦀",
            ".go": "🐹", ".rb": "💎", ".java": "☕",
        }
        return icons.get(ext, "📄")

    def _fmt(self, n: int) -> str:
        if n < 1024:        return f"{n} B"
        if n < 1_048_576:   return f"{n/1024:.1f} KB"
        if n < 1_073_741_824: return f"{n/1_048_576:.1f} MB"
        return f"{n/1_073_741_824:.1f} GB"
