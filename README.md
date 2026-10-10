# FPS Overlay — Theos project

这是一个轻量级实时帧率悬浮窗越狱插件源码项目，面向 iOS 15+、arm64/arm64e，适合作为 iOS 17.1.1 rootless / RootHide 的 Theos 构建起点。

## 功能
- 显示 FPS 数字悬浮窗，每秒更新一次。
- 黑色半透明底、白色等宽数字。
- 当前默认注入目标为 SpringBoard，方便先验证构建和显示逻辑。

## 重要说明
- 这里提供的是**可构建源码包**，不是已编译并实机验证的 `.deb`。当前环境没有 iOS Theos/Xcode 工具链，不能诚实地声称已生成可直接安装的成品。
- `FPSOverlay.plist` 当前仅列出 `com.apple.springboard`。要在特定 App 内显示，请把该 App 的 Bundle ID 添加到 `Bundles` 数组，并确保你的越狱环境已允许对该 App 注入 tweak。
- RootHide Bootstrap 默认不会自动向所有第三方 App 注入 tweak，需要在 Bootstrap 的 App List 中启用目标 App。SpringBoard 注入在不同 RootHide 版本/配置下可能受限制。
- 该实现统计的是 `CADisplayLink` 回调节奏，属于应用主线程可见的近似帧率；主线程卡顿、后台状态或系统合成器行为会影响读数，不等同于系统级 GPU 实际呈现帧率。
- 安装任何越狱插件前建议保留可进入安全模式/卸载插件的方式。

## 构建
先安装支持当前越狱环境的 Theos（RootHide 用户可使用 roothide/theos），进入项目目录：

### RootHide
```sh
make clean
make package THEOS_PACKAGE_SCHEME=roothide
```

### 标准 rootless
```sh
make clean
make package THEOS_PACKAGE_SCHEME=rootless
```

构建成功后，安装包通常会出现在 `packages/` 目录。请确认包内路径和目标环境匹配后再安装。

## 修改注入目标
编辑 `FPSOverlay.plist`，例如添加目标 App：
```plist
Filter = {
    Bundles = (
        "com.apple.springboard",
        "com.example.game"
    );
};
```
把 `com.example.game` 替换为目标应用真实的 Bundle ID。
