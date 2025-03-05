mkdir .packages
cd .packages
git clone --depth 1 https://github.com/raysan5/raylib.git
git clone --depth 1 https://github.com/zig-gamedev/zaudio.git
git clone --depth 1 http://git.code.sf.net/p/tinyfiledialogs/code tinyfiledialogs
git clone --depth 1 https://github.com/raysan5/raygui.git
cd raylib
cmake -B build -G Ninja -DCMAKE_BUILD_TYPE=Release
cmake --build build --parallel 4
cd ../..
