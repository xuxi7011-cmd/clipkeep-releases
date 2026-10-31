# 拾光裁切 · 安装与更新

导入 MP4 / MKV，选择时长或按声音随机选段，导出 MP4。默认五分钟，支持批量和 PNG 贴图。

## 下载 Windows 版

[下载最新安装包](https://github.com/xuxi7011-cmd/clipkeep-releases/releases/latest)

下载发布页中的 `ClipKeep-Setup-版本号-x64.exe` 并安装。其他文件供软件自动更新或第三方源码核查，普通使用无需逐个下载。

Windows 1.3.0 / 1.4.0 安装版可在软件内点 **软件更新 → 检查更新 → 下载 → 重启并更新**。应用启动后也会检查版本，但不自动下载、不强制重启、不在导出时打断任务。旧 ZIP 版需要先手动安装一次 EXE。

Mac 自动更新尚未开放，本页当前只发布 Windows x64。

## 1.4.1

- 普通视频优先直接复制，MP4 / MKV 都能走快速裁切。
- 去掉手动确认片源色彩和音轨转换的步骤；明确的 HDR 自动转换 SDR。
- 随机片段参考首尾音量和关键帧，并显示切点附近波形。它不识别剧情，也不保证每句对白完整。
- 提供 Windows 视频引擎完整对应源码、固定修订、构建配方和许可证。

快速复制受关键帧限制；精确裁切、PNG 贴图和 HDR 转换需要重新编码。不兼容音轨转 AAC 时保留支持的声道数，但 AAC 转换有损，Atmos 等扩展不保留。可切换内封字幕不随 MP4 保留，已压入画面的字幕不受影响。

## 验证与来源

Mac 上已验证实际桌面导入、选段与批量导出；Windows 视频引擎、安装器静默安装及安装后程序运行已在 Windows 构建环境实测。Windows 桌面操作、旧版覆盖升级以及用户真实片源仍需对应机器验收。安装器暂无开发者发行签名，不建议关闭系统安全保护。

[Windows 安装测试](https://github.com/xuxi7011-cmd/clipkeep-releases/actions/runs/41156151179) · [第三方引擎构建记录](https://github.com/xuxi7011-cmd/clipkeep-releases/actions/workflows/engine.yml) · [构建配方](engine/build.sh)

发布页附 `SHA256SUMS.txt` 及 `ClipKeep-FFmpeg-Windows-Corresponding-Source-1.4.1.tar.xz`。源码包对应本版安装器中的 FFmpeg / FFprobe 与所启用外部库，不是应用工程源码。

此仓库只存安装程序、更新说明及第三方分发资料，不存用户视频、字幕、密钥或私有应用工程。
