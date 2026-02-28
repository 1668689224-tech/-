#!/bin/bash

# ============================================
# 3X-UI 本地化安装文件准备脚本
# 帮助你下载和准备所有必要的文件
# ============================================

red='\033[0;31m'
green='\033[0;32m'
yellow='\033[0;33m'
plain='\033[0m'

function LOGI() {
    echo -e "${green}[INF] $* ${plain}"
}

function LOGE() {
    echo -e "${red}[ERR] $* ${plain}"
}

function LOGD() {
    echo -e "${yellow}[DEG] $* ${plain}"
}

# 检查 root 权限
[[ $EUID -ne 0 ]] && echo -e "${red}请使用 root 权限运行此脚本${plain}\n" && exit 1

# 工作目录
WORK_DIR="/tmp/x-ui-prepare"
mkdir -p $WORK_DIR
cd $WORK_DIR

show_menu() {
    echo -e "
——————————————————————
  ${green}3X-UI 本地化文件准备${plain}
——————————————————————
  ${green}1.${plain} 从官方 GitHub 下载 (可能失效)
  ${green}2.${plain} 从镜像源下载
  ${green}3.${plain} 手动指定下载链接
  ${green}4.${plain} 使用本地已有文件
  ${green}5.${plain} 查看当前文件状态
  ${green}6.${plain} 安装到系统
  ${green}0.${plain} 退出
——————————————————————
"
    
    read -p "请选择 [0-6]: " choice
    
    case $choice in
        1) download_from_github ;;
        2) download_from_mirror ;;
        3) download_custom ;;
        4) use_local_file ;;
        5) check_files ;;
        6) install_to_system ;;
        0) exit 0 ;;
        *) LOGE "无效选择" ;;
    esac
    
    echo ""
    read -p "按 Enter 继续..." temp
    show_menu
}

# 从 GitHub 下载 (原版方式，可能失效)
download_from_github() {
    LOGI "尝试从 GitHub 下载..."
    
    # 尝试多个可能的仓库
    repositories=(
        "https://github.com/xeefei/3x-ui"
        "https://github.com/MHSanaei/3x-ui"
        "https://github.com/alireza0/3x-ui"
    )
    
    for repo in "${repositories[@]}"; do
        LOGI "尝试仓库: $repo"
        
        # 尝试获取最新版本
        latest_version=$(curl -sL "$repo/releases/latest" | grep -o 'tag/[^"]*' | cut -d'/' -f2 | head -1)
        
        if [[ -n "$latest_version" ]]; then
            LOGI "找到版本: $latest_version"
            
            # 尝试下载不同架构的版本
            archs=("linux-amd64" "linux-arm64" "linux-arm")
            
            for arch in "${archs[@]}"; do
                download_url="$repo/releases/download/$latest_version/x-ui-${arch}.tar.gz"
                LOGI "尝试下载: $download_url"
                
                if wget --spider $download_url 2>/dev/null; then
                    wget -O x-ui.tar.gz $download_url
                    if [[ $? -eq 0 ]]; then
                        LOGI "下载成功!"
                        extract_files
                        return 0
                    fi
                fi
            done
        fi
    done
    
    LOGE "所有 GitHub 源都失败，请尝试其他方法"
    return 1
}

# 从镜像源下载
download_from_mirror() {
    LOGI "尝试从镜像源下载..."
    
    # 国内镜像源列表
    mirrors=(
        "https://ghproxy.com/https://github.com/xeefei/3x-ui/releases/latest/download/x-ui-linux-amd64.tar.gz"
        "https://github.91chi.fun/https://github.com/xeefei/3x-ui/releases/latest/download/x-ui-linux-amd64.tar.gz"
        "https://pd.zwc365.com/seturl/https://github.com/xeefei/3x-ui/releases/latest/download/x-ui-linux-amd64.tar.gz"
    )
    
    for mirror in "${mirrors[@]}"; do
        LOGI "尝试镜像: $mirror"
        
        if wget --spider $mirror 2>/dev/null; then
            wget -O x-ui.tar.gz $mirror
            if [[ $? -eq 0 ]]; then
                LOGI "镜像下载成功!"
                extract_files
                return 0
            fi
        fi
    done
    
    LOGE "所有镜像源都失败"
    return 1
}

# 自定义下载链接
download_custom() {
    echo -e "${yellow}请提供下载链接:${plain}"
    echo -e "支持的格式:"
    echo -e "1. tar.gz 压缩包"
    echo -e "2. 直接的可执行文件"
    echo ""
    
    read -p "下载链接: " url
    
    if [[ -z "$url" ]]; then
        LOGE "链接不能为空"
        return 1
    fi
    
    LOGI "正在下载: $url"
    
    # 根据链接类型处理
    if [[ "$url" == *".tar.gz" ]] || [[ "$url" == *".tgz" ]]; then
        wget -O x-ui.tar.gz "$url"
        if [[ $? -eq 0 ]]; then
            extract_files
        else
            LOGE "下载失败"
        fi
    else
        # 假设是直接的可执行文件
        wget -O x-ui "$url"
        if [[ $? -eq 0 ]]; then
            chmod +x x-ui
            LOGI "可执行文件下载完成"
        else
            LOGE "下载失败"
        fi
    fi
}

# 使用本地文件
use_local_file() {
    echo -e "${yellow}请选择本地文件:${plain}"
    
    read -p "本地文件路径 (tar.gz 或可执行文件): " local_file
    
    if [[ ! -f "$local_file" ]]; then
        LOGE "文件不存在: $local_file"
        return 1
    fi
    
    if [[ "$local_file" == *".tar.gz" ]] || [[ "$local_file" == *".tgz" ]]; then
        cp "$local_file" x-ui.tar.gz
        extract_files
    else
        cp "$local_file" x-ui
        chmod +x x-ui
        LOGI "本地文件已准备"
    fi
}

# 解压文件
extract_files() {
    if [[ ! -f "x-ui.tar.gz" ]]; then
        LOGE "压缩包不存在"
        return 1
    fi
    
    LOGI "解压文件..."
    tar -xzf x-ui.tar.gz
    
    # 查找解压出的文件
    if [[ -f "x-ui" ]]; then
        LOGI "找到可执行文件: x-ui"
        chmod +x x-ui
    elif [[ -f "x-ui-linux-amd64" ]]; then
        mv x-ui-linux-amd64 x-ui
        chmod +x x-ui
        LOGI "重命名为 x-ui"
    else
        # 尝试查找任何可执行文件
        executable=$(find . -type f -executable -name "*x-ui*" -o -name "*xui*" | head -1)
        if [[ -n "$executable" ]]; then
            cp "$executable" x-ui
            chmod +x x-ui
            LOGI "找到并复制可执行文件"
        else
            LOGE "未找到可执行文件"
            return 1
        fi
    fi
    
    # 查找配置文件示例
    if [[ -f "config.json" ]]; then
        LOGI "找到配置文件示例"
    fi
    
    LOGI "文件准备完成"
}

# 检查文件状态
check_files() {
    echo -e "${green}当前文件状态:${plain}"
    echo "工作目录: $WORK_DIR"
    echo ""
    
    if [[ -f "x-ui" ]]; then
        echo -e "✅ 可执行文件: x-ui"
        file x-ui
        ls -lh x-ui
    else
        echo -e "❌ 可执行文件: 未找到"
    fi
    
    if [[ -f "x-ui.tar.gz" ]]; then
        echo -e "📦 压缩包: x-ui.tar.gz"
        ls -lh x-ui.tar.gz
    fi
    
    if [[ -f "config.json" ]]; then
        echo -e "📄 配置文件: config.json"
    fi
    
    echo ""
}

# 安装到系统
install_to_system() {
    if [[ ! -f "x-ui" ]]; then
        LOGE "请先准备 x-ui 可执行文件"
        return 1
    fi
    
    LOGI "安装到系统..."
    
    # 创建目录
    mkdir -p /usr/local/x-ui /etc/x-ui
    
    # 复制可执行文件
    cp x-ui /usr/local/x-ui/
    chmod +x /usr/local/x-ui/x-ui
    
    # 复制配置文件示例
    if [[ -f "config.json" ]]; then
        if [[ ! -f "/etc/x-ui/config.json" ]]; then
            cp config.json /etc/x-ui/config.json
            LOGI "配置文件已复制"
        else
            LOGI "配置文件已存在，保留原文件"
        fi
    fi
    
    # 创建 systemd 服务
    cat > /etc/systemd/system/x-ui.service << EOF
[Unit]
Description=3X-UI Panel Service
After=network.target

[Service]
Type=simple
User=root
WorkingDirectory=/usr/local/x-ui
ExecStart=/usr/local/x-ui/x-ui
Restart=on-failure
RestartSec=5s
LimitNOFILE=51200

[Install]
WantedBy=multi-user.target
EOF
    
    systemctl daemon-reload
    
    LOGI "安装完成!"
    echo ""
    echo -e "${green}下一步:${plain}"
    echo -e "1. 编辑配置文件: ${yellow}nano /etc/x-ui/config.json${plain}"
    echo -e "2. 启动服务: ${yellow}systemctl start x-ui${plain}"
    echo -e "3. 设置开机自启: ${yellow}systemctl enable x-ui${plain}"
    echo -e "4. 查看状态: ${yellow}systemctl status x-ui${plain}"
    echo ""
    echo -e "使用本地化管理脚本:"
    echo -e "${yellow}bash /root/.openclaw/workspace/x-ui-local.sh${plain}"
}

# 显示使用说明
show_help() {
    echo -e "${green}3X-UI 本地化部署指南${plain}"
    echo ""
    echo -e "${yellow}第一步: 准备安装文件${plain}"
    echo -e "运行此脚本，选择下载方式获取 x-ui 二进制文件"
    echo ""
    echo -e "${yellow}第二步: 安装到系统${plain}"
    echo -e "选择选项 6 安装到系统"
    echo ""
    echo -e "${yellow}第三步: 使用本地化管理${plain}"
    echo -e "使用本地化脚本管理面板:"
    echo -e "  bash x-ui-local.sh menu"
    echo ""
    echo -e "${yellow}重要提示:${plain}"
    echo -e "1. 建议从可靠来源下载 x-ui 二进制文件"
    echo -e "2. 备份好配置文件"
    echo -e "3. 定期手动检查更新"
}

# 主程序
if [[ "$1" == "help" ]]; then
    show_help
elif [[ "$1" == "install" ]]; then
    install_to_system
else
    show_menu
fi