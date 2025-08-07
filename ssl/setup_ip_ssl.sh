#!/bin/bash

# Ubuntu IP SSL 自動安裝腳本
# 用途：為 Ubuntu 伺服器的 IP 地址自動生成和配置免費 SSL 憑證
# 作者：自動化腳本
# 版本：1.0

set -e  # 遇到錯誤立即退出

# 顏色定義
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# 函數：印出彩色訊息
print_status() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

print_step() {
    echo -e "${BLUE}[STEP]${NC} $1"
}

# 檢查是否為 root 用戶
check_root() {
    if [ "$EUID" -ne 0 ]; then
        print_error "請使用 sudo 執行此腳本"
        echo "範例：sudo bash setup_ip_ssl.sh"
        exit 1
    fi
}

# 獲取伺服器 IP
get_server_ip() {
    print_step "偵測伺服器 IP 地址..."
    
    # 嘗試多種方法獲取 IP
    SERVER_IP=$(hostname -I | awk '{print $1}' 2>/dev/null)
    
    if [ -z "$SERVER_IP" ]; then
        SERVER_IP=$(ip route get 8.8.8.8 | grep -oP 'src \K\S+' 2>/dev/null)
    fi
    
    if [ -z "$SERVER_IP" ]; then
        SERVER_IP=$(curl -s ifconfig.me 2>/dev/null || curl -s icanhazip.com 2>/dev/null)
    fi
    
    if [ -z "$SERVER_IP" ]; then
        print_warning "無法自動偵測 IP 地址"
        read -p "請手動輸入您的伺服器 IP 地址: " SERVER_IP
    else
        print_status "偵測到的伺服器 IP: $SERVER_IP"
        read -p "這是正確的 IP 地址嗎？ (y/n) [y]: " -r confirm
        confirm=${confirm:-y}
        
        if [[ ! $confirm =~ ^[Yy]$ ]]; then
            read -p "請輸入正確的 IP 地址: " SERVER_IP
        fi
    fi
    
    # 驗證 IP 格式
    if [[ ! $SERVER_IP =~ ^[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}$ ]]; then
        print_error "無效的 IP 地址格式: $SERVER_IP"
        exit 1
    fi
    
    print_status "將為 IP 地址 $SERVER_IP 設置 SSL 憑證"
}

# 安裝必要套件
install_packages() {
    print_step "更新系統並安裝必要套件..."
    
    # 更新套件清單
    apt update -y
    
    # 安裝必要套件
    apt install -y openssl nginx curl ufw
    
    print_status "套件安裝完成"
    
    # 檢查安裝結果
    if ! command -v openssl &> /dev/null; then
        print_error "OpenSSL 安裝失敗"
        exit 1
    fi
    
    if ! command -v nginx &> /dev/null; then
        print_error "Nginx 安裝失敗"
        exit 1
    fi
    
    print_status "OpenSSL 版本: $(openssl version)"
    print_status "Nginx 版本: $(nginx -v 2>&1)"
}

# 生成 SSL 憑證
generate_ssl_certificate() {
    print_step "生成 SSL 憑證..."
    
    # 建立憑證目錄
    mkdir -p /etc/ssl/private /etc/ssl/certs
    
    # 生成私鑰
    print_status "生成私鑰..."
    openssl genrsa -out /etc/ssl/private/server.key 4096
    
    # 生成自簽憑證
    print_status "生成 SSL 憑證（有效期 365 天）..."
    openssl req -new -x509 -key /etc/ssl/private/server.key \
        -out /etc/ssl/certs/server.crt -days 365 \
        -subj "/C=TW/ST=Taipei/L=Taipei/O=MyServer/OU=IT/CN=$SERVER_IP" \
        -addext "subjectAltName=IP:$SERVER_IP,IP:127.0.0.1,IP:::1"
    
    # 設定檔案權限
    chmod 600 /etc/ssl/private/server.key
    chmod 644 /etc/ssl/certs/server.crt
    chown root:root /etc/ssl/private/server.key /etc/ssl/certs/server.crt
    
    print_status "SSL 憑證生成完成"
    
    # 驗證憑證
    if openssl x509 -in /etc/ssl/certs/server.crt -noout -text | grep -q "$SERVER_IP"; then
        print_status "憑證驗證成功，包含正確的 IP 地址"
    else
        print_error "憑證驗證失敗"
        exit 1
    fi
}

# 配置 Nginx
configure_nginx() {
    print_step "配置 Nginx..."
    
    # 備份原始設定
    if [ -f /etc/nginx/sites-available/default ]; then
        cp /etc/nginx/sites-available/default /etc/nginx/sites-available/default.backup.$(date +%Y%m%d_%H%M%S)
        print_status "已備份原始 Nginx 設定"
    fi
    
    # 建立新的 Nginx 設定
    cat > /etc/nginx/sites-available/default << EOF
# HTTP 伺服器 - 重導向到 HTTPS
server {
    listen 80 default_server;
    listen [::]:80 default_server;
    
    server_name $SERVER_IP _;
    
    # 重導向所有 HTTP 請求到 HTTPS
    return 301 https://\$server_name\$request_uri;
}

# HTTPS 伺服器
server {
    listen 443 ssl http2 default_server;
    listen [::]:443 ssl http2 default_server;
    
    server_name $SERVER_IP _;
    
    # SSL 憑證設定
    ssl_certificate /etc/ssl/certs/server.crt;
    ssl_certificate_key /etc/ssl/private/server.key;
    
    # 現代 SSL 安全設定
    ssl_protocols TLSv1.2 TLSv1.3;
    ssl_ciphers ECDHE-RSA-AES256-GCM-SHA512:DHE-RSA-AES256-GCM-SHA512:ECDHE-RSA-AES256-GCM-SHA384:DHE-RSA-AES256-GCM-SHA384;
    ssl_prefer_server_ciphers off;
    ssl_session_cache shared:SSL:10m;
    ssl_session_timeout 10m;
    
    # 安全標頭
    add_header Strict-Transport-Security "max-age=31536000; includeSubDomains" always;
    add_header X-Content-Type-Options nosniff;
    add_header X-Frame-Options DENY;
    add_header X-XSS-Protection "1; mode=block";
    
    # 網站根目錄
    root /var/www/html;
    index index.html index.htm index.nginx-debian.html;
    
    # 主要位置設定
    location / {
        try_files \$uri \$uri/ =404;
    }
    
    # 隱藏 Nginx 版本
    server_tokens off;
    
    # 錯誤頁面
    error_page 404 /404.html;
    error_page 500 502 503 504 /50x.html;
}
EOF
    
    print_status "Nginx 設定完成"
}

# 建立測試頁面
create_test_page() {
    print_step "建立測試頁面..."
    
    # 建立主頁
    cat > /var/www/html/index.html << EOF
<!DOCTYPE html>
<html lang="zh-TW">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>SSL 測試頁面 - $SERVER_IP</title>
    <style>
        * { margin: 0; padding: 0; box-sizing: border-box; }
        body {
            font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif;
            background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
            min-height: 100vh;
            display: flex;
            align-items: center;
            justify-content: center;
            color: white;
        }
        .container {
            text-align: center;
            background: rgba(255, 255, 255, 0.1);
            padding: 3rem;
            border-radius: 15px;
            backdrop-filter: blur(10px);
            border: 1px solid rgba(255, 255, 255, 0.2);
            box-shadow: 0 8px 32px rgba(0, 0, 0, 0.1);
        }
        .success {
            color: #4CAF50;
            font-size: 3rem;
            margin-bottom: 1rem;
        }
        .title {
            font-size: 2.5rem;
            margin-bottom: 1rem;
            font-weight: 300;
        }
        .info {
            font-size: 1.2rem;
            margin: 1rem 0;
            opacity: 0.9;
        }
        .ip-address {
            background: rgba(255, 255, 255, 0.2);
            padding: 1rem 2rem;
            border-radius: 25px;
            font-family: 'Courier New', monospace;
            font-size: 1.5rem;
            margin: 2rem 0;
            border: 2px solid rgba(255, 255, 255, 0.3);
        }
        .warning {
            background: rgba(255, 193, 7, 0.2);
            color: #FFF9C4;
            padding: 1rem;
            border-radius: 10px;
            margin-top: 2rem;
            border-left: 4px solid #FFC107;
        }
        .details {
            margin-top: 2rem;
            opacity: 0.8;
            font-size: 0.9rem;
        }
        .status-grid {
            display: grid;
            grid-template-columns: repeat(auto-fit, minmax(200px, 1fr));
            gap: 1rem;
            margin: 2rem 0;
        }
        .status-item {
            background: rgba(255, 255, 255, 0.1);
            padding: 1rem;
            border-radius: 10px;
            border: 1px solid rgba(255, 255, 255, 0.2);
        }
        .status-label {
            font-size: 0.8rem;
            opacity: 0.7;
            text-transform: uppercase;
            letter-spacing: 1px;
        }
        .status-value {
            font-size: 1.2rem;
            font-weight: 600;
            margin-top: 0.5rem;
        }
    </style>
</head>
<body>
    <div class="container">
        <div class="success">🔒</div>
        <h1 class="title">SSL 連接成功！</h1>
        <div class="ip-address">$SERVER_IP</div>
        <p class="info">您的自簽 SSL 憑證已正常運作</p>
        
        <div class="status-grid">
            <div class="status-item">
                <div class="status-label">協議</div>
                <div class="status-value">HTTPS</div>
            </div>
            <div class="status-item">
                <div class="status-label">加密</div>
                <div class="status-value">TLS 1.2/1.3</div>
            </div>
            <div class="status-item">
                <div class="status-label">憑證類型</div>
                <div class="status-value">自簽憑證</div>
            </div>
            <div class="status-item">
                <div class="status-label">有效期</div>
                <div class="status-value">365 天</div>
            </div>
        </div>
        
        <div class="warning">
            <strong>⚠️ 注意：</strong><br>
            這是自簽憑證，瀏覽器會顯示安全警告。<br>
            點擊「進階」→「繼續前往」即可正常訪問。
        </div>
        
        <div class="details">
            <p>設定時間：$(date '+%Y-%m-%d %H:%M:%S %Z')</p>
            <p>伺服器：Ubuntu + Nginx</p>
            <p>SSL 提供者：OpenSSL (自簽憑證)</p>
        </div>
    </div>

    <script>
        // 顯示連接資訊
        if (location.protocol === 'https:') {
            console.log('✅ HTTPS 連接成功');
            console.log('🔒 SSL 憑證已載入');
            console.log('📍 伺服器 IP:', '$SERVER_IP');
        }
        
        // 檢查 SSL 憑證到期時間（如果瀏覽器支援）
        if ('serviceWorker' in navigator) {
            console.log('🌐 支援現代瀏覽器功能');
        }
    </script>
</body>
</html>
EOF
    
    # 建立 404 錯誤頁面
    cat > /var/www/html/404.html << EOF
<!DOCTYPE html>
<html lang="zh-TW">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>404 - 頁面未找到</title>
    <style>
        body { font-family: Arial, sans-serif; text-align: center; margin-top: 100px; color: #666; }
        h1 { color: #e74c3c; }
        a { color: #3498db; text-decoration: none; }
        a:hover { text-decoration: underline; }
    </style>
</head>
<body>
    <h1>404 - 頁面未找到</h1>
    <p>抱歉，您要找的頁面不存在。</p>
    <p><a href="/">返回首頁</a></p>
</body>
</html>
EOF
    
    # 設定檔案權限
    chown -R www-data:www-data /var/www/html
    chmod -R 644 /var/www/html/*
    
    print_status "測試頁面建立完成"
}

# 配置防火牆
configure_firewall() {
    print_step "配置防火牆..."
    
    # 檢查 UFW 狀態
    if ufw status | grep -q "Status: active"; then
        print_status "防火牆已啟用，新增規則..."
    else
        print_status "啟用防火牆..."
        ufw --force enable
    fi
    
    # 開放必要端口
    ufw allow 22/tcp comment 'SSH'
    ufw allow 80/tcp comment 'HTTP'
    ufw allow 443/tcp comment 'HTTPS'
    
    print_status "防火牆規則配置完成"
    ufw status numbered
}

# 啟動和測試 Nginx
start_and_test_nginx() {
    print_step "啟動和測試 Nginx..."
    
    # 測試 Nginx 配置
    if nginx -t; then
        print_status "Nginx 配置測試通過"
    else
        print_error "Nginx 配置測試失敗"
        exit 1
    fi
    
    # 啟動 Nginx 服務
    systemctl enable nginx
    systemctl restart nginx
    
    # 檢查服務狀態
    if systemctl is-active --quiet nginx; then
        print_status "Nginx 服務啟動成功"
    else
        print_error "Nginx 服務啟動失敗"
        systemctl status nginx
        exit 1
    fi
    
    # 等待服務完全啟動
    sleep 3
    
    # 測試 HTTP 和 HTTPS 連接
    print_status "測試連接..."
    
    if curl -s -o /dev/null -w "%{http_code}" http://localhost | grep -q "301"; then
        print_status "✅ HTTP 重導向測試通過"
    else
        print_warning "⚠️ HTTP 重導向可能有問題"
    fi
    
    if curl -k -s -o /dev/null -w "%{http_code}" https://localhost | grep -q "200"; then
        print_status "✅ HTTPS 連接測試通過"
    else
        print_warning "⚠️ HTTPS 連接可能有問題"
    fi
}

# 顯示憑證資訊
show_certificate_info() {
    print_step "SSL 憑證資訊"
    
    echo
    print_status "憑證詳細資訊："
    openssl x509 -in /etc/ssl/certs/server.crt -noout -text | grep -E "(Subject:|Issuer:|Not Before|Not After|IP Address)"
    
    echo
    print_status "憑證指紋："
    openssl x509 -in /etc/ssl/certs/server.crt -noout -fingerprint -sha256
}

# 建立管理腳本
create_management_scripts() {
    print_step "建立管理腳本..."
    
    # SSL 續約腳本
    cat > /usr/local/bin/renew_ssl_cert.sh << 'EOF'
#!/bin/bash
# SSL 憑證續約腳本

SERVER_IP=$(hostname -I | awk '{print $1}')
CERT_PATH="/etc/ssl/certs/server.crt"
KEY_PATH="/etc/ssl/private/server.key"

echo "續約 SSL 憑證 for IP: $SERVER_IP"

# 備份舊憑證
cp $CERT_PATH $CERT_PATH.backup.$(date +%Y%m%d)

# 生成新憑證
openssl req -new -x509 -key $KEY_PATH \
    -out $CERT_PATH -days 365 \
    -subj "/C=TW/ST=Taipei/L=Taipei/O=MyServer/OU=IT/CN=$SERVER_IP" \
    -addext "subjectAltName=IP:$SERVER_IP,IP:127.0.0.1,IP:::1"

# 重載 Nginx
systemctl reload nginx

echo "SSL 憑證續約完成！"
EOF
    
    chmod +x /usr/local/bin/renew_ssl_cert.sh
    
    # SSL 檢查腳本
    cat > /usr/local/bin/check_ssl_cert.sh << 'EOF'
#!/bin/bash
# SSL 憑證檢查腳本

SERVER_IP=$(hostname -I | awk '{print $1}')
CERT_PATH="/etc/ssl/certs/server.crt"

echo "檢查 SSL 憑證狀態..."
echo "伺服器 IP: $SERVER_IP"
echo

# 檢查憑證有效期
echo "憑證有效期："
openssl x509 -in $CERT_PATH -noout -dates

# 檢查憑證主體
echo
echo "憑證主體："
openssl x509 -in $CERT_PATH -noout -subject

# 檢查 SAN
echo
echo "Subject Alternative Names:"
openssl x509 -in $CERT_PATH -noout -text | grep -A 1 "Subject Alternative Name"

# 測試 SSL 連接
echo
echo "測試 SSL 連接："
if curl -k -s -o /dev/null -w "HTTP Status: %{http_code}\n" https://$SERVER_IP; then
    echo "✅ SSL 連接正常"
else
    echo "❌ SSL 連接失敗"
fi
EOF
    
    chmod +x /usr/local/bin/check_ssl_cert.sh
    
    print_status "管理腳本建立完成"
    print_status "  - 續約憑證：sudo /usr/local/bin/renew_ssl_cert.sh"
    print_status "  - 檢查憑證：sudo /usr/local/bin/check_ssl_cert.sh"
}

# 顯示最終結果
show_final_results() {
    echo
    echo "=============================================="
    print_status "🎉 SSL 設定完成！"
    echo "=============================================="
    echo
    
    print_status "📝 設定摘要："
    echo "   • 伺服器 IP: $SERVER_IP"
    echo "   • SSL 憑證: 自簽憑證 (365 天有效期)"
    echo "   • 網頁伺服器: Nginx"
    echo "   • 加密協議: TLS 1.2/1.3"
    echo "   • HTTP 自動重導向: 啟用"
    echo
    
    print_status "🌐 訪問方式："
    echo "   • HTTPS: https://$SERVER_IP"
    echo "   • HTTP:  http://$SERVER_IP (自動重導向)"
    echo
    
    print_warning "⚠️  重要提醒："
    echo "   • 這是自簽憑證，瀏覽器會顯示安全警告"
    echo "   • 點擊「進階」→「繼續前往」即可正常訪問"
    echo "   • 僅適用於內網或測試環境"
    echo "   • 憑證將在 365 天後過期"
    echo
    
    print_status "🛠️  管理指令："
    echo "   • 檢查 Nginx 狀態: sudo systemctl status nginx"
    echo "   • 重載 Nginx 設定: sudo systemctl reload nginx"
    echo "   • 查看憑證資訊: sudo /usr/local/bin/check_ssl_cert.sh"
    echo "   • 續約憑證: sudo /usr/local/bin/renew_ssl_cert.sh"
    echo "   • 檢查防火牆: sudo ufw status"
    echo
    
    print_status "📂 重要檔案位置："
    echo "   • SSL 憑證: /etc/ssl/certs/server.crt"
    echo "   • 私鑰檔案: /etc/ssl/private/server.key"
    echo "   • Nginx 設定: /etc/nginx/sites-available/default"
    echo "   • 網站目錄: /var/www/html/"
    echo
    
    echo "=============================================="
    print_status "安裝完成！請使用瀏覽器訪問 https://$SERVER_IP 測試"
    echo "=============================================="
}

# 主函數
main() {
    echo "=============================================="
    echo "      Ubuntu IP SSL 自動安裝腳本 v1.0"
    echo "=============================================="
    echo
    
    # 執行安裝步驟
    check_root
    get_server_ip
    install_packages
    generate_ssl_certificate
    configure_nginx
    create_test_page
    configure_firewall
    start_and_test_nginx
    show_certificate_info
    create_management_scripts
    show_final_results
}

# 執行主函數
main "$@"
