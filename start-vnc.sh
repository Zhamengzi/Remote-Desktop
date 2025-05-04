#!/bin/bash

# start-vnc.sh
# Script untuk memulai VNC server dengan konfigurasi XFCE

# Konfigurasi dasar
DISPLAY_NUM=1
RESOLUTION="1280x720"
DEPTH=24
VNC_PORT=5901
VNC_PASSWD_FILE="$HOME/.vnc/passwd"

# Fungsi untuk membersihkan session sebelumnya
cleanup() {
    echo "Membersihkan session VNC sebelumnya..."
    vncserver -kill :$DISPLAY_NUM >/dev/null 2>&1
    rm -rf /tmp/.X$DISPLAY_NUM-lock
    rm -rf /tmp/.X11-unix/X$DISPLAY_NUM
}

# Setup environment
setup_vnc() {
    echo "Menyiapkan environment VNC..."
    mkdir -p $HOME/.vnc
    chmod 700 $HOME/.vnc
    
    # File xstartup untuk XFCE
    cat > $HOME/.vnc/xstartup <<EOF
#!/bin/sh
unset SESSION_MANAGER
unset DBUS_SESSION_BUS_ADDRESS
export XKL_XMODMAP_DISABLE=1
export XDG_CURRENT_DESKTOP=XFCE
export XDG_DATA_DIRS=$XDG_DATA_DIRS:/usr/share/xfce4:/usr/share
exec startxfce4
EOF

    chmod +x $HOME/.vnc/xstartup
}

# Set password VNC
set_password() {
    if [ -z "$VNC_PASSWORD" ]; then
        echo -e "\n\e[31m[WARNING] VNC_PASSWORD tidak di-set!\e[0m"
        echo -e "Gunakan password default 'vncpassword'"
        VNC_PASSWORD="vncpassword"
    fi
    
    echo -e "$VNC_PASSWORD\n$VNC_PASSWORD\nn" | vncpasswd $VNC_PASSWD_FILE
    chmod 600 $VNC_PASSWD_FILE
}

# Mulai VNC server
start_vnc() {
    echo "Memulai VNC server pada display :$DISPLAY_NUM"
    vncserver :$DISPLAY_NUM \
        -geometry $RESOLUTION \
        -depth $DEPTH \
        -localhost no \
        -SecurityTypes VncAuth,TLSVnc \
        -PasswordFile $VNC_PASSWD_FILE
    
    echo -e "\n\e[32mVNC BERHASIL DIAKTIFKAN!\e[0m"
    echo "===================================="
    echo "Alamat Koneksi:"
    
    # Untuk GitHub Actions + Ngrok
    if [ -n "$NGROK_TOKEN" ]; then
        echo "1. Via Ngrok: $(curl -s http://localhost:4040/api/tunnels | jq -r '.tunnels[0].public_url')"
    fi
    
    # Untuk Termux/Lokal
    echo "2. Lokal: $(hostname -I | awk '{print $1}'):$VNC_PORT"
    echo "===================================="
}

# Main execution
cleanup
setup_vnc
set_password
start_vnc

# Jalankan ngrok jika token tersedia
if [ -n "$NGROK_TOKEN" ]; then
    echo "Memulai Ngrok..."
    ./ngrok tcp $VNC_PORT --authtoken $NGROK_TOKEN --log stdout > ngrok.log &
    sleep 3
    echo "URL Ngrok: $(curl -s http://localhost:4040/api/tunnels | jq -r '.tunnels[0].public_url')"
fi

# Pertahankan session aktif
tail -f /dev/null
