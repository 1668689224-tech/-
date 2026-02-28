#!/bin/bash
set -euo pipefail

# ============================================================================
# OpenClaw 中文社区 独立安装脚本
# 版本: 1.0.0 (2026-02-28)
# 描述: 独立可移植版本，不依赖外部脚本
# ============================================================================

# 颜色定义
BOLD='\033[1m'
ACCENT='\033[38;2;255;90;45m'
INFO='\033[38;2;255;138;91m'
SUCCESS='\033[38;2;47;191;113m'
WARN='\033[38;2;255;176;32m'
ERROR='\033[38;2;226;61;45m'
MUTED='\033[38;2;139;127;119m'
NC='\033[0m'

# 默认值
DEFAULT_TAGLINE="所有聊天，一个 OpenClaw。"
DEFAULT_REGISTRY="https://registry.npmmirror.com"
CLAWDBOT_VERSION="latest"
NPM_REGISTRY="${CLAWDBOT_NPM_REGISTRY:-$DEFAULT_REGISTRY}"
VERBOSE=0
HELP=0
DRY_RUN=0
NO_ONBOARD=0
TAGLINE="${CLAWDBOT_TAGLINE:-$DEFAULT_TAGLINE}"

# 临时文件管理
TMPFILES=()
cleanup_tmpfiles() {
    local f
    for f in "${TMPFILES[@]:-}"; do
        rm -f "$f" 2>/dev/null || true
    done
}
trap cleanup_tmpfiles EXIT

mktempfile() {
    local f
    f="$(mktemp)"
    TMPFILES+=("$f")
    echo "$f"
}

# 工具检测
detect_downloader() {
    if command -v curl &> /dev/null; then
        echo "curl"
        return 0
    fi
    if command -v wget &> /dev/null; then
        echo "wget"
        return 0
    fi
    echo -e "${ERROR}错误: 缺少下载工具 (需要 curl 或 wget)${NC}"
    exit 1
}

# UTF-8 环境确保
ensure_utf8_locale() {
    if command -v locale &> /dev/null; then
        if locale -a 2>/dev/null | grep -q -i "utf-8\|utf8"; then
            export LANG="C.UTF-8" 2>/dev/null || export LANG="en_US.UTF-8" 2>/dev/null || true
            export LC_ALL="$LANG" 2>/dev/null || true
        fi
    fi
}

# 显示横幅
print_banner() {
    echo ""
    echo -e "${ACCENT}  ╭──────────────────────────────────────╮${NC}"
    echo -e "${ACCENT}  │${NC}       ${BOLD}🧡 OpenClaw 独立安装程序${NC}       ${ACCENT}│${NC}"
    echo -e "${ACCENT}  │${NC}       ${BOLD}版本 1.0.0 - 便携版${NC}           ${ACCENT}│${NC}"
    echo -e "${ACCENT}  ╰──────────────────────────────────────╯${NC}"
    echo ""
    echo -e "  ${MUTED}${TAGLINE}${NC}"
    echo -e "  ${MUTED}📦 独立版本 - 不依赖外部脚本${NC}"
    echo ""
}

# 显示使用说明
print_usage() {
    echo -e "${BOLD}用法:${NC}"
    echo "  $(basename "$0") [选项]"
    echo ""
    echo -e "${BOLD}选项:${NC}"
    echo "  -h, --help             显示此帮助信息"
    echo "  -v, --verbose          详细输出模式"
    echo "  --dry-run              模拟运行，不实际安装"
    echo "  --no-onboard           跳过引导配置"
    echo "  --registry <url>       npm 安装源 (默认: $DEFAULT_REGISTRY)"
    echo "  --version <version>    安装指定版本 (默认: latest)"
    echo ""
    echo -e "${BOLD}环境变量:${NC}"
    echo "  CLAWDBOT_NPM_REGISTRY=<url>    npm 安装源"
    echo "  CLAWDBOT_TAGLINE=<text>        自定义标语"
    echo "  CLAWDBOT_VERSION=<version>     安装版本"
    echo ""
    echo -e "${BOLD}示例:${NC}"
    echo "  $(basename "$0")"
    echo "  $(basename "$0") --registry https://registry.npmjs.org"
    echo "  $(basename "$0") --version beta --verbose"
}

# 参数解析
parse_args() {
    while [[ $# -gt 0 ]]; do
        case "$1" in
            -h|--help)
                HELP=1
                shift
                ;;
            -v|--verbose)
                VERBOSE=1
                shift
                ;;
            --dry-run)
                DRY_RUN=1
                shift
                ;;
            --no-onboard)
                NO_ONBOARD=1
                shift
                ;;
            --registry)
                if [[ -z "${2:-}" ]]; then
                    echo -e "${ERROR}错误: --registry 需要参数${NC}"
                    exit 1
                fi
                NPM_REGISTRY="$2"
                shift 2
                ;;
            --version)
                if [[ -z "${2:-}" ]]; then
                    echo -e "${ERROR}错误: --version 需要参数${NC}"
                    exit 1
                fi
                CLAWDBOT_VERSION="$2"
                shift 2
                ;;
            *)
                echo -e "${ERROR}未知选项: $1${NC}"
                print_usage
                exit 1
                ;;
        esac
    done
}

# 系统检测
detect_os() {
    case "$(uname -s)" in
        Darwin*)
            echo "macos"
            ;;
        Linux*)
            echo "linux"
            ;;
        *)
            echo -e "${ERROR}错误: 不支持的操作系统: $(uname -s)${NC}"
            exit 1
            ;;
    esac
}

# 依赖检查
check_dependencies() {
    local missing=()
    
    # 检查 Node.js 和 npm
    if ! command -v node &> /dev/null; then
        missing+=("Node.js")
    fi
    
    if ! command -v npm &> /dev/null; then
        missing+=("npm")
    fi
    
    # 检查 git（某些依赖需要）
    if ! command -v git &> /dev/null; then
        echo -e "${WARN}[!]${NC} 未找到 git，某些功能可能受限"
    fi
    
    if [[ ${#missing[@]} -gt 0 ]]; then
        echo -e "${ERROR}错误: 缺少必要依赖:${NC}"
        for dep in "${missing[@]}"; do
            echo -e "  - ${dep}"
        done
        echo ""
        echo -e "${INFO}安装指南:${NC}"
        echo -e "  ${MUTED}macOS:${NC} brew install node"
        echo -e "  ${MUTED}Ubuntu/Debian:${NC} sudo apt-get install -y nodejs npm"
        echo -e "  ${MUTED}CentOS/RHEL:${NC} sudo yum install -y nodejs npm"
        exit 1
    fi
    
    echo -e "${SUCCESS}[✓]${NC} 依赖检查通过"
}

# 清理 npm 残留
cleanup_npm_openclaw_paths() {
    local npm_prefix
    npm_prefix="$(npm config get prefix 2>/dev/null || echo "")"
    if [[ -n "$npm_prefix" ]]; then
        local target_dir="$npm_prefix/lib/node_modules/openclaw-cn"
        if [[ -d "$target_dir" ]]; then
            echo -e "${INFO}[*]${NC} 清理残留目录: $target_dir"
            rm -rf "$target_dir" 2>/dev/null || true
        fi
    fi
}

# 安装 OpenClaw
install_openclaw_npm() {
    local spec="$1"
    local log
    local registry_args=()
    local npm_exit_code=0
    log="$(mktempfile)"

    if [[ -n "${NPM_REGISTRY:-}" ]]; then
        registry_args=(--registry "$NPM_REGISTRY")
    fi

    # 临时处理 git 配置
    local git_rewrite_backup=""
    git_rewrite_backup="$(git config --global --get url."git@github.com:".insteadOf 2>/dev/null || true)"
    if [[ -n "$git_rewrite_backup" ]]; then
        git config --global --unset url."git@github.com:".insteadOf 2>/dev/null || true
    fi

    # 安装
    set +e
    set -o pipefail
    
    echo -e "${INFO}[*]${NC} 正在安装 $spec..."
    echo -e "${MUTED}  使用镜像源: ${NPM_REGISTRY}${NC}"
    
    if [[ "$VERBOSE" -eq 1 ]]; then
        npm --loglevel verbose --no-fund --no-audit ${registry_args[@]+"${registry_args[@]}"} install -g "$spec" 2>&1 | tee "$log"
    else
        npm --loglevel error --no-fund --no-audit ${registry_args[@]+"${registry_args[@]}"} install -g "$spec" 2>&1 | tee "$log"
    fi
    
    npm_exit_code=$?
    set +o pipefail
    set -e

    # 恢复 git 配置
    if [[ -n "$git_rewrite_backup" ]]; then
        git config --global url."git@github.com:".insteadOf "$git_rewrite_backup" 2>/dev/null || true
    fi

    if [[ "$npm_exit_code" -ne 0 ]]; then
        # 处理常见错误
        if grep -q "ENOTEMPTY: directory not empty, rename .*openclaw" "$log"; then
            echo -e "${WARN}[!]${NC} 检测到残留目录，正在清理并重试..."
            cleanup_npm_openclaw_paths
            npm --loglevel error --no-fund --no-audit ${registry_args[@]+"${registry_args[@]}"} install -g "$spec"
            return $?
        fi

        if grep -Eqi "(git: not found|ENOENT.*git|not found: git)" "$log"; then
            echo -e "${WARN}[!]${NC} 需要 git 但未安装"
            echo -e "${INFO}请安装 git 后重试${NC}"
        fi

        if grep -Eqi "(EACCES|permission denied)" "$log"; then
            echo -e "${WARN}[!]${NC} 权限不足，请尝试:"
            echo -e "${INFO}  sudo $(basename "$0") ${@}${NC}"
            echo -e "${INFO}或:${NC}"
            echo -e "${INFO}  npm config set prefix ~/.npm-global${NC}"
            echo -e "${INFO}  export PATH=~/.npm-global/bin:\$PATH${NC}"
        fi

        return 1
    fi

    return 0
}

# 主安装函数
install_openclaw() {
    local spec="openclaw-cn"
    
    if [[ "$CLAWDBOT_VERSION" == "beta" ]]; then
        spec="openclaw-cn@beta"
    elif [[ "$CLAWDBOT_VERSION" != "latest" ]]; then
        spec="openclaw-cn@$CLAWDBOT_VERSION"
    fi

    echo -e "${INFO}[*]${NC} 安装规格: $spec"
    
    if [[ "$DRY_RUN" -eq 1 ]]; then
        echo -e "  ${MUTED}[dry-run] npm install -g $spec${NC}"
        CLAWDBOT_BIN="openclaw-cn"
        return 0
    fi
    
    if install_openclaw_npm "$spec"; then
        echo -e "${SUCCESS}[✓]${NC} OpenClaw 安装成功"
        CLAWDBOT_BIN="openclaw-cn"
        return 0
    else
        echo -e "${ERROR}安装失败${NC}"
        return 1
    fi
}

# 显示版本信息
show_version() {
    if [[ -n "$CLAWDBOT_BIN" ]] && command -v "$CLAWDBOT_BIN" &> /dev/null; then
        echo ""
        echo -e "${SUCCESS}[✓]${NC} 已安装: $($CLAWDBOT_BIN --version 2>/dev/null || echo 'openclaw-cn')"
    fi
}

# 运行引导
run_onboard() {
    if [[ "$NO_ONBOARD" -eq 0 ]]; then
        echo ""
        echo -e "${INFO}[*]${NC} 正在启动引导配置..."
        echo ""
        
        if [[ "$DRY_RUN" -eq 1 ]]; then
            echo -e "  ${MUTED}[dry-run] $CLAWDBOT_BIN onboard${NC}"
        else
            if [[ -r /dev/tty ]]; then
                "$CLAWDBOT_BIN" onboard < /dev/tty
            else
                "$CLAWDBOT_BIN" onboard
            fi
        fi
    else
        echo ""
        echo -e "${INFO}提示:${NC} 运行 ${ACCENT}openclaw-cn onboard${NC} 开始配置"
    fi
}

# 主函数
main() {
    ensure_utf8_locale
    parse_args "$@"
    
    if [[ "$HELP" -eq 1 ]]; then
        print_usage
        exit 0
    fi
    
    if [[ "$VERBOSE" -eq 1 ]]; then
        set -x
    fi
    
    print_banner
    
    # 系统检测
    OS="$(detect_os)"
    echo -e "${SUCCESS}[✓]${NC} 检测到 $OS"
    
    # 依赖检查
    check_dependencies
    
    # 安装
    install_openclaw
    
    # 显示版本
    show_version
    
    # 引导
    run_onboard
    
    echo ""
    echo -e "${SUCCESS}安装完成！${NC} 🦞"
    echo -e "${MUTED}独立脚本版本: 1.0.0${NC}"
    echo ""
}

# 运行主函数
main "$@"