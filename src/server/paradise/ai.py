"""
paradise/ai.py
Proxies requests to Groq's API (free, fast, Llama 3).
The API key lives here on the server only — never sent to the app.

Set your key in src/server/.env:
    GROQ_API_KEY=gsk_...
"""

import json
import os
from pathlib import Path
from typing import AsyncIterator, Optional

import httpx
from dotenv import load_dotenv

load_dotenv(Path(__file__).parent.parent / ".env")

GROQ_URL = "https://api.groq.com/openai/v1/chat/completions"
MODEL = "llama3-70b-8192"

SYSTEM_PROMPT = """You are Paradise IDE's AI Co-Pilot — a calm, supportive coding assistant.
Help users write, debug, and understand code.
- Be concise and friendly
- For fixes, show corrected code only
- For errors, be plain and reassuring
- Keep responses short — this is an inline IDE assistant
"""


class AIProxy:
    def __init__(self):
        self.api_key = os.getenv("GROQ_API_KEY", "")

    def is_configured(self) -> bool:
        return bool(self.api_key and self.api_key.startswith("gsk_"))

    def _headers(self) -> dict:
        return {
            "Authorization": f"Bearer {self.api_key}",
            "Content-Type": "application/json",
        }

    def _build_messages(self, prompt: str, context: Optional[str]) -> list:
        messages = [{"role": "system", "content": SYSTEM_PROMPT}]
        if context:
            messages.append({
                "role": "user",
                "content": f"Here is my current code:\n\n```\n{context}\n```"
            })
            messages.append({
                "role": "assistant",
                "content": "I can see your code. What would you like help with?"
            })
        messages.append({"role": "user", "content": prompt})
        return messages

    # ── Single response ───────────────────────────────────────────

    async def complete(self, prompt: str, context: Optional[str] = None, max_tokens: int = 512) -> str:
        if not self.is_configured():
            return "AI not configured. Add GROQ_API_KEY to src/server/.env"

        try:
            async with httpx.AsyncClient(timeout=30) as client:
                resp = await client.post(
                    GROQ_URL,
                    headers=self._headers(),
                    json={
                        "model": MODEL,
                        "max_tokens": max_tokens,
                        "messages": self._build_messages(prompt, context),
                    },
                )
                resp.raise_for_status()
                return resp.json()["choices"][0]["message"]["content"]

        except httpx.HTTPStatusError as e:
            return f"API error {e.response.status_code}: {e.response.text[:200]}"
        except Exception as e:
            return f"AI error: {e}"

    # ── Streaming response ────────────────────────────────────────

    async def stream(self, prompt: str, context: Optional[str] = None, max_tokens: int = 1024) -> AsyncIterator[str]:
        if not self.is_configured():
            yield "AI not configured. Add GROQ_API_KEY to src/server/.env"
            return

        try:
            async with httpx.AsyncClient(timeout=60) as client:
                async with client.stream(
                    "POST",
                    GROQ_URL,
                    headers=self._headers(),
                    json={
                        "model": MODEL,
                        "max_tokens": max_tokens,
                        "messages": self._build_messages(prompt, context),
                        "stream": True,
                    },
                ) as resp:
                    resp.raise_for_status()
                    async for line in resp.aiter_lines():
                        if not line.startswith("data: "):
                            continue
                        payload = line[6:]
                        if payload == "[DONE]":
                            break
                        try:
                            event = json.loads(payload)
                            delta = event["choices"][0].get("delta", {})
                            if "content" in delta and delta["content"]:
                                yield delta["content"]
                        except (json.JSONDecodeError, KeyError):
                            continue

        except httpx.HTTPStatusError as e:
            yield f"\nAPI error {e.response.status_code}: {e.response.text[:200]}"
        except Exception as e:
            yield f"\nAI error: {e}"

    # ── Convenience helpers ───────────────────────────────────────

    async def explain_error(self, error: str, code: Optional[str] = None) -> str:
        return await self.complete(
            f"Explain this error simply and suggest a fix:\n\n{error}",
            context=code, max_tokens=300
        )

    async def complete_code(self, code: str, cursor_hint: str = "") -> str:
        return await self.complete(
            f"Complete the code at the cursor. Return only the completion.\nCursor after: {cursor_hint}",
            context=code, max_tokens=200
        )

    async def explain_code(self, code: str) -> str:
        return await self.complete(
            "Explain what this code does in 2-3 sentences.",
            context=code, max_tokens=200
        )

    async def fix_code(self, code: str, problem: str = "") -> str:
        return await self.complete(
            f"Fix the bug{' — ' + problem if problem else ''}. Return only the corrected code.",
            context=code, max_tokens=400
        )
