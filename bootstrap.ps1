New-Item -Path ".\packages" -ItemType Directory -Force
Set-Location ".\packages"
git clone --depth 1 https://github.com/raysan5/raylib.git
Set-Location ".\raylib"
zig build --release=fast
Set-Location ".."
