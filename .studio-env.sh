# Source this to put the studio toolchain on PATH for the current shell:
#   source .studio-env.sh
# Needed until the app is restarted (it inherited PATH before ffmpeg/uv/bun installed).
_LA="${LOCALAPPDATA:-$HOME/AppData/Local}"
export PATH="$_LA/Microsoft/WinGet/Packages/Gyan.FFmpeg_Microsoft.Winget.Source_8wekyb3d8bbwe/ffmpeg-9.0.1-full_build/bin:$_LA/Microsoft/WinGet/Packages/astral-sh.uv_Microsoft.Winget.Source_8wekyb3d8bbwe:$HOME/.bun/bin:$PATH"
