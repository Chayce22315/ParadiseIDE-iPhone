FROM python:3.11-slim

# System deps + runtimes
RUN apt-get update && apt-get install -y --no-install-recommends \
    curl wget git make cmake zip unzip \
    build-essential gcc g++ gfortran \
    libssl-dev libffi-dev \
    libpq-dev libsqlite3-dev \
    libsfml-dev \
    libboost-all-dev \
    libsdl2-dev libsdl2-image-dev libsdl2-mixer-dev libsdl2-ttf-dev \
    libglfw3-dev libglew-dev \
    libeigen3-dev \
    libcurl4-openssl-dev \
    libjsoncpp-dev \
    nodejs npm \
    ruby ruby-dev \
    lua5.4 luarocks \
    golang-go \
    default-jdk \
    && rm -rf /var/lib/apt/lists/*

# Rust
RUN curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y
ENV PATH="/root/.cargo/bin:$PATH"

WORKDIR /app

COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

# Python libraries — data, web, graphics, ML, games, GUI, networking
RUN pip install --no-cache-dir \
    pygame \
    tkinter-page \
    PyQt5 \
    pyglet \
    arcade \
    wxPython \
    kivy \
    flask flask-cors flask-sqlalchemy flask-jwt-extended \
    fastapi uvicorn \
    django djangorestframework \
    aiohttp httpx requests \
    sqlalchemy alembic \
    psycopg2-binary pymongo redis \
    celery \
    numpy pandas scipy \
    matplotlib seaborn plotly \
    scikit-learn \
    tensorflow keras \
    torch torchvision \
    transformers \
    opencv-python-headless \
    Pillow \
    pytest black ruff mypy \
    click rich typer \
    pydantic \
    cryptography \
    paramiko \
    beautifulsoup4 scrapy selenium \
    sympy \
    pyserial \
    websockets \
    boto3 \
    stripe \
    twilio \
    sendgrid \
    python-dotenv \
    arrow pendulum \
    humanize \
    tqdm \
    loguru \
    || true

# Node.js / JS libraries
RUN npm install -g \
    typescript ts-node \
    express \
    fastify \
    react react-dom \
    next \
    vue \
    svelte \
    socket.io \
    axios \
    lodash \
    moment dayjs \
    dotenv \
    prisma \
    mongoose \
    jest \
    eslint prettier \
    webpack vite \
    tailwindcss \
    three \
    d3 \
    chart.js \
    || true

# Ruby gems
RUN gem install \
    rails \
    sinatra \
    rspec \
    bundler \
    rubocop \
    pry \
    httparty \
    nokogiri \
    || true

# Lua rocks
RUN luarocks install \
    luasocket \
    luafilesystem \
    || true

# Rust crates (common CLI tools)
RUN cargo install \
    ripgrep \
    fd-find \
    bat \
    exa \
    || true

COPY server.py .
COPY paradise/ ./paradise/

RUN mkdir -p /tmp/paradise_ide

EXPOSE 8765

HEALTHCHECK --interval=30s --timeout=5s \
  CMD curl -f http://localhost:8765/health || exit 1

CMD ["uvicorn", "server:app", "--host", "0.0.0.0", "--port", "8765"]
