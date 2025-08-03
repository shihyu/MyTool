#!/bin/bash
# Claude Code 智能包裝器 - cc_smart.sh
# 結合 alias、自動重試、使用量監控與錯誤處理

# 設置腳本變數
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LOG_FILE="$HOME/.claude/cc_usage.log"
CONFIG_FILE="$HOME/.claude/cc_config.json"
RETRY_COUNT=0
MAX_RETRIES=3

# 創建必要目錄
mkdir -p "$HOME/.claude"

# 初始化配置文件
init_config() {
    if [[ ! -f "$CONFIG_FILE" ]]; then
        cat > "$CONFIG_FILE" << 'EOF'
{
    "max_retries": 3,
    "wait_hours": 5,
    "enable_monitoring": true,
    "enable_cost_tracking": true,
    "notification_enabled": true,
    "show_process": true
}
EOF
    fi
}

# 讀取配置
read_config() {
    if command -v jq >/dev/null 2>&1; then
        MAX_RETRIES=$(jq -r '.max_retries // 3' "$CONFIG_FILE")
        WAIT_HOURS=$(jq -r '.wait_hours // 5' "$CONFIG_FILE")
        ENABLE_MONITORING=$(jq -r '.enable_monitoring // true' "$CONFIG_FILE")
        ENABLE_COST=$(jq -r '.enable_cost_tracking // true' "$CONFIG_FILE")
        NOTIFICATION=$(jq -r '.notification_enabled // true' "$CONFIG_FILE")
        SHOW_PROCESS=$(jq -r '.show_process // true' "$CONFIG_FILE")
    else
        # 默認值（如果沒有 jq）
        MAX_RETRIES=3
        WAIT_HOURS=5
        ENABLE_MONITORING=true
        ENABLE_COST=true
        NOTIFICATION=true
        SHOW_PROCESS=true
    fi
}

# 日誌記錄函數
log_event() {
    local level="$1"
    local message="$2"
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    echo "[$timestamp] [$level] $message" >> "$LOG_FILE"
    
    # 根據配置決定是否顯示處理過程
    if [[ "$SHOW_PROCESS" == "true" && "$level" != "DEBUG" ]]; then
        case "$level" in
            "INFO")    echo "ℹ️  $message" ;;
            "SUCCESS") echo "✅ $message" ;;
            "WARN")    echo "⚠️  $message" ;;
            "ERROR")   echo "❌ $message" ;;
            *)         echo "🤖 $message" ;;
        esac
    fi
}

# 檢查使用量（如果啟用監控）
check_usage() {
    if [[ "$ENABLE_MONITORING" == "true" ]]; then
        if command -v ccusage >/dev/null 2>&1; then
            log_event "INFO" "檢查當前使用量..."
            ccusage daily --quiet || true
        else
            log_event "DEBUG" "ccusage 未安裝，建議安裝以監控使用量: npm install -g ccusage"
        fi
    fi
}

# 發送通知
send_notification() {
    local title="$1"
    local message="$2"
    
    if [[ "$NOTIFICATION" == "true" ]]; then
        # macOS 通知
        if command -v osascript >/dev/null 2>&1; then
            osascript -e "display notification \"$message\" with title \"$title\""
        # Linux 通知
        elif command -v notify-send >/dev/null 2>&1; then
            notify-send "$title" "$message"
        # 終端鈴聲作為備選
        else
            echo -e "\a"
        fi
    fi
}

# 倒計時等待函數
countdown_wait() {
    local wait_seconds=$((WAIT_HOURS * 3600))
    local remaining=$wait_seconds
    
    log_event "WARN" "觸發速率限制，等待 $WAIT_HOURS 小時重置..."
    send_notification "Claude Code" "速率限制觸發，等待 $WAIT_HOURS 小時"
    
    while [[ $remaining -gt 0 ]]; do
        local hours=$((remaining / 3600))
        local minutes=$(((remaining % 3600) / 60))
        local seconds=$((remaining % 60))
        
        printf "\r⏳ 等待重置: %02d:%02d:%02d (剩餘 %.1f 小時)" \
               $hours $minutes $seconds $(echo "scale=1; $remaining/3600" | bc -l 2>/dev/null || echo $((remaining/3600)))
        
        sleep 1
        ((remaining--))
    done
    
    echo ""
    log_event "INFO" "等待完成，速率限制已重置"
    send_notification "Claude Code" "速率限制已重置，可以繼續使用"
}

# 檢查錯誤類型
is_rate_limit_error() {
    local error_msg="$1"
    local error_lower=$(echo "$error_msg" | tr '[:upper:]' '[:lower:]')
    
    # Claude Code 實際的速率限制錯誤訊息模式
    if [[ "$error_lower" =~ (rate.limit|usage.limit|quota.*exceeded|too.many.requests|limit.*reached) ]] || \
       [[ "$error_msg" =~ "rate_limit_error" ]] || \
       [[ "$error_msg" =~ "This request would exceed your account's rate limit" ]] || \
       [[ "$error_msg" =~ "usage limit reached" ]] || \
       [[ "$error_msg" =~ "limit will reset at" ]] || \
       [[ "$error_msg" =~ "429" ]] || \
       [[ "$error_lower" =~ "rate limit exceeded" ]] || \
       [[ "$error_lower" =~ "sorry, you have reached the rate limit" ]] || \
       [[ "$error_lower" =~ "rate.limited" ]]; then
        return 0
    fi
    return 1
}

# 解析重置時間（如果錯誤訊息包含）
parse_reset_time() {
    local error_msg="$1"
    if [[ "$error_msg" =~ until\.([0-9]{4}-[0-9]{2}-[0-9]{2}\ [0-9]{2}:[0-9]{2}:[0-9]{2}) ]]; then
        echo "${BASH_REMATCH[1]}"
    fi
}

# 主要執行函數
execute_claude() {
    local cmd_args=("$@")
    local temp_error=$(mktemp)
    local exit_code=0

    trap 'rm -f "$temp_error"' EXIT

    # 顯示開始處理
    if [[ "$SHOW_PROCESS" == "true" ]]; then
        echo "🚀 啟動 Claude Code..."
        echo "📝 問題: ${cmd_args[*]}"
        echo "────────────────────────────────────"
    fi

    while [[ $RETRY_COUNT -le $MAX_RETRIES ]]; do
        log_event "INFO" "執行 Claude Code (嘗試 $((RETRY_COUNT + 1))/$((MAX_RETRIES + 1)))"
        
        check_usage
        
        # 顯示正在處理
        if [[ "$SHOW_PROCESS" == "true" ]]; then
            echo "🤖 Claude 正在思考中..."
            echo "💬 Claude 回應:"
            echo "────────────────────────────────────"
        fi
        
        # 即時顯示 Claude 輸出，同時捕獲錯誤
        claude --dangerously-skip-permissions "${cmd_args[@]}" 2> "$temp_error"
        exit_code=$?
        
        local error_msg=$(cat "$temp_error")
        
        if [[ $exit_code -eq 0 ]]; then
            if [[ "$SHOW_PROCESS" == "true" ]]; then
                echo ""
                echo "────────────────────────────────────"
            fi
            log_event "SUCCESS" "Claude Code 執行成功"
            if [[ "$ENABLE_COST" == "true" && "$SHOW_PROCESS" == "true" ]]; then
                echo "💰 使用 'cc -u' 查看詳細使用量"
            fi
            break
        fi
        
        if is_rate_limit_error "$error_msg"; then
            if [[ $RETRY_COUNT -lt $MAX_RETRIES ]]; then
                log_event "WARN" "檢測到速率限制: $error_msg"
                local reset_time=$(parse_reset_time "$error_msg")
                [[ -n "$reset_time" ]] && log_event "INFO" "解析到重置時間: $reset_time"
                countdown_wait
                ((RETRY_COUNT++))
                continue
            else
                log_event "ERROR" "達到最大重試次數，放棄執行"
                echo "❌ 錯誤: $error_msg" >&2
                exit 1
            fi
        else
            log_event "ERROR" "Claude Code 執行失敗: $error_msg"
            echo "❌ 錯誤: $error_msg" >&2
            exit $exit_code
        fi
    done

    return $exit_code
}

# 顯示幫助信息
show_help() {
    cat << 'EOF'
Claude Code 智能包裝器 - cc

用法:
  cc "你的問題"                    # 執行 Claude Code 並顯示處理過程
  cc --file script.py "解釋程式"   # 分析檔案
  cc -h                           # 顯示此幫助
  cc -c                           # 顯示當前配置
  cc -u                           # 顯示使用統計
  cc -r                           # 重置配置文件
  cc -q "問題"                     # 安靜模式（不顯示處理過程）

功能:
  ✅ 自動重試機制（速率限制時等待重置）
  ✅ 使用量監控（需安裝 ccusage）
  ✅ 錯誤類型識別
  ✅ 倒計時顯示
  ✅ 系統通知
  ✅ 詳細日誌記錄
  ✅ 可配置參數
  ✅ 處理過程顯示

配置文件位置: ~/.claude/cc_config.json
日誌文件位置: ~/.claude/cc_usage.log

推薦安裝:
  npm install -g ccusage              # 使用量監控工具
  sudo apt install jq                # JSON 解析工具 (Linux)
  brew install jq                     # JSON 解析工具 (macOS)
EOF
}

# 顯示配置
show_config() {
    echo "📋 當前配置 ($CONFIG_FILE):"
    if command -v jq >/dev/null 2>&1; then
        jq . "$CONFIG_FILE"
    else
        cat "$CONFIG_FILE"
    fi
}

# 顯示使用統計
show_usage() {
    echo "📊 使用統計:"
    if [[ -f "$LOG_FILE" ]]; then
        echo "總執行次數: $(grep -c "執行 Claude Code" "$LOG_FILE" 2>/dev/null || echo "0")"
        echo "成功次數: $(grep -c "SUCCESS" "$LOG_FILE" 2>/dev/null || echo "0")"
        echo "速率限制次數: $(grep -c "速率限制" "$LOG_FILE" 2>/dev/null || echo "0")"
        echo ""
        echo "最近 5 次活動:"
        tail -5 "$LOG_FILE" 2>/dev/null || echo "無日誌記錄"
    else
        echo "暫無使用記錄"
    fi
}

# 主程序
main() {
    init_config
    read_config

    case "${1:-}" in
        -q|--quiet)
            # 安靜模式
            SHOW_PROCESS=false
            shift
            if [[ $# -eq 0 ]]; then
                echo "❌ 安靜模式需要提供問題"
                echo "💡 用法: cc -q '你的問題'"
                exit 1
            fi
            execute_claude "$@"; exit 0 ;;
        -h|--help)
            show_help; exit 0 ;;
        -c|--config)
            show_config; exit 0 ;;
        -u|--usage)
            show_usage; exit 0 ;;
        -r|--reset)
            rm -f "$CONFIG_FILE"; init_config
            echo "✅ 配置文件已重置"; exit 0 ;;
        "")
            echo "💡 使用 'cc -h' 查看幫助"
            echo "💡 使用 'cc \"你的問題\"' 開始提問"
            exit 0 ;;
        *)
            # 執行 Claude Code
            execute_claude "$@"; exit 0 ;;
    esac
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi
