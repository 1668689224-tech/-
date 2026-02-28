#!/bin/bash

red='\033[0;31m'
green='\033[0;32m'
yellow='\033[0;33m'
plain='\033[0m'

# ============================================
# 本地化版本 - 不依赖外部作者资源
# 创建时间: $(date)
# ============================================

# 配置变量 - 在这里设置你的自定义值
CONFIG_DIR="/etc/x-ui-local"
BACKUP_DIR="/var/backup/x-ui"
LOG_DIR="/var/log/x-ui-local"
PANEL_VERSION="1.0.0"  # 你的自定义版本号

# 创建必要的目录
mkdir -p $CONFIG_DIR $BACKUP_DIR $LOG_DIR

function LOGD() {
    echo -e "${yellow}[DEG] $* ${plain}"
}

function LOGE() {
    echo -e "${red}[ERR] $* ${plain}"
}

function LOGI() {
    echo -e "${green}[INF] $* ${plain}"
}

# 检查 root 权限
[[ $EUID -ne 0 ]] && echo -e "${red}致命错误: ${plain} 请使用 root 权限运行此脚本\n" && exit 1

# 检查操作系统
check_os() {
    if [[ -f /etc/os-release ]]; then
        source /etc/os-release
        release=$ID
    elif [[ -f /usr/lib/os-release ]]; then
        source /usr/lib/os-release
        release=$ID
    else
        echo -e "${red}检查服务器操作系统失败${plain}" >&2
        exit 1
    fi
    
    os_version=$(grep -i version_id /etc/os-release | cut -d \" -f2 | cut -d . -f1)
    
    echo -e "——————————————————————"
    echo -e "当前服务器的操作系统为:${red} $release ${plain}"
    echo -e "系统版本:${red} $os_version ${plain}"
    echo -e "面板版本:${green} 本地化版 v$PANEL_VERSION ${plain}"
    echo ""
}

# 备份当前配置
backup_config() {
    local timestamp=$(date +%Y%m%d_%H%M%S)
    local backup_file="$BACKUP_DIR/x-ui-backup-$timestamp.tar.gz"
    
    if [[ -d "/etc/x-ui" ]]; then
        tar -czf $backup_file /etc/x-ui /usr/local/x-ui 2>/dev/null
        LOGI "配置已备份到: $backup_file"
    fi
}

# 恢复配置
restore_config() {
    echo "可用的备份文件:"
    ls -lh $BACKUP_DIR/*.tar.gz 2>/dev/null || echo "暂无备份"
    
    read -p "输入要恢复的备份文件名 (或按回车取消): " backup_file
    [[ -z "$backup_file" ]] && return
    
    if [[ -f "$BACKUP_DIR/$backup_file" ]]; then
        tar -xzf "$BACKUP_DIR/$backup_file" -C /
        LOGI "配置已从 $backup_file 恢复"
        restart_panel
    else
        LOGE "备份文件不存在"
    fi
}

# 安装面板 (本地化版本)
install_panel() {
    LOGI "开始安装本地化 3X-UI 面板..."
    
    # 检查是否已安装
    if systemctl is-active --quiet x-ui; then
        LOGE "面板已安装且正在运行"
        return 1
    fi
    
    # 创建安装目录
    mkdir -p /usr/local/x-ui /etc/x-ui
    
    # 这里应该是你的本地安装逻辑
    # 由于原脚本依赖外部资源，你需要：
    # 1. 手动下载 x-ui 二进制文件到本地
    # 2. 或者使用其他安装方式
    
    echo ""
    echo -e "${yellow}⚠️  注意: ${plain}"
    echo -e "本地化版本需要你手动准备安装文件。"
    echo -e "请执行以下步骤:"
    echo -e "1. 从可靠来源下载 x-ui 二进制文件"
    echo -e "2. 将文件放在 /usr/local/x-ui/ 目录"
    echo -e "3. 创建配置文件 /etc/x-ui/config.json"
    echo ""
    echo -e "或者使用备用安装方法:"
    echo -e "${green}curl -L -o x-ui-linux-amd64.tar.gz <你的下载链接>${plain}"
    echo -e "${green}tar -xzf x-ui-linux-amd64.tar.gz -C /usr/local/x-ui/${plain}"
    
    read -p "是否继续? (y/n): " choice
    [[ "$choice" != "y" ]] && return
    
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

[Install]
WantedBy=multi-user.target
EOF
    
    systemctl daemon-reload
    LOGI "服务文件已创建"
    
    # 设置默认配置
    if [[ ! -f "/etc/x-ui/config.json" ]]; then
        cat > /etc/x-ui/config.json << EOF
{
  "panelSettings": {
    "webPort": 2053,
    "webCertFile": "",
    "webKeyFile": "",
    "webBasePath": "",
    "secret": "",
    "webHost": "0.0.0.0",
    "sessionMaxAge": 7200
  },
  "xraySettings": {
    "logLevel": "warning"
  }
}
EOF
        LOGI "默认配置文件已创建"
    fi
    
    LOGI "安装完成，请手动放置 x-ui 二进制文件到 /usr/local/x-ui/"
}

# 面板管理函数
start_panel() {
    systemctl start x-ui
    sleep 2
    if systemctl is-active --quiet x-ui; then
        LOGI "面板启动成功"
    else
        LOGE "面板启动失败"
    fi
}

stop_panel() {
    systemctl stop x-ui
    sleep 2
    if ! systemctl is-active --quiet x-ui; then
        LOGI "面板已停止"
    else
        LOGE "面板停止失败"
    fi
}

restart_panel() {
    systemctl restart x-ui
    sleep 2
    if systemctl is-active --quiet x-ui; then
        LOGI "面板重启成功"
    else
        LOGE "面板重启失败"
    fi
}

check_status() {
    systemctl status x-ui --no-pager -l
}

enable_autostart() {
    systemctl enable x-ui
    LOGI "已启用开机自启"
}

disable_autostart() {
    systemctl disable x-ui
    LOGI "已禁用开机自启"
}

show_log() {
    journalctl -u x-ui.service -e --no-pager -f
}

# 配置管理
reset_credentials() {
    backup_config
    
    read -rp "设置用户名 [默认: admin]: " username
    username=${username:-admin}
    
    read -rp "设置密码 [默认: 随机生成]: " password
    if [[ -z "$password" ]]; then
        password=$(date +%s%N | md5sum | cut -c 1-12)
    fi
    
    # 这里应该是调用 x-ui 命令重置凭据
    # /usr/local/x-ui/x-ui setting -username $username -password $password
    
    echo -e "用户名: ${green}$username${plain}"
    echo -e "密码: ${green}$password${plain}"
    echo -e "${yellow}请手动更新配置文件 /etc/x-ui/config.json${plain}"
    
    read -p "是否重启面板应用更改? (y/n): " choice
    [[ "$choice" == "y" ]] && restart_panel
}

change_port() {
    read -rp "输入新端口号 [1-65535]: " port
    if [[ -z "$port" ]]; then
        LOGE "取消操作"
        return
    fi
    
    if [[ "$port" -lt 1 || "$port" -gt 65535 ]]; then
        LOGE "端口号无效"
        return
    fi
    
    # 更新配置文件
    if [[ -f "/etc/x-ui/config.json" ]]; then
        sed -i "s/\"webPort\": [0-9]*/\"webPort\": $port/" /etc/x-ui/config.json
        LOGI "端口已修改为 $port"
        restart_panel
    else
        LOGE "配置文件不存在"
    fi
}

# 防火墙管理 (本地化)
firewall_setup() {
    echo -e "${green}防火墙管理${plain}"
    echo -e "1. 开放面板端口"
    echo -e "2. 查看防火墙状态"
    echo -e "3. 禁用防火墙"
    echo -e "0. 返回"
    
    read -p "选择: " choice
    
    case $choice in
        1)
            read -p "输入要开放的端口 (默认 2053): " port
            port=${port:-2053}
            
            if command -v ufw &>/dev/null; then
                ufw allow $port/tcp
                ufw reload
                LOGI "UFW: 端口 $port 已开放"
            elif command -v firewall-cmd &>/dev/null; then
                firewall-cmd --permanent --add-port=$port/tcp
                firewall-cmd --reload
                LOGI "FirewallD: 端口 $port 已开放"
            else
                LOGE "未找到支持的防火墙工具"
            fi
            ;;
        2)
            if command -v ufw &>/dev/null; then
                ufw status
            elif command -v firewall-cmd &>/dev/null; then
                firewall-cmd --list-all
            else
                echo "未安装防火墙"
            fi
            ;;
        3)
            if command -v ufw &>/dev/null; then
                ufw disable
            elif command -v firewall-cmd &>/dev/null; then
                systemctl stop firewalld
                systemctl disable firewalld
            fi
            LOGI "防火墙已禁用"
            ;;
    esac
}

# BBR 加速 (本地化)
enable_bbr() {
    echo "net.core.default_qdisc=fq" >> /etc/sysctl.conf
    echo "net.ipv4.tcp_congestion_control=bbr" >> /etc/sysctl.conf
    sysctl -p
    
    if sysctl net.ipv4.tcp_congestion_control | grep -q bbr; then
        LOGI "BBR 已启用"
    else
        LOGE "BBR 启用失败"
    fi
}

# 导出配置
export_config() {
    local timestamp=$(date +%Y%m%d_%H%M%S)
    local export_file="$BACKUP_DIR/x-ui-export-$timestamp.json"
    
    if [[ -f "/etc/x-ui/config.json" ]]; then
        cp /etc/x-ui/config.json $export_file
        LOGI "配置已导出到: $export_file"
        echo -e "${yellow}重要: 此文件包含敏感信息，请妥善保管${plain}"
    else
        LOGE "配置文件不存在"
    fi
}

# 导入配置
import_config() {
    echo "可用的配置文件:"
    ls -lh $BACKUP_DIR/*.json 2>/dev/null || echo "暂无配置文件"
    
    read -p "输入要导入的配置文件名 (或按回车取消): " config_file
    [[ -z "$config_file" ]] && return
    
    if [[ -f "$BACKUP_DIR/$config_file" ]]; then
        cp "$BACKUP_DIR/$config_file" /etc/x-ui/config.json
        LOGI "配置已从 $config_file 导入"
        restart_panel
    else
        LOGE "配置文件不存在"
    fi
}

# 显示菜单
show_menu() {
    check_os
    
    echo -e "
——————————————————————
  ${green}本地化 3X-UI 面板管理${plain}
  ${yellow}版本: v$PANEL_VERSION${plain}
  ${yellow}不依赖外部作者资源${plain}
——————————————————————
  ${green}1.${plain} 安装面板 (需手动准备文件)
  ${green}2.${plain} 启动面板
  ${green}3.${plain} 停止面板
  ${green}4.${plain} 重启面板
  ${green}5.${plain} 查看状态
  ${green}6.${plain} 查看日志
——————————————————————
  ${green}7.${plain} 重置用户名密码
  ${green}8.${plain} 修改面板端口
  ${green}9.${plain} 导出配置
  ${green}10.${plain} 导入配置
  ${green}11.${plain} 备份配置
  ${green}12.${plain} 恢复备份
——————————————————————
  ${green}13.${plain} 启用开机自启
  ${green}14.${plain} 禁用开机自启
  ${green}15.${plain} 防火墙管理
  ${green}16.${plain} 启用 BBR 加速
——————————————————————
  ${green}0.${plain} 退出
——————————————————————
"
    
    read -p "请选择操作 [0-16]: " choice
    
    case $choice in
        1) install_panel ;;
        2) start_panel ;;
        3) stop_panel ;;
        4) restart_panel ;;
        5) check_status ;;
        6) show_log ;;
        7) reset_credentials ;;
        8) change_port ;;
        9) export_config ;;
        10) import_config ;;
        11) backup_config ;;
        12) restore_config ;;
        13) enable_autostart ;;
        14) disable_autostart ;;
        15) firewall_setup ;;
        16) enable_bbr ;;
        0) exit 0 ;;
        *) LOGE "无效选择" ;;
    esac
    
    echo ""
    read -p "按 Enter 返回菜单..." temp
    show_menu
}

# 命令行参数处理
if [[ $# -gt 0 ]]; then
    case $1 in
        "start") start_panel ;;
        "stop") stop_panel ;;
        "restart") restart_panel ;;
        "status") check_status ;;
        "log") show_log ;;
        "backup") backup_config ;;
        "menu") show_menu ;;
        *) 
            echo "用法: $0 [command]"
            echo "命令:"
            echo "  start     - 启动面板"
            echo "  stop      - 停止面板"
            echo "  restart   - 重启面板"
            echo "  status    - 查看状态"
            echo "  log       - 查看日志"
            echo "  backup    - 备份配置"
            echo "  menu      - 显示菜单"
            ;;
    esac
else
    show_menu
fi