"""
paradise/downloader.py
Handles all file downloads with live progress streamed back over WebSocket.
Supports: direct URLs, GitHub releases, pip packages, npm packages, raw files.
"""

import asyncio
import os
import re
import shutil
import tarfile
import zipfile
from pathlib import Path
from typing import Callable, Optional
from urllib.parse import urlparse

import httpx


# ── Progress callback type ───────────────────────────────────────
# send_fn(type, message, extra_dict)
SendFn = Callable[[str, str, Optional[dict]], None]


class Downloader:
    def __init__(self, workspace: Path, send_fn: SendFn):
        self.workspace = workspace
        self.send = send_fn

    # ── Main entry point ─────────────────────────────────────────

    async def download(self, url: str) -> Optional[Path]:
        """Download a URL to the workspace with live progress."""
        parsed = urlparse(url)

        # Resolve GitHub shorthand: gh:owner/repo@tag
        if url.startswith("gh:"):
            url = self._resolve_github(url)
            parsed = urlparse(url)

        filename = self._filename_from_url(url)
        dest = self.workspace / filename

        await self.send("stdout", f"⬇️  Downloading: {url}\n", None)
        await self.send("stdout", f"   → {dest}\n", None)

        try:
            async with httpx.AsyncClient(follow_redirects=True, timeout=120) as client:
                async with client.stream("GET", url) as response:
                    response.raise_for_status()

                    total = int(response.headers.get("content-length", 0))
                    downloaded = 0
                    last_pct = -1

                    with open(dest, "wb") as f:
                        async for chunk in response.aiter_bytes(chunk_size=65536):
                            f.write(chunk)
                            downloaded += len(chunk)

                            if total:
                                pct = int(downloaded / total * 100)
                                if pct != last_pct and pct % 10 == 0:
                                    bar = "█" * (pct // 5) + "░" * (20 - pct // 5)
                                    await self.send(
                                        "stdout",
                                        f"\r   [{bar}] {pct}%  {self._fmt(downloaded)}/{self._fmt(total)}",
                                        None,
                                    )
                                    last_pct = pct
                            else:
                                if downloaded % (1024 * 512) == 0:
                                    await self.send("stdout", f"\r   {self._fmt(downloaded)} received…", None)

            await self.send("stdout", f"\n✅ Saved: {filename} ({self._fmt(dest.stat().st_size)})\n", None)
            await self.send("download_complete", filename, {
                "filename": filename,
                "path": str(dest),
                "size": dest.stat().st_size,
            })

            # Auto-extract archives
            extracted = await self._maybe_extract(dest)
            if extracted:
                await self.send("stdout", f"📦 Extracted to: {extracted}\n", None)

            return dest

        except httpx.HTTPStatusError as e:
            await self.send("stderr", f"❌ HTTP {e.response.status_code}: {url}\n", None)
            return None
        except Exception as e:
            await self.send("stderr", f"❌ Download failed: {e}\n", None)
            return None

    # ── Archive extraction ────────────────────────────────────────

    async def _maybe_extract(self, path: Path) -> Optional[Path]:
        name = path.name.lower()

        if name.endswith(".zip"):
            out_dir = self.workspace / path.stem
            out_dir.mkdir(exist_ok=True)
            with zipfile.ZipFile(path, "r") as zf:
                zf.extractall(out_dir)
            return out_dir

        if name.endswith((".tar.gz", ".tgz", ".tar.bz2", ".tar.xz")):
            stem = path.name.split(".tar")[0]
            out_dir = self.workspace / stem
            out_dir.mkdir(exist_ok=True)
            with tarfile.open(path) as tf:
                tf.extractall(out_dir)
            return out_dir

        return None

    # ── GitHub shorthand resolver ─────────────────────────────────

    def _resolve_github(self, shorthand: str) -> str:
        """gh:owner/repo  →  latest release tarball
           gh:owner/repo@v1.2  →  specific tag"""
        rest = shorthand[3:]
        if "@" in rest:
            repo, tag = rest.split("@", 1)
        else:
            repo, tag = rest, "latest"

        owner, name = repo.split("/")
        if tag == "latest":
            return f"https://api.github.com/repos/{owner}/{name}/tarball"
        return f"https://github.com/{owner}/{name}/archive/refs/tags/{tag}.tar.gz"

    # ── Helpers ───────────────────────────────────────────────────

    def _filename_from_url(self, url: str) -> str:
        name = urlparse(url).path.split("/")[-1]
        return name if name else "download"

    def _fmt(self, n: int) -> str:
        if n < 1024:        return f"{n} B"
        if n < 1_048_576:   return f"{n/1024:.1f} KB"
        return f"{n/1_048_576:.1f} MB"
