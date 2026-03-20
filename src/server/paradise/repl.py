"""
paradise/repl.py
Persistent Python REPL per session.
Runs code in an isolated namespace, streams output live,
remembers variables between executions.
"""

import asyncio
import io
import sys
import traceback
from contextlib import redirect_stdout, redirect_stderr
from pathlib import Path
from typing import Callable, Optional

SendFn = Callable[[str, str, Optional[dict]], None]


class PythonREPL:
    def __init__(self, workspace: Path, send_fn: SendFn):
        self.workspace = workspace
        self.send = send_fn
        # Persistent namespace across calls
        self._ns: dict = {
            "__name__": "__paradise_repl__",
            "__doc__": None,
        }
        # Add workspace path to sys.path inside namespace
        self._ns["__builtins__"] = __builtins__

    async def execute(self, source: str):
        """Execute Python source, stream stdout/stderr back."""
        stdout_buf = io.StringIO()
        stderr_buf = io.StringIO()

        try:
            # Try to compile as expression first (like IPython)
            try:
                code = compile(source, "<paradise>", "eval")
                with redirect_stdout(stdout_buf), redirect_stderr(stderr_buf):
                    result = eval(code, self._ns)
                if result is not None:
                    await self.send("stdout", repr(result) + "\n", None)
            except SyntaxError:
                # Fall back to exec for statements
                code = compile(source, "<paradise>", "exec")
                with redirect_stdout(stdout_buf), redirect_stderr(stderr_buf):
                    exec(code, self._ns)

            out = stdout_buf.getvalue()
            err = stderr_buf.getvalue()

            if out:
                await self.send("stdout", out, None)
            if err:
                await self.send("stderr", err, None)

        except Exception:
            tb = traceback.format_exc()
            await self.send("stderr", tb, None)

    async def run_file(self, filename: str):
        """Execute a .py file from the workspace."""
        path = self.workspace / filename
        if not path.exists():
            await self.send("stderr", f"repl: {filename}: No such file\n", None)
            return
        source = path.read_text(errors="replace")
        await self.send("stdout", f"▶  Running {filename}…\n", None)
        await self.execute(source)

    async def show_vars(self):
        """List user-defined variables in the namespace."""
        user_vars = {
            k: v for k, v in self._ns.items()
            if not k.startswith("_")
        }
        if not user_vars:
            await self.send("stdout", "  (namespace is empty)\n", None)
            return
        for k, v in user_vars.items():
            type_name = type(v).__name__
            preview = repr(v)
            if len(preview) > 60:
                preview = preview[:57] + "…"
            await self.send("stdout", f"  {k}: {type_name} = {preview}\n", None)

    async def reset(self):
        """Clear the namespace."""
        self._ns = {
            "__name__": "__paradise_repl__",
            "__doc__": None,
            "__builtins__": __builtins__,
        }
        await self.send("stdout", "🔄 REPL namespace reset.\n", None)
