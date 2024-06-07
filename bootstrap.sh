mkdir .packages
cd .packages
git clone --depth 1 https://github.com/raysan5/raylib.git
git clone --depth 1 https://github.com/zig-gamedev/zig-gamedev.git
cd raylib
zig build --release=fast
cd ../..
