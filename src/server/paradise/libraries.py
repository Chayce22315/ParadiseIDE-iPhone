""""
paradise/libraries.py
Catalog of pre-installed libraries per language.
Used by the ‘libs’ command to show what’s available.
"""
LIBRARY_CATALOG = {
“python”: {
“Games & Graphics”: [
“pygame        - 2D game development”,
“pyglet        - OpenGL games & multimedia”,
“arcade        - Easy 2D game framework”,
“kivy          - Cross-platform UI & touch”,
“PyQt5         - Full desktop GUI toolkit”,
],
“Web & APIs”: [
“flask         - Lightweight web framework”,
“fastapi       - Modern async web API”,
“django        - Full-stack web framework”,
“aiohttp       - Async HTTP client/server”,
“httpx         - Modern HTTP client”,
“requests      - Simple HTTP requests”,
“scrapy        - Web scraping framework”,
“beautifulsoup4 - HTML/XML parsing”,
],
“Data & ML”: [
“numpy         - Numerical computing”,
“pandas        - Data analysis”,
“scipy         - Scientific computing”,
“matplotlib    - Plotting & charts”,
“seaborn       - Statistical visualization”,
“plotly        - Interactive charts”,
“scikit-learn  - Machine learning”,
“tensorflow    - Deep learning (Google)”,
“torch         - Deep learning (PyTorch)”,
“transformers  - HuggingFace models”,
“opencv        - Computer vision”,
“Pillow        - Image processing”,
],
“Database”: [
“sqlalchemy    - SQL ORM”,
“psycopg2      - PostgreSQL driver”,
“pymongo       - MongoDB driver”,
“redis         - Redis client”,
“alembic       - DB migrations”,
],
“Utilities”: [
“click         - CLI framework”,
“rich          - Beautiful terminal output”,
“typer         - CLI with type hints”,
“pydantic      - Data validation”,
“cryptography  - Encryption”,
“boto3         - AWS SDK”,
“celery        - Task queues”,
“pytest        - Testing”,
“black         - Code formatter”,
“arrow         - Date/time handling”,
“loguru        - Logging”,
“tqdm          - Progress bars”,
],
},
“javascript”: {
“Frontend”: [
“react         - UI library”,
“vue           - Progressive framework”,
“svelte        - Compiler framework”,
“three         - 3D graphics (Three.js)”,
“d3            - Data visualization”,
“chart.js      - Charts”,
“tailwindcss   - Utility CSS”,
],
“Backend”: [
“express       - Web framework”,
“fastify       - Fast web framework”,
“next          - React full-stack”,
“socket.io     - Real-time WebSockets”,
“axios         - HTTP client”,
“mongoose      - MongoDB ODM”,
“prisma        - Type-safe ORM”,
],
“Tooling”: [
“typescript    - Typed JavaScript”,
“ts-node       - Run TS directly”,
“jest          - Testing”,
“eslint        - Linting”,
“prettier      - Formatting”,
“vite          - Build tool”,
“webpack       - Bundler”,
“lodash        - Utilities”,
“dayjs         - Date handling”,
“dotenv        - Env vars”,
],
},
“ruby”: {
“Web”: [
“rails         - Full-stack web framework”,
“sinatra       - Minimal web framework”,
“httparty      - HTTP client”,
“nokogiri      - HTML/XML parsing”,
],
“Dev Tools”: [
“rspec         - Testing”,
“bundler       - Dependency management”,
“rubocop       - Style enforcement”,
“pry           - Interactive console”,
],
},
“rust”: {
“CLI Tools (pre-installed)”: [
“ripgrep (rg)  - Fast text search”,
“fd            - Fast file finder”,
“bat           - Cat with syntax highlighting”,
“exa           - Modern ls replacement”,
],
“Install via cargo”: [
“cargo install serde      - Serialization”,
“cargo install tokio      - Async runtime”,
“cargo install reqwest    - HTTP client”,
“cargo install actix-web  - Web framework”,
“cargo install clap       - CLI argument parsing”,
“cargo install sqlx       - Async SQL”,
],
},
“go”: {
“Install via go get”: [
“gin           - Web framework”,
“fiber         - Express-like framework”,
“gorm          - ORM”,
“cobra         - CLI framework”,
“viper         - Config management”,
“zap           - Logging”,
],
},
“lua”: {
“Pre-installed”: [
“luasocket     - Network support”,
“luafilesystem - File system access”,
],
“Install via luarocks”: [
“luarocks install lua-cjson   - JSON”,
“luarocks install penlight    - Utilities”,
“luarocks install luaunit     - Testing”,
],
},
“cpp”: {
“Graphics & Games (pre-installed)”: [
“SFML          - 2D graphics, audio, networking, window”,
“SDL2          - Low-level media (graphics, audio, input)”,
“SDL2_image    - Image loading for SDL2”,
“SDL2_mixer    - Audio mixing for SDL2”,
“SDL2_ttf      - TrueType fonts for SDL2”,
“GLFW          - OpenGL window/input”,
“GLEW          - OpenGL extension loading”,
],
“Math & Science (pre-installed)”: [
“Eigen3        - Linear algebra, matrices, vectors”,
“Boost         - Comprehensive C++ utilities”,
],
“Networking & Data (pre-installed)”: [
“libcurl       - HTTP/FTP client”,
“jsoncpp       - JSON parsing”,
],
“Compile Examples”: [
“g++ main.cpp -o app -lsfml-graphics -lsfml-window -lsfml-system”,
“g++ main.cpp -o app -lSDL2 -lSDL2_image”,
“g++ main.cpp -o app -lGL -lGLEW -lglfw”,
“g++ main.cpp -o app $(pkg-config –cflags –libs eigen3)”,
],
},
“c”: {
“Pre-installed”: [
“SDL2          - Graphics, audio, input”,
“libcurl       - HTTP client”,
“OpenSSL       - Cryptography”,
],
“Compile Examples”: [
“gcc main.c -o app -lSDL2”,
“gcc main.c -o app -lcurl”,
],
},
“java”: {
“Note”: [
“Use maven or gradle to add dependencies.”,
“JDK is pre-installed (run: java -version)”,
],
“Popular”: [
“Spring Boot   - Web framework”,
“Hibernate     - ORM”,
“JUnit         - Testing”,
“Log4j         - Logging”,
],
},
}

def format_catalog(language: str = None) -> str:
out = []
if language and language in LIBRARY_CATALOG:
cats = {language: LIBRARY_CATALOG[language]}
else:
cats = LIBRARY_CATALOG


for lang, categories in cats.items():
    out.append(f"\n  {lang.upper()} LIBRARIES")
    out.append("  " + "-" * 40)
    for cat, libs in categories.items():
        out.append(f"\n  {cat}:")
        for lib in libs:
            out.append(f"    {lib}")

out.append("\n  Use 'install <package>' to add more.\n")
return "\n".join(out)
