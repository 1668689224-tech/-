#!/bin/bash
# ============================================================================
# OpenClaw 中文社区 超简安装脚本
# 独立版本 - 不依赖外部网络脚本
# 创建时间: 2026-02-28
# ============================================================================

set -euo pipefail

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# 配置
REGISTRY="${1:-https://registry.npmmirror.com}"
PACKAGE="openclaw-cn"
VERSION="latest"

print_header() {
    echo -e "${BLUE}"
    echo "╔══════════════════════════════════════════════════════╗"
    echo "║          OpenClaw 中文社区 - 独立安装器             ║"
    echo "║                版本 1.0 (便携版)                    ║"
    echo "╚══════════════════════════════════════════════════════╝"
    echo -e "${NC}"
    echo "📦 镜像源: $REGISTRY"
    echo "📦 包名称: $PACKAGE"
    echo "📦 版本: $VERSION"
    echo ""
}

check_deps() {
    echo -e "${BLUE}[1/4] 检查依赖...${NC}"
    
    local missing=()
    
    if ! command -v node &> /dev/null; then
        missing+=("Node.js")
    fi
    
    if ! command -v npm &> /dev/null; then
        missing+=("npm")
    fi
    
    if [[ ${#missing[@]} -gt 0 ]]; then
        echo -e "${RED}✗ 缺少依赖:${NC}"
        for dep in "${missing[@]}"; do
            echo "  - $dep"
        done
        echo ""
        echo -e "${YELLOW}安装指南:${NC}"
        echo "  macOS:    brew install node"
        echo "  Ubuntu:   sudo apt install nodejs npm"
        echo "  CentOS:   sudo yum install nodejs npm"
        exit 1
    fi
    
    echo -e "${GREEN}✓ 依赖检查通过${NC}"
    echo "  Node.js: $(node --version 2>/dev/null || echo '未找到')"
    echo "  npm: $(npm --version 2>/dev/null || echo '未找到')"
    echo ""
}

setup_npm() {
    echo -e "${BLUE}[2/4] 配置 npm...${NC}"
    
    # 设置镜像源
    if npm config set registry "$REGISTRY" 2>/dev/null; then
        echo -e "${GREEN}✓ 已设置 npm 镜像源: $REGISTRY${NC}"
    else
        echo -e "${YELLOW}⚠ 无法设置 npm 配置，继续尝试...${NC}"
    fi
    
    # 禁用 fund 和 audit 消息
    npm config set fund false 2>/dev/null || true
    npm config set audit false 2>/dev/null || true
    
    echo ""
}

install_clawd() {
    echo -e "${BLUE}[3/4] 安装 OpenClaw...${NC}"
    
    local install_cmd="npm install -g $PACKAGE"
    if [[ "$VERSION" != "latest" ]]; then
        install_cmd="npm install -g $PACKAGE@$VERSION"
    fi
    
    echo "执行: $install_cmd"
    echo ""
    
    # 尝试安装
    if eval "$install_cmd"; then
        echo -e "${GREEN}✓ 安装成功${NC}"
    else
        echo -e "${YELLOW}⚠ 第一次安装失败，尝试清理后重试...${NC}"
        
        # 清理可能存在的残留
        npm_prefix="$(npm config get prefix 2>/dev/null || echo '')"
        if [[ -n "$npm_prefix" ]]; then
            target_dir="$npm_prefix/lib/node_modules/$PACKAGE"
            if [[ -d "$target_dir" ]]; then
                echo "清理残留目录: $target_dir"
                rm -rf "$target_dir" 2>/dev/null || true
            fi
        fi
        
        # 重试
        if eval "$install_cmd"; then
            echo -e "${GREEN}✓ 重试安装成功${NC}"
        else
            echo -e "${RED}✗ 安装失败${NC}"
            echo ""
            echo -e "${YELLOW}可能的解决方案:${NC}"
            echo "1. 使用 sudo 运行: sudo $0 $REGISTRY"
            echo "2. 更改 npm 全局安装目录:"
            echo "   npm config set prefix ~/.npm-global"
            echo "   echo 'export PATH=~/.npm-global/bin:\$PATH' >> ~/.bashrc"
            echo "3. 检查网络连接"
            exit 1
        fi
    fi
    
    echo ""
}

verify_install() {
    echo -e "${BLUE}[4/4] 验证安装...${NC}"
    
    if command -v openclaw-cn &> /dev/null; then
        echo -e "${GREEN}✓ OpenClaw 已安装${NC}"
        echo "  版本: $(openclaw-cn --version 2>/dev/null || echo '未知')"
        echo "  路径: $(which openclaw-cn)"
    else
        echo -e "${YELLOW}⚠ 命令未找到，尝试在 PATH 中查找...${NC}"
        
        # 查找可能的安装位置
        npm_prefix="$(npm config get prefix 2>/dev/null || echo '')"
        if [[ -n "$npm_prefix" ]]; then
            bin_path="$npm_prefix/bin/openclaw-cn"
            if [[ -f "$bin_path" ]]; then
                echo -e "${GREEN}✓ 找到可执行文件: $bin_path${NC}"
                echo "  请确保该目录在 PATH 环境变量中"
                echo "  临时使用: export PATH=\"$npm_prefix/bin:\$PATH\""
            fi
        fi
    fi
    
    echo ""
}

show_next_steps() {
    echo -e "${BLUE}🎉 安装完成！${NC}"
    echo ""
    echo -e "${GREEN}下一步操作:${NC}"
    echo "1. 运行配置向导:"
    echo "   openclaw-cn onboard"
    echo ""
    echo "2. 查看帮助:"
    echo "   openclaw-cn --help"
    echo ""
    echo "3. 启动服务:"
    echo "   openclaw-cn gateway start"
    echo ""
    echo -e "${YELLOW}📝 此脚本为独立版本，不依赖外部网络脚本${NC}"
    echo "   保存此文件即可随时重新安装"
    echo ""
}

# 主流程
main() {
    print_header
    check_deps
    setup_npm
    install_clawd
    verify_install
    show_next_steps
}

# 显示帮助
show_help() {
    echo -e "${BLUE}OpenClaw 独立安装脚本${NC}"
    echo ""
    echo "用法:"
    echo "  $0 [镜像源地址]"
    echo ""
    echo "示例:"
    echo "  $0                           # 使用默认镜像源 (npmmirror.com)"
    echo "  $0 https://registry.npmjs.org  # 使用官方 npm 源"
    echo "  sudo $0                     # 需要权限时使用"
    echo ""
    echo "默认镜像源: https://registry.npmmirror.com (淘宝镜像)"
    exit 0
}

# 参数处理
if [[ "$1" == "-h" || "$1" == "--help" ]]; then
    show_help
fi

# 运行主函数
main "$@"