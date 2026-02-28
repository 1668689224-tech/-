# OpenClaw 独立安装包

## 📦 概述

这是一个完全独立的 OpenClaw 中文社区版安装包，不依赖任何外部网络脚本。即使原始安装脚本 (`https://clawd.org.cn/install.sh`) 被删除或更新，你仍然可以使用这个包进行安装。

## 🚀 快速开始

### 方法1：直接运行（推荐）
```bash
# 下载安装脚本
curl -fsSL https://你的存储地址/install-clawd.sh -o install-clawd.sh

# 添加执行权限
chmod +x install-clawd.sh

# 运行安装（默认使用淘宝镜像）
./install-clawd.sh

# 或指定镜像源
./install-clawd.sh https://registry.npmjs.org
```

### 方法2：使用 sudo（需要权限时）
```bash
sudo ./install-clawd.sh
```

## 📁 文件说明

### 主要文件
1. **`install-clawd.sh`** - 超简安装脚本（推荐）
   - 大小：~5KB
   - 功能：完整的安装流程
   - 特点：简洁、易读、易维护

2. **`install-standalone.sh`** - 完整功能版
   - 大小：~10KB
   - 功能：包含所有原始脚本功能
   - 特点：功能完整，参数丰富

3. **`install-original.sh`** - 原始脚本备份
   - 大小：~27KB
   - 来源：`https://clawd.org.cn/install.sh`
   - 备份时间：2026-02-28

### 辅助文件
4. **`packaged-installer.tar.gz`** - 完整打包文件
   - 包含所有脚本和文档
   - 方便分发和备份

## ⚙️ 安装选项

### 镜像源选择
```bash
# 淘宝镜像（中国大陆推荐，速度快）
./install-clawd.sh https://registry.npmmirror.com

# 官方 npm 镜像
./install-clawd.sh https://registry.npmjs.org

# 其他镜像
./install-clawd.sh https://registry.yarnpkg.com
```

### 完整版参数
```bash
# 查看帮助
./install-standalone.sh --help

# 详细输出
./install-standalone.sh --verbose

# 指定版本
./install-standalone.sh --version beta

# 跳过引导
./install-standalone.sh --no-onboard

# 模拟运行
./install-standalone.sh --dry-run
```

## 🔧 系统要求

### 必需依赖
- **Node.js** (v14 或更高)
- **npm** (v6 或更高)
- **bash** shell

### 可选依赖
- **git** (某些功能需要)

### 支持系统
- ✅ macOS 10.15+
- ✅ Ubuntu 18.04+
- ✅ CentOS 7+
- ✅ 其他 Linux 发行版

## 🛡️ 安全性

### 安全特性
1. **独立运行**：不下载外部脚本
2. **代码透明**：所有代码可见
3. **错误处理**：完善的错误检测
4. **权限管理**：明确的权限提示

### 安全建议
1. **检查脚本**：运行前查看脚本内容
2. **使用可信源**：从可信位置下载
3. **定期更新**：关注 OpenClaw 更新

## 🔄 更新维护

### 脚本更新
当需要更新安装脚本时：
1. 备份当前版本
2. 下载最新原始脚本
3. 对比并合并更改
4. 测试新版本

### 版本记录
- **v1.0.0** (2026-02-28)
  - 初始版本
  - 基于原始脚本 v? (clawd.org.cn)
  - 添加独立运行功能

## 🆘 故障排除

### 常见问题

#### 1. 权限不足
```bash
# 方案A：使用 sudo
sudo ./install-clawd.sh

# 方案B：更改 npm 安装目录
npm config set prefix ~/.npm-global
echo 'export PATH=~/.npm-global/bin:$PATH' >> ~/.bashrc
source ~/.bashrc
./install-clawd.sh
```

#### 2. 网络问题
```bash
# 尝试不同镜像源
./install-clawd.sh https://registry.npmjs.org

# 检查网络连接
curl -I https://registry.npmjs.org
```

#### 3. 依赖缺失
```bash
# Ubuntu/Debian
sudo apt update
sudo apt install nodejs npm

# macOS
brew install node

# CentOS/RHEL
sudo yum install nodejs npm
```

### 获取帮助
1. 查看脚本帮助：`./install-clawd.sh --help`
2. 查看 OpenClaw 帮助：`openclaw-cn --help`
3. 访问社区：https://clawd.org.cn

## 📄 许可证

本安装脚本基于原始 OpenClaw 安装脚本修改，遵循相同许可证。

## 🤝 贡献

欢迎提交问题和改进建议！

---

**最后更新：2026-02-28**
**保持独立，随时安装！**