"""
paradise/process_manager.py
Runs and tracks subprocesses per session.
Supports: background jobs, signal (kill), stdin injection, live streaming.
"""

import asyncio
import os
import signal
from dataclasses import dataclass, field
from pathlib import Path
from typing import Callable, Dict, Optional

SendFn = Callable[[str, str, Optional[dict]], None]


@dataclass
class ManagedProcess:
    job_id: str
    command: str
    process: asyncio.subprocess.Process
    task: asyncio.Task


class ProcessManager:
    def __init__(self, workspace: Path, send_fn: SendFn):
        self.workspace = workspace
        self.send = send_fn
        self._jobs: Dict[str, ManagedProcess] = {}
        self._job_counter = 0

    # ── Run foreground (blocks until done) ───────────────────────

    async def run(self, command: str, cwd: Optional[str] = None, stdin_data: Optional[str] = None):
        """Run a shell command and stream output. Awaits completion."""
        work_dir = cwd or str(self.workspace)

        proc = await asyncio.create_subprocess_shell(
            command,
            stdout=asyncio.subprocess.PIPE,
            stderr=asyncio.subprocess.PIPE,
            stdin=asyncio.subprocess.PIPE if stdin_data else None,
            cwd=work_dir,
            env={**os.environ, "TERM": "xterm-256color", "FORCE_COLOR": "1"},
        )

        async def pipe_stdout():
            async for line in proc.stdout:
                await self.send("stdout", line.decode(errors="replace"), None)

        async def pipe_stderr():
            async for line in proc.stderr:
                await self.send("stderr", line.decode(errors="replace"), None)

        if stdin_data:
            proc.stdin.write(stdin_data.encode())
            await proc.stdin.drain()
            proc.stdin.close()

        await asyncio.gather(pipe_stdout(), pipe_stderr())
        await proc.wait()

        code = proc.returncode
        await self.send("exit_code", str(code), {"code": code})
        return code

    # ── Run background (returns job_id immediately) ───────────────

    async def run_background(self, command: str, cwd: Optional[str] = None) -> str:
        self._job_counter += 1
        job_id = f"job_{self._job_counter}"
        work_dir = cwd or str(self.workspace)

        proc = await asyncio.create_subprocess_shell(
            command,
            stdout=asyncio.subprocess.PIPE,
            stderr=asyncio.subprocess.PIPE,
            cwd=work_dir,
            env={**os.environ, "TERM": "xterm-256color"},
        )

        async def _watch():
            async def pipe_stdout():
                async for line in proc.stdout:
                    await self.send("stdout", f"[{job_id}] {line.decode(errors='replace')}", None)

            async def pipe_stderr():
                async for line in proc.stderr:
                    await self.send("stderr", f"[{job_id}] {line.decode(errors='replace')}", None)

            await asyncio.gather(pipe_stdout(), pipe_stderr())
            await proc.wait()
            await self.send("stdout", f"[{job_id}] Process exited (code {proc.returncode})\n", None)
            self._jobs.pop(job_id, None)

        task = asyncio.create_task(_watch())
        self._jobs[job_id] = ManagedProcess(job_id, command, proc, task)

        await self.send("stdout", f"🚀 Started background job [{job_id}] PID={proc.pid}\n", None)
        return job_id

    # ── Kill a job ────────────────────────────────────────────────

    async def kill(self, job_id: str):
        job = self._jobs.get(job_id)
        if not job:
            await self.send("stderr", f"No job '{job_id}'\n", None)
            return
        try:
            job.process.send_signal(signal.SIGTERM)
            await asyncio.sleep(0.5)
            if job.process.returncode is None:
                job.process.kill()
            job.task.cancel()
            self._jobs.pop(job_id, None)
            await self.send("stdout", f"🛑 Killed [{job_id}]\n", None)
        except Exception as e:
            await self.send("stderr", f"Kill error: {e}\n", None)

    # ── List running jobs ─────────────────────────────────────────

    async def list_jobs(self):
        if not self._jobs:
            await self.send("stdout", "  (no background jobs)\n", None)
            return
        for jid, job in self._jobs.items():
            pid = job.process.pid
            await self.send("stdout", f"  [{jid}]  PID={pid}  {job.command}\n", None)

    # ── Kill all (called on session close) ────────────────────────

    async def kill_all(self):
        for job_id in list(self._jobs.keys()):
            await self.kill(job_id)
