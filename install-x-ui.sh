#!/bin/bash
# ============================================================================
# 3X-UI 本地化一键安装脚本
# 独立版本 - 不依赖外部脚本
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
REPO_URL="https://raw.githubusercontent.com/1668689224-tech/-/main/x-ui-local"
INSTALL_DIR="/usr/local/x-ui"
CONFIG_DIR="/etc/x-ui"
BACKUP_DIR="/var/backup/x-ui"

print_header() {
    echo -e "${BLUE}"
    echo "╔══════════════════════════════════════════════════════╗"
    echo "║          3X-UI 本地化一键安装器                     ║"
    echo "║              版本 1.0 (独立版)                      ║"
    echo "╚══════════════════════════════════════════════════════╝"
    echo -e "${NC}"
    echo "📦 仓库: https://github.com/1668689224-tech/-"
    echo "📦 模式: 完全本地化，不依赖外部资源"
    echo ""
}

check_root() {
    if [[ $EUID -ne 0 ]]; then
        echo -e "${RED}错误: 需要root权限运行此脚本${NC}"
        echo -e "${YELLOW}请使用: sudo $0${NC}"
        exit 1
    fi
    echo -e "${GREEN}✓ Root权限检查通过${NC}"
}

check_deps() {
    echo -e "${BLUE}[1/6] 检查依赖...${NC}"
    
    local missing=()
    
    if ! command -v curl &> /dev/null; then
        missing+=("curl")
    fi
    
    if ! command -v tar &> /dev/null; then
        missing+=("tar")
    fi
    
    if ! command -v systemctl &> /dev/null; then
        missing+=("systemd")
    fi
    
    if [[ ${#missing[@]} -gt 0 ]]; then
        echo -e "${RED}✗ 缺少依赖:${NC}"
        for dep in "${missing[@]}"; do
            echo "  - $dep"
        done
        echo ""
        echo -e "${YELLOW}安装指南:${NC}"
        echo "  Ubuntu/Debian: sudo apt update && sudo apt install -y curl tar"
        echo "  CentOS/RHEL: sudo yum install -y curl tar"
        exit 1
    fi
    
    echo -e "${GREEN}✓ 依赖检查通过${NC}"
    echo "  curl: $(curl --version 2>/dev/null | head -1 | awk '{print $2}' || echo '未找到')"
    echo "  tar: $(tar --version 2>/dev/null | head -1 | awk '{print $4}' || echo '未找到')"
    echo ""
}

download_files() {
    echo -e "${BLUE}[2/6] 下载文件...${NC}"
    
    local files=(
        "x-ui-local.sh"
        "prepare-x-ui.sh"
        "X-UI-本地化部署指南.md"
        "x-ui-local-package.tar.gz"
    )
    
    mkdir -p /tmp/x-ui-install
    cd /tmp/x-ui-install
    
    for file in "${files[@]}"; do
        echo "下载: $file"
        if curl -fsSL "$REPO_URL/$file" -o "$file" 2>/dev/null; then
            echo -e "  ${GREEN}✓ 成功${NC}"
        else
            echo -e "  ${RED}✗ 失败${NC}"
            echo -e "${YELLOW}尝试备用下载方式...${NC}"
            # 备用下载方式
            curl -fsSL "https://ghproxy.com/$REPO_URL/$file" -o "$file" 2>/dev/null || {
                echo -e "${RED}无法下载文件，请检查网络${NC}"
                exit 1
            }
        fi
    done
    
    echo -e "${GREEN}✓ 文件下载完成${NC}"
    echo ""
}

prepare_installation() {
    echo -e "${BLUE}[3/6] 准备安装...${NC}"
    
    # 解压包
    if [[ -f "x-ui-local-package.tar.gz" ]]; then
        echo "解压安装包..."
        tar -xzvf x-ui-local-package.tar.gz
    fi
    
    # 设置执行权限
    chmod +x x-ui-local.sh prepare-x-ui.sh
    
    echo -e "${GREEN}✓ 安装准备完成${NC}"
    echo ""
}

run_prepare_script() {
    echo -e "${BLUE}[4/6] 运行准备脚本...${NC}"
    echo -e "${YELLOW}请按照提示操作:${NC}"
    echo "  1. 选择下载方式 (推荐选项2: 镜像源下载)"
    echo "  2. 下载必要文件"
    echo "  3. 选择选项6: 安装到系统"
    echo ""
    
    # 自动选择选项2（镜像源下载）
    echo "2" | ./prepare-x-ui.sh 2>/dev/null || true
    
    # 等待用户交互完成
    echo ""
    echo -e "${YELLOW}准备脚本已完成，继续安装...${NC}"
    echo ""
}

setup_system() {
    echo -e "${BLUE}[5/6] 配置系统...${NC}"
    
    # 创建目录
    mkdir -p "$INSTALL_DIR" "$CONFIG_DIR" "$BACKUP_DIR"
    
    # 复制管理脚本
    cp x-ui-local.sh /usr/local/bin/x-ui-local 2>/dev/null || true
    chmod +x /usr/local/bin/x-ui-local 2>/dev/null || true
    
    # 设置防火墙（如果启用）
    if command -v ufw &> /dev/null && ufw status | grep -q "active"; then
        echo "配置UFW防火墙..."
        ufw allow 2053/tcp comment "x-ui panel" 2>/dev/null || true
    fi
    
    echo -e "${GREEN}✓ 系统配置完成${NC}"
    echo ""
}

verify_installation() {
    echo -e "${BLUE}[6/6] 验证安装...${NC}"
    
    # 检查文件
    local checks=0
    
    if [[ -f "/usr/local/bin/x-ui-local" ]]; then
        echo -e "${GREEN}✓ 管理脚本已安装${NC}"
        ((checks++))
    fi
    
    if [[ -d "$INSTALL_DIR" ]]; then
        echo -e "${GREEN}✓ 安装目录存在${NC}"
        ((checks++))
    fi
    
    if [[ -d "$CONFIG_DIR" ]]; then
        echo -e "${GREEN}✓ 配置目录存在${NC}"
        ((checks++))
    fi
    
    if [[ $checks -ge 3 ]]; then
        echo -e "${GREEN}✓ 安装验证通过${NC}"
    else
        echo -e "${YELLOW}⚠ 部分文件可能未正确安装${NC}"
    fi
    
    echo ""
}

show_next_steps() {
    echo -e "${BLUE}🎉 安装完成！${NC}"
    echo ""
    echo -e "${GREEN}下一步操作:${NC}"
    echo "1. 启动管理菜单:"
    echo "   x-ui-local menu"
    echo ""
    echo "2. 或使用具体命令:"
    echo "   x-ui-local start      # 启动面板"
    echo "   x-ui-local stop       # 停止面板"
    echo "   x-ui-local status     # 查看状态"
    echo "   x-ui-local backup     # 备份配置"
    echo ""
    echo "3. 访问面板:"
    echo "   地址: http://你的服务器IP:2053"
    echo "   默认账号: admin"
    echo "   默认密码: admin"
    echo ""
    echo -e "${YELLOW}📝 重要安全提醒:${NC}"
    echo "   • 首次登录后立即修改密码"
    echo "   • 配置防火墙限制访问"
    echo "   • 定期备份配置"
    echo ""
    echo -e "${BLUE}💡 更多信息请查看:${NC}"
    echo "   cat /tmp/x-ui-install/X-UI-本地化部署指南.md"
    echo ""
}

# 显示帮助
show_help() {
    echo -e "${BLUE}3X-UI 本地化一键安装脚本${NC}"
    echo ""
    echo "用法:"
    echo "  $0                 # 交互式安装"
    echo "  sudo $0           # 需要root权限"
    echo ""
    echo "选项:"
    echo "  -h, --help        显示此帮助信息"
    echo "  -y, --yes         自动模式（使用默认选项）"
    echo ""
    echo "示例:"
    echo "  curl -fsSL https://raw.githubusercontent.com/1668689224-tech/-/main/install-x-ui.sh | bash"
    echo "  sudo bash -c \"\$(curl -fsSL https://raw.githubusercontent.com/1668689224-tech/-/main/install-x-ui.sh)\""
    exit 0
}

# 主流程
main() {
    print_header
    check_root
    check_deps
    download_files
    prepare_installation
    run_prepare_script
    setup_system
    verify_installation
    show_next_steps
}

# 参数处理
if [[ "$1" == "-h" || "$1" == "--help" ]]; then
    show_help
fi

# 运行主函数
main "$@"