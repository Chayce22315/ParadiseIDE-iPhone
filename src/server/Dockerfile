FROM python:3.11-slim

RUN apt-get update && apt-get install -y --no-install-recommends \
    curl wget git make cmake zip unzip \
    nodejs npm \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /app

COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

COPY server.py .
COPY paradise/ ./paradise/

RUN mkdir -p /tmp/paradise_ide

# API key is injected at runtime — never baked into the image
# Run with: docker run -e ANTHROPIC_API_KEY=sk-ant-... paradise-ide-server
ENV ANTHROPIC_API_KEY=""

EXPOSE 8765

HEALTHCHECK --interval=30s --timeout=5s \
  CMD curl -f http://localhost:8765/health || exit 1

CMD ["uvicorn", "server:app", "--host", "0.0.0.0", "--port", "8765"]
