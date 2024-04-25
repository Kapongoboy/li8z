New-Item -Path ".\packages" -ItemType Directory -Force
Set-Location ".\packages"
git clone --depth 1 https://github.com/raysan5/raylib.git
git clone --depth 1 https://github.com/zig-gamedev/zig-gamedev.git
Set-Location ".\raylib"
zig build --release=fast
Set-Location "../.."
