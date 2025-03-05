New-Item -Path ".packages" -ItemType Directory -Force
Set-Location ".packages"
git clone --depth 1 https://github.com/raysan5/raylib.git
git clone --depth 1 https://github.com/zig-gamedev/zaudio.git
git clone --depth 1 http://git.code.sf.net/p/tinyfiledialogs/code tinyfiledialogs
git clone --depth 1 https://github.com/raysan5/raygui.git
Set-Location "raylib"
cmake -B build -G Ninja -DCMAKE_BUILD_TYPE=Release
cmake --build build --parallel 4
Set-Location "../.."
