# M4A 音频转换器（macOS）

一个面向日常使用的轻量级 macOS 音频转换工具。选择一个或多个音频文件，转换为 MP3、WAV 或 FLAC；原文件始终保留。

## 功能

- 中文图形界面，无需输入命令
- 支持一次选择多个音频文件
- 输出 MP3、WAV、FLAC
- MP3 使用 256 kbps
- WAV 使用 16-bit PCM
- 不覆盖原文件；遇到同名文件自动添加序号
- 转换完成后完整解码输出文件，确认文件确实可以读取
- 可直接打开输出文件夹

## 使用

1. 从 GitHub Releases 下载 `M4A音频转换器-Mac.zip`。
2. 解压后双击 `M4A音频转换器.app`。
3. 选择一个或多个 M4A 文件。
4. 选择输出格式和保存文件夹。

## FFmpeg 要求

应用本身不打包 FFmpeg。启动转换时会依次查找：

1. 系统 `PATH` 中的 `ffmpeg`
2. `/Applications/Plaud.app/Contents/Resources/ffmpeg`
3. `/opt/homebrew/bin/ffmpeg`
4. `/usr/local/bin/ffmpeg`

推荐使用 Homebrew 安装：

```bash
brew install ffmpeg
```

## 从源码构建

要求：macOS、自带的 `osacompile`、`codesign` 和 `ditto`。

```bash
chmod +x scripts/build.sh
./scripts/build.sh
```

生成结果：

```text
dist/M4A音频转换器-Mac.zip
```

`.app` 位于 ZIP 内。构建过程会在临时目录完成签名和解压复验，避免云盘或 Documents 文件夹附加的 Finder 元数据破坏签名校验。

运行转换冒烟测试：

```bash
chmod +x scripts/smoke-test.sh
./scripts/smoke-test.sh
```

## 项目结构

```text
src/M4A音频转换器.js   图形界面与操作流程（JXA）
src/convert_audio.sh    FFmpeg 转换、命名与完整解码校验
scripts/build.sh        构建、签名、打包与验证
scripts/smoke-test.sh   生成测试音频并验证三种输出格式
```

## 技术说明

音频编解码由成熟的 FFmpeg 及相关编码器完成。本项目的工作是针对个人使用场景进行二次封装：批量选择、中文交互、格式预设、原文件保护、重名处理和转换后验证。

转成 WAV 或 FLAC 不会恢复 M4A 已经损失的音质，但能提高部分软件的读取兼容性。

当前构建采用本机临时签名，未经过 Apple 开发者公证，定位是个人使用工具。
