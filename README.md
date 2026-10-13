# WorldBox Trackpad for Mac 🐾

**把手留在触控板上，继续照看你的小世界。**

你好呀，我是参与制作这个补丁的 AI 助手 Mary。它的起点很简单：用 MacBook 玩 WorldBox 时，能不能像逛 Miro 画布一样，双指滑动地图、捏合缩放？

我们试过把滑动变成方向键，结果地图有自己的想法——惯性和方向都不太听话。于是返工，改成直接按手指滑动的距离移动相机。经过真实触控板上的来回测试，现在终于顺手了。

如果你也用触控板玩，希望这个小补丁能让你少按几个键，多看一会儿小人的故事。💛

## 给人类的省流版

- **能做什么：**双指滑动 → 移动地图；张开／捏合 → 放大／缩小。
- **谁能用：**目前实测 **Apple Silicon Mac + Steam WorldBox 0.51.2**。其他版本先别装。
- **怎么装：**下面三种方式，选你最舒服的一种。
- **记住一件事：**以后用补丁自带的启动器打开游戏，直接从 Steam 启动不会加载它。

这是 **v0.2.0-preview**，尚未做 Apple 公证；异机下载后的首次启动未验证。无需 NeoModLoader。完整限制在后面，遇到问题可以[来告诉我们](https://github.com/BunnyTwo22/worldbox-trackpad-mac/issues)。

### A. 我是人类，我想点两下就走

**[下载补丁 ZIP](https://github.com/BunnyTwo22/worldbox-trackpad-mac/releases/download/v0.2.0-preview/WorldBox-Trackpad-v0.2.0-preview.zip)** → 解压 → 保存并退出游戏 → 双击文件夹里的 **Start WorldBox Trackpad.command**。

文件夹里的东西要待在一起，别只把启动器单独拎走。

### B. 我是人类，但复制一段命令也可以

打开 Mac 的「终端」，把下面整段复制进去，按回车。它会**下载并运行[安装脚本](install.sh)**，检查默认 Steam 库里的游戏版本、校验下载包，再放到你的用户「应用程序」文件夹。已有安装不会被覆盖，游戏也不会自动启动。

```sh
WB_TRACKPAD_INSTALLER="$(mktemp -t worldbox-trackpad)" && \
  curl -fL https://raw.githubusercontent.com/BunnyTwo22/worldbox-trackpad-mac/main/install.sh -o "$WB_TRACKPAD_INSTALLER" && \
  /bin/bash "$WB_TRACKPAD_INSTALLER"
```

装好后，在 Finder 按 **⌘⇧G**，粘贴这个路径：

```text
~/Applications/WorldBox Trackpad/v0.2.0-preview
```

先保存退出游戏，再双击里面的启动器。游戏装在外置硬盘或其他 Steam 库的话，请用手动安装方式，或让下面的 agent 帮忙找。

### C. 我有 agent，让它帮我装

把这段直接发给能操作你电脑的 agent 就好：

```text
请帮我安装 WorldBox 的 Mac 触控板补丁：
https://github.com/BunnyTwo22/worldbox-trackpad-mac

目标：双指平移地图、捏合缩放，并给我一个之后能直接打开的启动器。

请先阅读仓库 README 和 install.sh，检查我的系统、WorldBox 安装位置和游戏版本。
目前只验证了 Apple Silicon Mac 上通过 Rosetta 运行的 Steam WorldBox 0.51.2。
如果系统或游戏版本不在支持范围内，请说明情况，不要强行安装。

下载 v0.2.0-preview 发布包，核对仓库安装脚本中的固定 SHA-256，
解压到我的用户应用程序目录；已有目录不要覆盖。
游戏不在默认 Steam 库时，找到实际的 worldbox.app，
只调整补丁启动器里的 GAME_DIR。

保留我现有的存档、模组和游戏文件。不强退游戏，不关闭系统安全保护。
这个补丁不需要 NeoModLoader、实验模式或辅助功能权限。
若运行验证需要我先保存退出游戏，请提醒我。

完成后告诉我启动器在哪、如何使用、如何恢复原版输入。
若已启动验证，检查 Player.log 里的补丁加载记录；
请区分“文件已安装”“补丁已加载”和“真实触控板手势已验证”，不要混为一谈。
```

English: two-finger pan and pinch-to-zoom for a Mac trackpad. [English quick start](#english-quick-start).

---

## 想知道我们折腾了什么？往下看

## 操作

| 手势或按键 | 功能 |
| --- | --- |
| 双指滑动 | 按滑动距离平移地图，沿用系统滚动方向设置 |
| 双指张开／捏合 | 放大／缩小，使用游戏默认 Q/E 键位 |
| F8（部分键盘 Fn+F8） | 开关补丁 |
| 按住 Option | 临时使用游戏原始滚动行为 |

## 适配范围

- **已实测**：Steam WorldBox **0.51.2 / build 719**，Unity 2022.3.60f1；Apple Silicon Mac 通过 Rosetta 运行 x86_64 游戏。
- 使用者已确认双指平移和捏合缩放方向、手感正常。
- Intel Mac、其他 macOS 环境及其他游戏版本尚未验证。Windows 和移动版不适用。
- 平移接口目前限定游戏版本 `0.51.2`。
- 与 NeoModLoader、PowerBox、ActorHistory、Optime 同时启动成功，不代表所有功能组合都已测试。

## 安装

1. 将发布包解压到一个保留使用的文件夹。不要分开移动启动器与 `Trackpad.dylib`。
2. 保存并退出 WorldBox，确认 Steam 已登录，游戏本身能正常启动。
3. 在 Finder 中双击 **Start WorldBox Trackpad.command**。
4. 以后也从这个启动器进入游戏；直接点击 Steam 的“开始游戏”不会加载本补丁。

默认游戏位置：

```text
~/Library/Application Support/Steam/steamapps/common/worldbox/worldbox.app
```

如果游戏安装在另一块硬盘或 Steam 库，编辑启动器中的 `GAME_DIR`，指向实际的 `worldbox.app`。

本补丁不需要 NeoModLoader、游戏实验模式或辅助功能权限。

### 下载后的首次运行

预览二进制仅采用本地 ad-hoc 签名，**没有 Apple 开发者签名或公证**。下载后首次启动尚未在另一台 Mac 上验证；若系统阻止运行，请先核对发布来源，也可使用附带源码自行构建。无需关闭 SIP 等系统安全保护。

## 工作方式

macOS 手势事件进入游戏进程后，补丁将捏合转换为缩放键输入，将双指滑动转换为相机的实际位移。它读取当前缩放倍率换算距离，平移不再模拟方向键，也不叠加旧版的键盘移动惯性。

- 不覆盖游戏程序集，不安装全局键鼠监听。
- 平移事件合并至约每秒 60 次；空闲时无常驻轮询。
- 它是输入体验补丁，**不是游戏整体性能优化模组**，不承诺提高 FPS。
- 检查游戏菜单和控制锁定状态后再平移；遇到输入冲突可用 F8 或 Option。

## 已知限制

- 缩放仍依赖默认 Q/E 键位。
- 某些精确滚动鼠标（如部分 Magic Mouse）也会触发平移。
- 未覆盖全部窗口、游戏状态、第三方模组组合或长时间运行情况。
- 游戏更新后需要重新检查相机接口；不要假设未来版本直接兼容。

## 排查

游戏日志：

```text
~/Library/Logs/mkarpenko/WorldBox/Player.log
```

正常加载包含 `[WorldBox Trackpad v2] loaded`。首次在地图滑动后，成功绑定接口会记录 `direct camera bridge ready`。

启动器日志：

```text
~/Library/Logs/WorldBoxTrackpad/launch.log
```

如果不生效，先确认旧游戏进程已经退出、通过专用启动器打开、F8 没有关闭补丁，以及游戏版本为 0.51.2。

## 从源码构建

需要 Xcode Command Line Tools。在此文件夹的终端中运行：

```sh
zsh build.sh
```

输入转换测试：

```sh
xcrun clang -arch x86_64 -fobjc-arc -fblocks -framework Cocoa -framework Carbon test.m -o test-input
./test-input
```

自动测试覆盖坐标换算、不同缩放倍率、事件合并、旁路、无空闲定时器和缩放回归；不能代替真实设备测试。

## 卸载

保存并退出游戏，从 Steam 正常启动即可恢复原版输入。可以移除整个补丁文件夹，不需要删除游戏或存档。

## 文件与署名

包内包含源码、预览二进制、启动器、测试源码及安装说明；不包含游戏文件、第三方模组、存档、个人日志或本机绝对路径。

发布与维护：[BunnyTwo22](https://github.com/BunnyTwo22)。本项目使用 AI 编程助手协助实现，并由使用者在真实触控板上测试和反馈。

尚未选择开源许可证。源码公开用于透明审查；请勿假定它已按 MIT 或其他开源许可证授权。

## 设计参考

- [Miro 的触控板导航](https://help.miro.com/hc/en-us/articles/360017731053-Using-Miro-with-a-mouse-trackpad-or-touchscreen)
- [Apple 手势事件文档](https://developer.apple.com/library/archive/documentation/Cocoa/Conceptual/EventOverview/HandlingTouchEvents/HandlingTouchEvents.html)

## English quick start

1. Save and quit WorldBox. Keep the extracted folder intact.
2. Make sure Steam is signed in and the game works normally.
3. Double-click `Start WorldBox Trackpad.command` in Finder. Use this launcher each time; launching directly from Steam does not load the patch.
4. Two-finger scroll pans the map; pinch zooms using the default Q/E bindings. F8 toggles the patch (possibly Fn+F8); hold Option for original scrolling.

The launcher uses the default macOS Steam library path. If the game is elsewhere, edit `GAME_DIR` in the launcher. No NeoModLoader or experimental mode is required.

**Compatibility:** tested only with Steam WorldBox 0.51.2 / build 719 on an Apple Silicon Mac running the x86_64 game through Rosetta. Intel Macs and other game/OS versions are unverified. The pan bridge is version-gated to 0.51.2.

**Distribution:** this preview has an ad-hoc signature, not Apple Developer ID signing or notarization. First launch after downloading on another Mac has not been verified. You may inspect and build the included source with Xcode Command Line Tools (`zsh build.sh`). No need to disable SIP or system security.

This is an input patch, not an FPS booster. To disable it, quit and launch the game normally through Steam. Game files and saves are not bundled or overwritten. Report issues with the game/macOS version and relevant log lines, removing personal paths first.

AI-assisted development, with human testing on a real trackpad. No open-source license has been selected.
