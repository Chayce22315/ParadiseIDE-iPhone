"""
paradise/installer.py
Wraps pip, npm, brew, cargo, gem etc.
Streams install output live over WebSocket so the user sees real progress.
"""

import asyncio
import shutil
import sys
from pathlib import Path
from typing import Callable, Optional

SendFn = Callable[[str, str, Optional[dict]], None]


class PackageInstaller:
    def __init__(self, workspace: Path, send_fn: SendFn):
        self.workspace = workspace
        self.send = send_fn

    # ── Detect and dispatch ───────────────────────────────────────

    async def install(self, package: str, manager: Optional[str] = None):
        """
        Install a package, auto-detecting the manager if not specified.
        Examples:
            install("requests")           → pip
            install("express", "npm")     → npm
            install("ripgrep", "cargo")   → cargo
        """
        if manager is None:
            manager = self._detect_manager(package)

        await self.send("stdout", f"📦 Installing '{package}' via {manager}…\n", None)

        dispatch = {
            "pip":   self._pip,
            "npm":   self._npm,
            "brew":  self._brew,
            "cargo": self._cargo,
            "gem":   self._gem,
            "apt":   self._apt,
        }

        fn = dispatch.get(manager)
        if fn is None:
            await self.send("stderr", f"❌ Unknown package manager: {manager}\n", None)
            return

        await fn(package)

    # ── pip ───────────────────────────────────────────────────────

    async def _pip(self, package: str):
        # Install into a venv inside the workspace so packages persist per-session
        venv = self.workspace / ".venv"
        if not venv.exists():
            await self._stream([sys.executable, "-m", "venv", str(venv)])

        pip_bin = venv / "bin" / "pip"
        if not pip_bin.exists():
            pip_bin = venv / "Scripts" / "pip"  # Windows

        await self._stream([str(pip_bin), "install", "--upgrade", package])

    # ── npm ───────────────────────────────────────────────────────

    async def _npm(self, package: str):
        npm = shutil.which("npm")
        if not npm:
            await self.send("stderr", "❌ npm not found. Install Node.js first.\n", None)
            return
        node_modules = self.workspace / "node_modules"
        node_modules.mkdir(exist_ok=True)
        await self._stream(["npm", "install", package, "--prefix", str(self.workspace)])

    # ── brew ─────────────────────────────────────────────────────

    async def _brew(self, package: str):
        brew = shutil.which("brew")
        if not brew:
            await self.send("stderr", "❌ Homebrew not found.\n", None)
            return
        await self._stream(["brew", "install", package])

    # ── cargo ─────────────────────────────────────────────────────

    async def _cargo(self, package: str):
        cargo = shutil.which("cargo")
        if not cargo:
            await self.send("stderr", "❌ cargo not found. Install Rust first.\n", None)
            return
        await self._stream(["cargo", "install", package])

    # ── gem ───────────────────────────────────────────────────────

    async def _gem(self, package: str):
        gem = shutil.which("gem")
        if not gem:
            await self.send("stderr", "❌ gem not found. Install Ruby first.\n", None)
            return
        await self._stream(["gem", "install", package])

    # ── apt ───────────────────────────────────────────────────────

    async def _apt(self, package: str):
        apt = shutil.which("apt-get")
        if not apt:
            await self.send("stderr", "❌ apt-get not found.\n", None)
            return
        await self._stream(["sudo", "apt-get", "install", "-y", package])

    # ── Auto-detect manager ───────────────────────────────────────

    def _detect_manager(self, package: str) -> str:
        # npm packages often have @scope or contain slashes
        if package.startswith("@") or "/" in package:
            return "npm"
        # Rust crates often have hyphens
        if shutil.which("cargo") and not shutil.which("pip3"):
            return "cargo"
        return "pip"

    # ── Subprocess streaming ──────────────────────────────────────

    async def _stream(self, cmd: list[str]):
        proc = await asyncio.create_subprocess_exec(
            *cmd,
            stdout=asyncio.subprocess.PIPE,
            stderr=asyncio.subprocess.STDOUT,
            cwd=str(self.workspace),
        )

        async for line in proc.stdout:
            text = line.decode(errors="replace")
            await self.send("stdout", text, None)

        await proc.wait()
        if proc.returncode == 0:
            await self.send("stdout", f"✅ Done (exit 0)\n", None)
        else:
            await self.send("stderr", f"⚠️  Exited with code {proc.returncode}\n", None)
