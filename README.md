# 3X-UI 本地化部署包

## 📦 概述

这是一个完全本地化的 3X-UI 部署方案，不依赖任何外部 GitHub 仓库或作者资源。即使原版作者删除仓库，此方案仍然可用。

## 🎯 核心优势

### **完全可控**
- ✅ 零外部依赖 - 不调用任何外部脚本或 API
- ✅ 本地化管理 - 所有文件都在你的服务器上
- ✅ 手动更新 - 避免意外变更破坏服务
- ✅ 完整备份 - 配置备份和恢复机制

### **安全可靠**
- 🔒 避免第三方脚本的安全风险
- 🔒 敏感信息本地存储
- 🔒 操作确认和日志记录
- 🔒 防火墙和安全配置

## 🚀 一键安装

### **方法1：直接运行**
```bash
# 下载并运行安装脚本
curl -fsSL https://raw.githubusercontent.com/1668689224-tech/-/main/install-x-ui.sh | bash
```

### **方法2：使用sudo**
```bash
# 需要root权限
sudo bash -c "$(curl -fsSL https://raw.githubusercontent.com/1668689224-tech/-/main/install-x-ui.sh)"
```

### **方法3：下载后安装**
```bash
# 下载脚本
curl -fsSL https://raw.githubusercontent.com/1668689224-tech/-/main/install-x-ui.sh -o install-x-ui.sh

# 添加执行权限
chmod +x install-x-ui.sh

# 运行安装
sudo ./install-x-ui.sh
```

## 📁 文件结构

### **仓库文件**
```
https://github.com/1668689224-tech/-/main/
├── install-x-ui.sh              # 一键安装脚本（推荐使用）
├── x-ui-local/                  # 本地化包目录
│   ├── x-ui-local.sh           # 本地化管理脚本
│   ├── prepare-x-ui.sh         # 安装文件准备脚本
│   ├── X-UI-本地化部署指南.md   # 详细部署指南
│   └── x-ui-local-package.tar.gz # 完整打包
```

### **安装后文件**
```
/usr/local/bin/x-ui-local        # 管理命令
/etc/x-ui/                       # 配置文件目录
/usr/local/x-ui/                 # 程序文件目录
/var/backup/x-ui/                # 备份目录
/var/log/x-ui-local/             # 日志目录
```

## 🔧 安装流程

安装脚本会自动完成以下步骤：

1. **权限检查** - 验证root权限
2. **依赖检查** - 检查curl、tar等工具
3. **文件下载** - 从GitHub下载必要文件
4. **准备安装** - 解压和设置权限
5. **运行准备** - 下载x-ui核心文件
6. **系统配置** - 创建目录和配置文件
7. **验证安装** - 检查安装结果

## 📋 使用指南

### **启动管理菜单**
```bash
x-ui-local menu
```

### **常用命令**
```bash
# 服务管理
x-ui-local start      # 启动面板
x-ui-local stop       # 停止面板
x-ui-local restart    # 重启面板
x-ui-local status     # 查看状态

# 配置管理
x-ui-local backup     # 备份配置
x-ui-local restore    # 恢复配置
x-ui-local reset      # 重置密码

# 系统管理
x-ui-local log        # 查看日志
x-ui-local update     # 手动更新
x-ui-local firewall   # 防火墙管理
```

### **访问面板**
- **地址**: `http://你的服务器IP:2053`
- **默认账号**: `admin`
- **默认密码**: `admin`

**首次登录后请立即修改密码！**

## ⚙️ 配置说明

### **端口配置**
默认使用 `2053` 端口，可在以下位置修改：
- 配置文件: `/etc/x-ui/config.json`
- 使用命令: `x-ui-local menu` → 修改面板端口

### **防火墙配置**
如果使用UFW，安装脚本会自动添加规则：
```bash
ufw allow 2053/tcp comment "x-ui panel"
```

### **备份配置**
自动备份位置：`/var/backup/x-ui/`
- 完整备份: `x-ui-backup-*.tar.gz`
- 配置导出: `x-ui-export-*.json`

## 🔄 更新策略

### **手动更新流程**
1. **备份当前配置**
   ```bash
   x-ui-local backup
   ```

2. **下载新版本**
   ```bash
   cd /tmp
   curl -fsSL https://raw.githubusercontent.com/1668689224-tech/-/main/install-x-ui.sh -o update-x-ui.sh
   chmod +x update-x-ui.sh
   sudo ./update-x-ui.sh
   ```

3. **恢复配置**（如果需要）
   ```bash
   x-ui-local restore
   ```

## 🛡️ 安全建议

### **1. 密码安全**
```bash
# 首次登录后立即修改
# 面板设置 → 修改密码
```

### **2. 访问控制**
```bash
# 限制访问IP
ufw allow from 你的IP to any port 2053
ufw deny 2053/tcp
```

### **3. 定期备份**
```bash
# 设置定时备份（每天）
echo "0 2 * * * root /usr/local/bin/x-ui-local backup" > /etc/cron.d/x-ui-backup
```

### **4. 监控日志**
```bash
# 查看实时日志
tail -f /var/log/x-ui-local/access.log

# 或使用journalctl
journalctl -u x-ui.service -f
```

## 🚨 故障排除

### **常见问题**

#### **1. 面板无法启动**
```bash
# 检查日志
journalctl -u x-ui.service -n 50

# 检查端口占用
netstat -tlnp | grep :2053

# 检查权限
ls -la /usr/local/x-ui/x-ui
```

#### **2. 无法访问面板**
```bash
# 检查防火墙
ufw status

# 检查服务状态
systemctl status x-ui.service

# 检查网络连接
curl -v http://localhost:2053
```

#### **3. 配置错误**
```bash
# 验证JSON格式
python3 -m json.tool /etc/x-ui/config.json

# 恢复备份
x-ui-local menu
# 选择"恢复备份"
```

## 📞 支持与反馈

### **问题报告**
如果遇到问题，请提供：
1. 操作系统信息：`cat /etc/os-release`
2. 错误日志：`journalctl -u x-ui.service -n 100`
3. 安装方式：使用的命令和参数

### **功能建议**
欢迎提出改进建议，可通过：
- GitHub Issues
- 提交Pull Request

## 📄 许可证

本项目基于原版 3X-UI 修改，遵循相同许可证。

## 🔗 相关链接

- **原版 3X-UI**: https://github.com/xeefei/3x-ui
- **X-UI 原版**: https://github.com/vaxilu/x-ui
- **Xray Core**: https://github.com/XTLS/Xray-core
- **备用镜像**: https://ghproxy.com/

---

## 🎯 最后提醒

通过此本地化方案，你完全掌控了 3X-UI 面板的管理，不再受制于任何第三方作者的变更或删除。

**安全、可控、可靠** - 这就是本地化部署的核心价值。

**一键安装命令：**
```bash
curl -fsSL https://raw.githubusercontent.com/1668689224-tech/-/main/install-x-ui.sh | bash
```