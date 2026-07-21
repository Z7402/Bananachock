# 🍌 Bananachock

**专注计时 · 沉浸动画 · 长期时间管理**

> 让每一次专注都更自然、更有节奏。

Bananachock 是一款专为 Android 打造的 Flutter 应用，将番茄钟与正向计时统一在一个界面中，并配有从海平线升起的太阳光影动画、可自定义壁纸色调的动态主题以及完备的统计复盘功能。

---

## ✨ 特色功能

### ⏱️ 双模式计时
- **番茄钟**：专注时段 + 休息时段自动循环，支持预制时长（25/30/45 分钟）与自定义时长
- **正向计时**：自由记录任意任务耗时，可随时停止并保存为记录
- **阶段标签**：专注中 / 休息中状态清晰可见

### 🌅 沉浸式光影动画
- 太阳沿弧形轨迹东升西落，大小随高度变化
- 中景与前景海浪分层绘制，营造「从海中升起、落入海中」的深度感
- 宽幅环境光束 + 多层柔光光晕，光影随进度动态变化
- 海面碎金反射，增强视觉真实感
- 海浪采用线性循环 + 整数倍谐波，无周期接缝跳变

### 🖼️ 动态壁纸主题
- 选择本地图片作为背景壁纸
- 自动提取主色、辅助色、强调色，适配全界面色调
- 可调节壁纸透明度（0%–100%），持久化保存
- 一键移除壁纸，恢复默认配色

### 🧘 沉浸全屏 & 横竖屏
- 开始番茄钟专注后自动进入 **沉浸式全屏**（隐藏状态栏/导航栏）
- 界面仅保留时间、暂停/继续、跳过、方向选择、退出五项控制
- 支持三种屏幕方向模式：**自动旋转 / 锁定竖屏 / 锁定横屏**
- 横竖屏切换时通过 `AnimatedSwitcher` 实现淡入 + 滑动平滑衔接
- 普通界面↔沉浸界面使用缩放 + 淡入过渡

### 📊 数据统计
- 专注次数、总时长、当前连续天数展示
- 按天/周/月查看专注时长柱状图
- 每次专注记录可包含任务名称与时长

### 🎨 Material 3 动态主题
- 支持 **浅色 / 深色 / 跟随系统** 三种模式
- 基于壁纸色调自动生成配色方案

---

## 🧰 技术栈

| 层级 | 技术 |
|------|------|
| 框架 | Flutter (Dart SDK ≥3.1.0) |
| 状态管理 | Riverpod (flutter_riverpod) |
| 设计语言 | Material 3 (Material You 动态配色) |
| UI 动画 | CustomPainter + AnimationController + AnimatedSwitcher |
| 本地存储 | SharedPreferences |
| 图表 | fl_chart |
| 其他 | url_launcher, image_picker, palette_generator, audioplayers, dynamic_color |

---

## 📱 系统要求

- **Android 5.0 (API 21)** 及以上
- **架构**：arm64-v8a（当前构建目标）

---

## ⬇️ 下载与安装

1. 前往 [GitHub Releases](https://github.com/Z7402/Bananachock/releases/latest) 下载最新 APK
2. 在 Android 设备上允许“安装未知来源应用”
3. 打开 APK 文件完成安装

> 所有 Release 均通过 GitHub Actions 自动构建并签名发布。

---

## 🔧 开发指南

### 环境准备

```bash
# 确保已安装 Flutter SDK (stable 渠道)
flutter --version

# 克隆仓库
git clone https://github.com/Z7402/Bananachock.git
cd Bananachock

# 安装依赖
flutter pub get
```

### 运行与调试

```bash
# 连接 Android 设备后运行
flutter run

# 或构建 Debug APK
flutter build apk --debug
```

### 发布构建

项目配置了 GitHub Actions 工作流，推送到 `main` 分支后自动：

1. 安装 Flutter + Java 17
2. 导入签名密钥并构建 **release ARM64 APK**
3. 上传构建产物并发布 GitHub Release

---

## 🏷️ 版本历史

| 版本 | 标签 | 说明 |
|------|------|------|
| v1.1.0 | `build-86` | 沉浸全屏 + 横竖屏适配 + 光影增强 + 关于页 + 壁纸透明度 |
| v1.0.14 | `build-85` | 太阳多层柔光 + 海浪层次感 + 全屏专注模式 |
| v1.0.13 | `build-84` | 修复海浪跳变 + 壁纸透明度滑杆 + 计时动效修复 |
| v1.0.0 | `build-51` | 首个公开构建版本 |

> 完整变更记录请查看 [GitHub Releases](https://github.com/Z7402/Bananachock/releases)。

---

## 👤 作者

- **Z7402** — Bananachock 设计与开发
- GitHub: [@Z7402](https://github.com/Z7402)
- 项目仓库: [Z7402/Bananachock](https://github.com/Z7402/Bananachock)

## 🤝 贡献与反馈

- 🐛 遇到问题或需要新功能？请提交 [GitHub Issues](https://github.com/Z7402/Bananachock/issues)
- ⭐ 欢迎给项目点 Star，支持长期开发

---

<p align="center"><strong>Made with focus by Z7402</strong></p>
