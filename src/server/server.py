"""
Paradise IDE — Backend Server  v2
===================================
FastAPI + WebSocket terminal server.
All heavy lifting is delegated to the paradise/ modules:
  - downloader.py    → download <url>, gh:<owner>/<repo>
  - installer.py     → pip/npm/brew/cargo install
  - process_manager.py → run commands, background jobs, kill
  - file_manager.py  → ls, cat, tree, mv, cp, rm, search, du
  - repl.py          → persistent Python REPL (>>> mode)

Run:
    pip install -r requirements.txt
    python server.py
    # or:
    uvicorn server:app --host 0.0.0.0 --port 8765 --reload
"""

import asyncio
import json
import shutil
import sys
import tempfile
import uuid
from datetime import datetime
from pathlib import Path

import uvicorn
from fastapi import FastAPI, WebSocket, WebSocketDisconnect, HTTPException
from fastapi.middleware.cors import CORSMiddleware
from fastapi.responses import FileResponse
from pydantic import BaseModel

from paradise import Downloader, PackageInstaller, ProcessManager, FileManager, PythonREPL, AIProxy
from paradise.ai import MODEL

# -----------------------------------------------------------------
app = FastAPI(title="Paradise IDE Server", version="2.0.0")

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

WORKSPACE_ROOT = Path(tempfile.gettempdir()) / "paradise_ide"
WORKSPACE_ROOT.mkdir(parents=True, exist_ok=True)

# session_id → { cwd, downloader, installer, proc_mgr, file_mgr, repl, repl_mode }
sessions: dict[str, dict] = {}


def workspace(session_id: str) -> Path:
    ws = WORKSPACE_ROOT / session_id
    ws.mkdir(parents=True, exist_ok=True)
    return ws


def cleanup(session_id: str):
    ws = WORKSPACE_ROOT / session_id
    if ws.exists():
        shutil.rmtree(ws, ignore_errors=True)
    sessions.pop(session_id, None)


# 

async def msg(ws: WebSocket, kind: str, data: str, extra: dict | None = None):
    payload = {"type": kind, "data": data, "ts": datetime.utcnow().isoformat()}
    if extra:
        payload.update(extra)
    await ws.send_text(json.dumps(payload))


def make_send(ws: WebSocket):
    async def send(kind: str, data: str, extra: dict | None = None):
        await msg(ws, kind, data, extra)
    return send


# 
# WebSocket terminal endpoint
# 

@app.websocket("/terminal/{session_id}")
async def terminal(ws: WebSocket, session_id: str):
    await ws.accept()
    ws_dir = workspace(session_id)
    send = make_send(ws)

    sessions[session_id] = {
        "cwd":       str(ws_dir),
        "repl_mode": False,
    }

    dl   = Downloader(ws_dir, send)
    inst = PackageInstaller(ws_dir, send)
    pm   = ProcessManager(ws_dir, send)
    fm   = FileManager(ws_dir, send)
    repl = PythonREPL(ws_dir, send)
    ai   = AIProxy()

    # Banner
    await send("banner", (
        f"\n  ☮️  Paradise IDE Terminal  v2\n"
        f"  🌴 Session : {session_id[:8]}…\n"
        f"  📁 Workspace: {ws_dir}\n"
        f"  🐍 Python  : {sys.version.split()[0]}\n"
        f"  💡 Type 'help' for all commands\n\n"
    ))
    await send("prompt", "paradise ➜ ")

    try:
        while True:
            raw = await ws.receive_text()

            try:
                packet  = json.loads(raw)
                command = packet.get("command", "").strip()
            except json.JSONDecodeError:
                command = raw.strip()

            if not command:
                await send("prompt", "paradise ➜ ")
                continue

            # 
            if sessions[session_id]["repl_mode"]:
                if command in ("exit", "quit", "exit()", "quit()"):
                    sessions[session_id]["repl_mode"] = False
                    await send("stdout", "⬅️  Exited REPL mode\n", None)
                elif command == "reset":
                    await repl.reset()
                elif command == "vars":
                    await repl.show_vars()
                else:
                    await repl.execute(command)
                await send("prompt", ">>> " if sessions[session_id]["repl_mode"] else "paradise ➜ ")
                continue

            # 
            parts = command.split()
            cmd0  = parts[0] if parts else ""

            # 
            if command == "help":
                await send("stdout", HELP_TEXT)

            # 
            elif command == "clear":
                await send("clear", "")

            # 
            elif command == "pwd":
                await send("stdout", sessions[session_id]["cwd"] + "\n")

            # 
            elif cmd0 == "cd":
                target = parts[1] if len(parts) > 1 else str(ws_dir)
                new_dir = (Path(sessions[session_id]["cwd"]) / target).resolve()
                if new_dir.exists() and new_dir.is_dir():
                    sessions[session_id]["cwd"] = str(new_dir)
                    await send("stdout", f"📁 {new_dir}\n")
                else:
                    await send("stderr", f"cd: {target}: No such directory\n")

            # 
            elif cmd0 in ("ls", "ll", "dir"):
                path = parts[1] if len(parts) > 1 else "."
                long = "-l" in command or "-la" in command or cmd0 in ("ll",)
                await fm.ls(path, long=long)

            # 
            elif cmd0 == "tree":
                path = parts[1] if len(parts) > 1 else "."
                await fm.tree(path)

            # 
            elif cmd0 == "cat":
                if len(parts) < 2:
                    await send("stderr", "Usage: cat <filename>\n")
                else:
                    await fm.cat(parts[1])

            # 
            elif cmd0 == "mkdir":
                if len(parts) < 2:
                    await send("stderr", "Usage: mkdir <dirname>\n")
                else:
                    await fm.mkdir(parts[1])

            # 
            elif cmd0 == "rm":
                recursive = "-r" in parts or "-rf" in parts
                targets = [p for p in parts[1:] if not p.startswith("-")]
                for t in targets:
                    await fm.rm(t, recursive=recursive)

            # 
            elif cmd0 == "mv" and len(parts) == 3:
                await fm.mv(parts[1], parts[2])

            # 
            elif cmd0 == "cp" and len(parts) >= 3:
                await fm.cp(parts[1], parts[2])

            # 
            elif cmd0 in ("find", "search"):
                pattern = parts[1] if len(parts) > 1 else ""
                await fm.search(pattern)

            # 
            elif command in ("du", "du -sh", "disk"):
                await fm.du()

            # 
            elif command == "files":
                await fm.file_list_json()

            # 
            elif cmd0 == "download":
                if len(parts) < 2:
                    await send("stderr", "Usage: download <url>\n")
                else:
                    await dl.download(parts[1])

            # 
            elif cmd0 == "install":
                if len(parts) < 2:
                    await send("stderr", "Usage: install <package> [pip|npm|brew|cargo]\n")
                else:
                    mgr = parts[2] if len(parts) > 2 else None
                    await inst.install(parts[1], mgr)

            # 
            elif cmd0 == "pip" or (cmd0 == "pip3"):
                if len(parts) >= 3 and parts[1] == "install":
                    await inst.install(parts[2], "pip")
                else:
                    await pm.run(command, sessions[session_id]["cwd"])

            # 
            elif cmd0 == "npm" and len(parts) >= 3 and parts[1] == "install":
                await inst.install(parts[2], "npm")

            # 
            elif command == "python" or command == "python3":
                sessions[session_id]["repl_mode"] = True
                await send("stdout", "🐍 Python REPL — type 'exit' to leave, 'vars' to list variables\n")
                await send("prompt", ">>> ")
                continue

            # 
            elif cmd0 == "run":
                if len(parts) < 2:
                    await send("stderr", "Usage: run <filename.py>\n")
                elif parts[1].endswith(".py"):
                    await repl.run_file(parts[1])
                else:
                    await pm.run(command, sessions[session_id]["cwd"])

            # 
            elif cmd0 == "bg":
                bg_cmd = " ".join(parts[1:])
                if bg_cmd:
                    await pm.run_background(bg_cmd, sessions[session_id]["cwd"])
                else:
                    await send("stderr", "Usage: bg <command>\n")

            elif command in ("jobs",):
                await pm.list_jobs()

            elif cmd0 == "kill":
                job_id = parts[1] if len(parts) > 1 else ""
                if job_id:
                    await pm.kill(job_id)
                else:
                    await send("stderr", "Usage: kill <job_id>\n")

            # AI commands
            elif cmd0 == "ai":
                # ai <question>  — ask anything with optional code context
                question = " ".join(parts[1:]) if len(parts) > 1 else ""
                if not question:
                    await send("stdout", "Usage: ai <question>\n       ai fix\n       ai explain\n       ai complete\n")
                elif not ai.is_configured():
                    await send("stderr", "AI not configured. Set ANTHROPIC_API_KEY on the server.\n")
                else:
                    await send("stdout", "AI: ")
                    async for chunk in ai.stream(question):
                        await send("stdout", chunk)
                    await send("stdout", "\n")

            elif command == "ai fix":
                if not ai.is_configured():
                    await send("stderr", "AI not configured.\n")
                else:
                    cwd = Path(sessions[session_id]["cwd"])
                    code_context = ""
                    # Try to read the most recently modified .py or .swift file
                    files = sorted(cwd.glob("*.py"), key=lambda f: f.stat().st_mtime, reverse=True)
                    if not files:
                        files = sorted(cwd.glob("*.swift"), key=lambda f: f.stat().st_mtime, reverse=True)
                    if files:
                        code_context = files[0].read_text(errors="replace")[:2000]
                    await send("stdout", "Analyzing...\n")
                    async for chunk in ai.stream("Find and fix any bugs in this code.", context=code_context):
                        await send("stdout", chunk)
                    await send("stdout", "\n")

            elif command == "ai explain":
                if not ai.is_configured():
                    await send("stderr", "AI not configured.\n")
                else:
                    cwd = Path(sessions[session_id]["cwd"])
                    files = sorted(cwd.glob("*.py"), key=lambda f: f.stat().st_mtime, reverse=True)
                    if not files:
                        files = sorted(cwd.glob("*.swift"), key=lambda f: f.stat().st_mtime, reverse=True)
                    if files:
                        code_context = files[0].read_text(errors="replace")[:2000]
                        await send("stdout", "Explaining...\n")
                        async for chunk in ai.stream("Explain what this code does.", context=code_context):
                            await send("stdout", chunk)
                        await send("stdout", "\n")
                    else:
                        await send("stderr", "No code files found in workspace.\n")

            elif command == "ai complete":
                if not ai.is_configured():
                    await send("stderr", "AI not configured.\n")
                else:
                    cwd = Path(sessions[session_id]["cwd"])
                    files = sorted(cwd.glob("*.py"), key=lambda f: f.stat().st_mtime, reverse=True)
                    if files:
                        code_context = files[0].read_text(errors="replace")[:2000]
                        await send("stdout", "Completing...\n")
                        async for chunk in ai.stream("Complete the code.", context=code_context):
                            await send("stdout", chunk)
                        await send("stdout", "\n")
                    else:
                        await send("stderr", "No Python files found in workspace.\n")

            elif command in ("exit", "quit"):
                await send("stdout", "Goodbye from Paradise!\n")
                break

            # 
            else:
                await pm.run(command, sessions[session_id]["cwd"])

            await send("prompt", "paradise ➜ ")

    except WebSocketDisconnect:
        pass
    finally:
        await pm.kill_all()
        cleanup(session_id)


# 
# REST endpoints
# 

@app.get("/")
async def root():
    return {
        "name": "Paradise IDE Server",
        "version": "2.0.0",
        "status": "🌴 Running",
        "sessions": len(sessions),
        "workspace": str(WORKSPACE_ROOT),
    }


@app.get("/health")
async def health():
    return {"ok": True, "ts": datetime.utcnow().isoformat()}


@app.get("/sessions")
async def list_sessions():
    return {"sessions": list(sessions.keys()), "count": len(sessions)}


class WriteFileRequest(BaseModel):
    session_id: str
    filename: str
    content: str


@app.post("/files/write")
async def write_file(req: WriteFileRequest):
    ws = workspace(req.session_id)
    dest = ws / req.filename
    dest.parent.mkdir(parents=True, exist_ok=True)
    dest.write_text(req.content, encoding="utf-8")
    return {"ok": True, "path": str(dest), "size": len(req.content)}


@app.get("/files/download/{session_id}/{filename:path}")
async def download_file(session_id: str, filename: str):
    ws = workspace(session_id)
    path = ws / filename
    if not path.exists():
        raise HTTPException(status_code=404, detail="File not found")
    return FileResponse(str(path), filename=path.name)


@app.delete("/sessions/{session_id}")
async def delete_session(session_id: str):
    cleanup(session_id)
    return {"ok": True}


# AI proxy endpoints

_ai = AIProxy()


@app.get("/ai/status")
async def ai_status():
    return {
        "configured": _ai.is_configured(),
        "model": MODEL if _ai.is_configured() else None,
    }


class AIRequest(BaseModel):
    prompt: str
    context: str = ""
    max_tokens: int = 512


@app.post("/ai/complete")
async def ai_complete(req: AIRequest):
    if not _ai.is_configured():
        raise HTTPException(status_code=503, detail="ANTHROPIC_API_KEY not set on server")
    result = await _ai.complete(req.prompt, context=req.context or None, max_tokens=req.max_tokens)
    return {"result": result}


@app.post("/ai/explain-error")
async def ai_explain_error(req: AIRequest):
    if not _ai.is_configured():
        raise HTTPException(status_code=503, detail="ANTHROPIC_API_KEY not set on server")
    result = await _ai.explain_error(req.prompt, code=req.context or None)
    return {"result": result}


@app.post("/ai/fix")
async def ai_fix(req: AIRequest):
    if not _ai.is_configured():
        raise HTTPException(status_code=503, detail="ANTHROPIC_API_KEY not set on server")
    result = await _ai.fix_code(req.context, problem=req.prompt)
    return {"result": result}


@app.post("/ai/explain-code")
async def ai_explain_code(req: AIRequest):
    if not _ai.is_configured():
        raise HTTPException(status_code=503, detail="ANTHROPIC_API_KEY not set on server")
    result = await _ai.explain_code(req.context)
    return {"result": result}


# 
HELP_TEXT = """
┌──────────────────────────────────────────────────┐
│  ☮️  Paradise IDE Terminal v2 — Command Reference │
├──────────────────────────────────────────────────┤
│  FILES                                           │
│  ls [path]          List directory               │
│  ll [path]          Long list                    │
│  tree [path]        Directory tree               │
│  cat <file>         Print file contents          │
│  mkdir <dir>        Create directory             │
│  rm [-r] <path>     Remove file/directory        │
│  mv <src> <dst>     Move/rename                  │
│  cp <src> <dst>     Copy                         │
│  find <pattern>     Search files                 │
│  du                 Workspace disk usage         │
│  files              Refresh UI file panel        │
│  pwd / cd <dir>     Navigation                   │
│                                                  │
│  DOWNLOADS                                       │
│  download <url>     Download any URL             │
│  download gh:<owner>/<repo>  GitHub latest       │
│  download gh:<o>/<r>@<tag>   GitHub tag          │
│                                                  │
│  PACKAGES                                        │
│  install <pkg>      Auto-detect pip/npm          │
│  install <pkg> pip  Force pip                    │
│  install <pkg> npm  Force npm                    │
│  install <pkg> brew Force brew                   │
│  pip install <pkg>  Direct pip                   │
│  npm install <pkg>  Direct npm                   │
│                                                  │
│  PYTHON                                          │
│  python / python3   Enter interactive REPL       │
│  run <script.py>    Run a Python file            │
│  vars               (in REPL) list variables     │
│  reset              (in REPL) clear namespace    │
│                                                  │
│  PROCESSES                                       │
│  bg <command>       Run command in background    │
│  jobs               List background jobs         │
│  kill <job_id>      Kill a background job        │
│                                                  │
│  OTHER                                           │
│  clear              Clear terminal               │
│  help               Show this help               │
│  exit               Close session                │
│                                                  │
│  Anything else runs as a shell command.          │
│  All files are temp — use REST to retrieve them. │
└──────────────────────────────────────────────────┘\n
"""

if __name__ == "__main__":
    print("🌴 Paradise IDE Server v2")
    print(f"   Workspace : {WORKSPACE_ROOT}")
    print(f"   Python    : {sys.version}")
    uvicorn.run("server:app", host="0.0.0.0", port=8765, reload=True, log_level="info")
