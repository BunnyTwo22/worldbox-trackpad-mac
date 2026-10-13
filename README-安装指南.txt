WorldBox Trackpad for Mac — v0.2.0 preview

让 WorldBox 在 MacBook 触控板上支持双指平移与捏合缩放。
社区实验性补丁，与 WorldBox 官方无隶属关系。

支持与验证范围
- 实测：Steam WorldBox 0.51.2 / build 719，Unity 2022.3.60f1，Apple Silicon Mac 通过 Rosetta 运行 x86_64 游戏。
- 使用者已确认：双指平移和捏合缩放方向、手感正常。
- Intel Mac 未实测；Windows、移动版、其他游戏版本不在验证范围内。
- 当前平移接口限定游戏版本 0.51.2。不要将“Mac 可运行”等同于所有 Mac / macOS 版本都已验证。

安装与启动
1. 保留整个解压后的文件夹。启动器和 Trackpad.dylib 必须在同一目录。
2. 先保存并退出已打开的 WorldBox，确保 Steam 已登录并可正常启动游戏。
3. 在 Finder 中双击 Start WorldBox Trackpad.command。
4. 默认查找 ~/Library/Application Support/Steam/steamapps/common/worldbox/worldbox.app。
   如使用其他 Steam 库，需编辑启动器中的 GAME_DIR 指向实际的 worldbox.app。
5. 以后也要用这个启动器启动。直接从 Steam 点“开始游戏”不会加载本补丁。

操作
- 双指张开／捏合：放大／缩小。当前转换为 Q/E，需保留游戏默认缩放键位。
- 双指滑动：按滑动距离平移地图，沿用 macOS 的滚动方向设置。
- F8：切换补丁开关。部分键盘需要 Fn+F8。
- 按住 Option：临时恢复游戏原始滚动，可用于菜单操作。
- 游戏内菜单和控制锁定状态会检查是否允许平移；遇到输入冲突可用 F8 关闭。

技术说明
- 进程内加载本地 dylib，不覆盖游戏程序集，不需要 NeoModLoader 或实验模式。
- 使用 macOS 手势事件；平移通过游戏内已有 Mono 相机接口完成。
- 不安装全局键鼠监听，不需要辅助功能权限。
- 平移事件合并约 60 次/秒；空闲时无常驻轮询。不是游戏整体性能优化模组。
- 普通鼠标滚轮保持原行为；部分支持精确滚动的 Magic Mouse 也会被识别为平移。
- 已与 NeoModLoader、PowerBox、ActorHistory、Optime 同时启动，但未覆盖所有组合功能。

安全与分发状态
- 此预览包采用本地 ad-hoc 签名，未进行 Apple 开发者签名或公证。
- 下载后的首次打开体验尚未在另一台 Mac 验证；如系统阻止运行，请先核对来源，或从附带源码自行构建。
- 不需要关闭 SIP 或其他系统安全保护。
- 本包不含 WorldBox 游戏文件、存档、聊天记录或第三方模组。
- GitHub 发布账号：BunnyTwo22。AI 辅助开发，真实触控板人工测试。
- 尚未选择开源许可证，不默认授予 MIT 等开源授权。
- 下载及源码：https://github.com/BunnyTwo22/worldbox-trackpad-mac

从源码构建
需要 Xcode Command Line Tools。在本文件夹打开终端，执行：
  zsh build.sh
测试：
  xcrun clang -arch x86_64 -fobjc-arc -fblocks -framework Cocoa -framework Carbon test.m -o test-input
  ./test-input
构建不会自动启动游戏。

排查是否加载
游戏日志：~/Library/Logs/mkarpenko/WorldBox/Player.log
查找：[WorldBox Trackpad v2] loaded
首次在地图滑动后应出现：direct camera bridge ready
启动器日志：~/Library/Logs/WorldBoxTrackpad/launch.log
不识别其他版本时，相机平移不会启用。

卸载
保存退出游戏，从 Steam 正常启动即可恢复原版输入。
不再使用时移除整个补丁文件夹。不要删除游戏或存档。

设计参考
Miro 触控板导航：https://help.miro.com/hc/en-us/articles/360017731053-Using-Miro-with-a-mouse-trackpad-or-touchscreen
Apple 手势事件：https://developer.apple.com/library/archive/documentation/Cocoa/Conceptual/EventOverview/HandlingTouchEvents/HandlingTouchEvents.html
