mkdir .packages
cd .packages
git clone --depth 1 https://github.com/raysan5/raylib.git
git clone --depth 1 https://github.com/zig-gamedev/zaudio.git
cd raylib
cmake -B build -G Ninja -DCMAKE_BUILD_TYPE=Release
cmake --build build --parallel 4
cd ../..
