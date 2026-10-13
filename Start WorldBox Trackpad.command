#!/bin/zsh
set -eu
MOD_DIR="${0:A:h}"
GAME_DIR="$HOME/Library/Application Support/Steam/steamapps/common/worldbox/worldbox.app"
if /usr/bin/pgrep -x WorldBox >/dev/null; then
    print 'WorldBox 已经运行。请先保存并退出游戏，再启动触控板版。'
    read '?按回车关闭…'
    exit 1
fi
if [[ ! -x "$GAME_DIR/Contents/MacOS/WorldBox" || ! -f "$MOD_DIR/Trackpad.dylib" ]]; then
    print '找不到游戏或 Trackpad.dylib，请保留启动器与补丁在同一个文件夹。'
    read '?按回车关闭…'
    exit 1
fi
mkdir -p "$HOME/Library/Logs/WorldBoxTrackpad"
print '启动 WorldBox 触控板版：捏合缩放，双指滑动移动，F8 开关，Option 临时恢复原操作。'
cd "$GAME_DIR/Contents/MacOS"
export SteamAppId=1206560
export SteamGameId=1206560
export DYLD_INSERT_LIBRARIES="$MOD_DIR/Trackpad.dylib"
exec ./WorldBox >>"$HOME/Library/Logs/WorldBoxTrackpad/launch.log" 2>&1
