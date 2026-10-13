#!/bin/bash
# Download and verify the released patch. Does not start the game or change security settings.
set -euo pipefail

VERSION='v0.2.0-preview'
ASSET="WorldBox-Trackpad-${VERSION}.zip"
BASE="https://github.com/BunnyTwo22/worldbox-trackpad-mac/releases/download/${VERSION}"
EXPECTED_SHA256='3814afc69ec65d16b995987573aabf749fd55921ceb8d265ead25c24b3b28fce'
GAME_DIR="$HOME/Library/Application Support/Steam/steamapps/common/worldbox/worldbox.app"
DEST="${WORLDBOX_TRACKPAD_INSTALL_DIR:-$HOME/Applications/WorldBox Trackpad/$VERSION}"

die() { printf '%s\n' "$*" >&2; exit 1; }
[[ "$(uname -s)" == Darwin ]] || die '这个补丁目前只支持 macOS。'
[[ -d "$GAME_DIR" ]] || die "没有找到默认位置的 WorldBox：$GAME_DIR。若在其他 Steam 库，请按 README 手动安装，或把 README 中的安装 prompt 交给 agent。"
GAME_VERSION=$(/usr/libexec/PlistBuddy -c 'Print :CFBundleShortVersionString' "$GAME_DIR/Contents/Info.plist")
[[ "$GAME_VERSION" == '0.51.2' ]] || die "检测到 WorldBox $GAME_VERSION；本预览版只适配 0.51.2，已停止安装。"
[[ ! -e "$DEST" && ! -L "$DEST" ]] || die "安装目录已经存在，我没有覆盖它：$DEST。可以直接使用其中的启动器。"

WORK_DIR=$(mktemp -d "${TMPDIR:-/tmp}/worldbox-trackpad.XXXXXX")
trap 'rm -rf -- "$WORK_DIR"' EXIT
printf '正在下载 WorldBox 触控板补丁 %s…\n' "$VERSION"
curl --fail --location --proto '=https' --proto-redir '=https' --retry 2 \
  --connect-timeout 20 --max-time 180 --output "$WORK_DIR/$ASSET" "$BASE/$ASSET"
ACTUAL_SHA256=$(shasum -a 256 "$WORK_DIR/$ASSET" | awk '{print $1}')
[[ "$ACTUAL_SHA256" == "$EXPECTED_SHA256" ]] || die '下载文件与固定版本的 SHA-256 不符，已停止安装。'
/usr/bin/ditto -x -k "$WORK_DIR/$ASSET" "$WORK_DIR/unpacked"
SOURCE="$WORK_DIR/unpacked/WorldBox-Trackpad-$VERSION"
[[ -f "$SOURCE/Trackpad.dylib" && -f "$SOURCE/Start WorldBox Trackpad.command" ]] || die '压缩包内容不完整，已停止安装。'
mkdir -p "$(dirname "$DEST")"
# mkdir refuses a destination created by another process since our initial check.
mkdir "$DEST"
/usr/bin/ditto "$SOURCE" "$DEST"
chmod u+x "$DEST/Start WorldBox Trackpad.command"
printf '\n装好啦。先保存并退出游戏，再双击下面的启动器：\n%s\n' "$DEST/Start WorldBox Trackpad.command"
printf '\n双指滑动移动地图，捏合缩放；F8 开关，Option 临时恢复普通滚动。\n以后也请从这个启动器进入游戏。安装过程没有启动游戏，也没有改动游戏文件或存档。\n'
