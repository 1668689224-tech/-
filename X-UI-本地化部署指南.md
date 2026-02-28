# 3X-UI 本地化部署指南

## 📋 概述

本方案将原版依赖作者 GitHub 仓库的 3X-UI 脚本改造为**完全本地化、去中心化**的版本，确保不会因作者删除仓库而失效。

## 🎯 核心优势

1. **零外部依赖** - 不调用任何外部脚本或 API
2. **完全可控** - 所有文件都在你的服务器上
3. **备份恢复** - 完整的配置备份和恢复机制
4. **安全可靠** - 避免第三方脚本的安全风险

## 📁 文件结构

```
/root/.openclaw/workspace/
├── x-ui-local.sh          # 本地化管理脚本（主脚本）
├── prepare-x-ui.sh        # 安装文件准备脚本
└── X-UI-本地化部署指南.md  # 本指南
```

## 🚀 快速开始

### 步骤 1: 准备安装文件

```bash
# 1. 给脚本执行权限
chmod +x prepare-x-ui.sh x-ui-local.sh

# 2. 运行准备脚本
./prepare-x-ui.sh
```

在菜单中选择下载方式：
- **选项 1**: 从 GitHub 下载（可能失效）
- **选项 2**: 从镜像源下载（推荐）
- **选项 3**: 自定义下载链接
- **选项 4**: 使用本地已有文件

### 步骤 2: 安装到系统

在准备脚本中选择 **选项 6**，将文件安装到系统目录：
- `/usr/local/x-ui/x-ui` - 可执行文件
- `/etc/x-ui/config.json` - 配置文件
- `/etc/systemd/system/x-ui.service` - 系统服务

### 步骤 3: 使用本地化管理

```bash
# 启动管理菜单
./x-ui-local.sh menu

# 或使用命令行
./x-ui-local.sh start      # 启动
./x-ui-local.sh stop       # 停止
./x-ui-local.sh status     # 状态
./x-ui-local.sh backup     # 备份
```

## 🔧 功能对比

### 原版脚本的问题：
- ✅ 安装/更新依赖作者 GitHub
- ✅ 版本检查依赖 GitHub API
- ✅ WARP/订阅转换依赖其他作者
- ✅ 无法控制更新内容

### 本地化版本的改进：
- ✅ **安装**: 手动准备文件，完全控制
- ✅ **更新**: 手动更新，避免意外变更
- ✅ **管理**: 所有功能本地化
- ✅ **备份**: 完整的配置备份/恢复
- ✅ **安全**: 无外部脚本执行风险

## 📊 功能列表

### 核心管理功能：
- [x] 启动/停止/重启面板
- [x] 查看状态和日志
- [x] 启用/禁用开机自启
- [x] 备份和恢复配置
- [x] 导出/导入配置

### 配置管理：
- [x] 重置用户名密码
- [x] 修改面板端口
- [x] 防火墙管理
- [x] BBR 加速启用

### 安全特性：
- [x] 配置自动备份
- [x] 恢复点管理
- [x] 敏感信息保护提示
- [x] 操作确认提示

## 🛡️ 安全建议

### 1. 文件安全
```bash
# 设置正确的权限
chmod 750 /usr/local/x-ui/x-ui
chmod 600 /etc/x-ui/config.json
chown root:root /usr/local/x-ui/x-ui
```

### 2. 定期备份
```bash
# 手动备份配置
./x-ui-local.sh backup

# 备份文件位置
/var/backup/x-ui/x-ui-backup-*.tar.gz
```

### 3. 监控日志
```bash
# 查看实时日志
./x-ui-local.sh log

# 或使用 journalctl
journalctl -u x-ui.service -f
```

## 🔄 更新策略

### 手动更新流程：
1. **备份当前配置**
   ```bash
   ./x-ui-local.sh backup
   ```

2. **下载新版本**
   ```bash
   ./prepare-x-ui.sh
   # 选择下载方式获取新版本
   ```

3. **测试新版本**
   ```bash
   # 在测试环境部署
   # 验证功能正常
   ```

4. **生产环境更新**
   ```bash
   # 停止服务
   ./x-ui-local.sh stop
   
   # 替换文件
   cp /tmp/x-ui-prepare/x-ui /usr/local/x-ui/
   
   # 启动服务
   ./x-ui-local.sh start
   ```

## 🗂️ 配置文件管理

### 配置文件位置：
```
/etc/x-ui/config.json          # 主配置文件
/var/backup/x-ui/             # 备份目录
  ├── x-ui-backup-*.tar.gz    # 完整备份
  └── x-ui-export-*.json      # 配置导出
```

### 配置示例：
```json
{
  "panelSettings": {
    "webPort": 2053,
    "webCertFile": "",
    "webKeyFile": "",
    "webBasePath": "",
    "secret": "",
    "webHost": "0.0.0.0"
  }
}
```

## 🚨 故障排除

### 常见问题：

1. **面板无法启动**
   ```bash
   # 检查日志
   journalctl -u x-ui.service -n 50
   
   # 检查权限
   ls -la /usr/local/x-ui/x-ui
   
   # 检查端口占用
   netstat -tlnp | grep :2053
   ```

2. **配置文件错误**
   ```bash
   # 验证 JSON 格式
   python3 -m json.tool /etc/x-ui/config.json
   
   # 恢复备份
   ./x-ui-local.sh menu
   # 选择 "恢复备份"
   ```

3. **服务管理问题**
   ```bash
   # 重新加载 systemd
   systemctl daemon-reload
   
   # 重置失败状态
   systemctl reset-failed x-ui
   ```

## 📈 维护计划

### 每日检查：
- [ ] 服务状态
- [ ] 错误日志
- [ ] 磁盘空间

### 每周维护：
- [ ] 备份完整性检查
- [ ] 日志清理
- [ ] 安全更新检查

### 每月维护：
- [ ] 配置文件审查
- [ ] 性能监控
- [ ] 备份恢复测试

## 🔗 资源链接

### 备用下载源：
- GitHub 镜像: `https://ghproxy.com/`
- 91 镜像: `https://github.91chi.fun/`
- 中转站: `https://pd.zwc365.com/seturl/`

### 相关项目：
- 原版 3X-UI: `https://github.com/xeefei/3x-ui`
- X-UI 原版: `https://github.com/vaxilu/x-ui`
- Xray Core: `https://github.com/XTLS/Xray-core`

## 📝 版本记录

### v1.0.0 (当前版本)
- ✅ 基础管理功能
- ✅ 配置备份恢复
- ✅ 防火墙管理
- ✅ BBR 加速支持

### 计划功能：
- [ ] Web 界面配置
- [ ] 自动更新检查
- [ ] 多节点管理
- [ ] 性能监控面板

---

## 🎯 最后建议

1. **测试环境先行** - 先在测试服务器部署验证
2. **定期备份** - 配置变更前务必备份
3. **监控告警** - 设置服务监控
4. **文档更新** - 记录所有自定义配置

通过此本地化方案，你完全掌控了 3X-UI 面板的管理，不再受制于任何第三方作者的变更或删除。

**安全、可控、可靠** - 这就是本地化部署的核心价值。