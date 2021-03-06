#! /bin/bash
PATH=/bin:/sbin:/usr/bin:/usr/sbin:/usr/local/bin:/usr/local/sbin:~/bin
export PATH

clear
echo "#############################################################"
echo "# Install My config in Ubuntu"
echo "#"
echo "#############################################################"
echo ""

function install_vps() {
    rootness
    get_my_ip
    read -p "是否安装shadowsocks？[y/n]" isInstallSS
    read -p "是否安装Aria2？[y/n]" isInstallAria2
    read -p "是否添加Swap？[y/n]" isAddSwap
    read -p "是否安装net-speeder？[y/n]" isinstallNetspeeder
    read -p "是否安装denyhosts？[y/n]" isDenyhosts
    install_SS
    install_Aria2
    addSwap
    install_net-speeder
    install_denyhosts

}

# Make sure only root can run our script
function rootness() {
    if [[ $EUID -ne 0 ]]; then
    echo "Error:This script must be run as root!" 1>&2
    exit 1
    fi
}

# Get IP address of the server
function get_my_ip() {
    echo "获取 IP..."
    IP=`/sbin/ifconfig -a|grep inet|grep -v 127.0.0.1|grep -v inet6|awk '{print $2}'|tr -d "addr:"`
#IP=`curl -s checkip.dyndns.com | cut -d' ' -f 6  | cut -d'<' -f 1`
    if [ -z $IP ]; then
    IP=`curl -s ifconfig.me/ip`
    fi
}

function install_SS() {
    case $isInstallSS in
    y|Y|yes|Yes)
    yum -y update
    echo "安装 shadowsocks..."
    yum install -y python-setuptools
    easy_install pip
    pip install shadowsocks

    setup_SS
    ;;
}

function setup_SS() {
    echo "配置 shadowsocks..."
    /sbin/ifconfig|sed -n '/inet addr/s/^[^:]*:\([0-9.]\{7,15\}\) .*/\1/p'
    cat > /etc/shadowsocks.json << EOF
{
    "server":"${IP}",
    "port_password":{
    "8381":"LyzLyz123",
    "8382":"LyzLyz123",
    "8481":"CylCyl"
    },
    "timeout":300,
    "method":"bf-cfb",
    "fast_open":true,
    "workers":1
}
EOF

    sed -i '/INPUT.*NEW.*22/a -A INPUT -m state --state NEW -m tcp -p tcp --dport 8381 -j ACCEPT' /etc/sysconfig/iptables
    sed -i '/INPUT.*NEW.*22/a -A INPUT -m state --state NEW -m tcp -p tcp --dport 8382 -j ACCEPT' /etc/sysconfig/iptables
    sed -i '/INPUT.*NEW.*22/a -A INPUT -m state --state NEW -m tcp -p tcp --dport 8481 -j ACCEPT' /etc/sysconfig/iptables

# 启动服务
    echo "后台启动 shadowsocks..."
    ssserver -c /etc/shadowsocks.json -d start
    echo 'ssserver -c /etc/shadowsocks.json -d start' >> /etc/rc.local
}

function install_Aria2() {
    case $isInstallAria2 in
    y|Y|yes|Yes)
    echo "安装 Aria2..."
    wget http://pkgs.repoforge.org/rpmforge-release/rpmforge-release-0.5.2-2.el6.rf.i686.rpm
    rpm -ivh rpmforge-release-0.5.2-2.el6.rf.i686.rpm
    yum install aria2 -y
    rm -f rpmforge-release-0.5.2-2.el6.rf.i686.rpm
    mkdir /root/Downloads
    touch /root/Downloads/aria2.conf
    touch /root/Downloads/aria2.session
    cat << EOF > /root/Downloads/aria2.conf
#允许rpc
enable-rpc=true
#允许所有来源, web界面跨域权限需要
rpc-allow-origin-all=true
#允许非外部访问
rpc-listen-all=true
#RPC端口, 仅当默认端口被占用时修改
#rpc-listen-port=6800
rpc-user=command
rpc-passwd=LyzLyz
#最大同时下载数(任务数), 路由建议值: 3
max-concurrent-downloads=10
#断点续传
continue=true
#同服务器连接数
max-connection-per-server=10
#最小文件分片大小, 下载线程数上限取决于能分出多少片, 对于小文件重要
min-split-size=10M
#单文件最大线程数, 路由建议值: 5
split=10
#下载速度限制
max-overall-download-limit=0
#单文件速度限制
max-download-limit=0
#上传速度限制
max-overall-upload-limit=0
#单文件速度限制
max-upload-limit=0
#断开速度过慢的连接
#lowest-speed-limit=0
#验证用，需要1.16.1之后的release版本
#referer=*
input-file=/root/Downloads/aria2.session
save-session=/root/Downloads/aria2.session
#定时保存会话，需要1.16.1之后的release版
#save-session-interval=60
#文件保存路径, 默认为当前启动位置
dir=/root/Downloads
#文件缓存, 使用内置的文件缓存, 如果你不相信Linux内核文件缓存和磁盘内置缓存时使用, 需要1.16及以上版本
#disk-cache=0
#另一种Linux文件缓存方式, 使用前确保您使用的内核支持此选项, 需要1.15及以上版本(?)
#enable-mmap=true
#文件预分配, 能有效降低文件碎片, 提高磁盘性能. 缺点是预分配时间较长
#所需时间 none < falloc ? trunc << prealloc, falloc和trunc需要文件系统和内核支持
file-allocation=prealloc
#启用本地节点查找
bt-enable-lpd=true
#添加额外的tracker
#bt-tracker=<URI>,…
#单种子最大连接数
#bt-max-peers=55
#强制加密, 防迅雷必备
#bt-require-crypto=true
#当下载的文件是一个种子(以.torrent结尾)时, 自动下载BT
follow-torrent=true
#BT监听端口, 当端口屏蔽时使用
#listen-port=6881-6999
#不确定是否需要，为保险起见，need more test
enable-dht=false
bt-enable-lpd=false
enable-peer-exchange=false
#修改特征
user-agent=uTorrent/2210(25130)
peer-id-prefix=-UT2210-
#修改做种设置, 允许做种
seed-ratio=0
#保存会话
#force-save=
bt-hash-check-seed=true
bt-seed-unverified=true
bt-save-metadata=true
#定时保存会话，需要1.16.1之后的某个release版本（比如1.16.2）
save-session-interval=60
EOF

;;
}

function addSwap() {
    case $isAddSwap in
    y|Y|yes|Yes)

    echo "添加 Swap..."
    /bin/dd if=/dev/zero of=/var/swap.1 bs=1M count=1152
    /sbin/mkswap /var/swap.1
    /sbin/swapon /var/swap.1
    sed -i '$a /var/swap.1 swap swap default 0 0' /etc/fstab
    ;;
}

function install_net-speeder() {
    case $isinstallNetspeeder in
    y|Y|yes|Yes)

    wget http://dl.fedoraproject.org/pub/epel/6/x86_64/epel-release-6-8.noarch.rpm
    rpm -ivh epel-release-6-8.noarch.rpm
    yum -y install libnet libpcap libnet-devel libpcap-devel
    yum -y install zip unzip
    wget https://github.com/snooda/net-speeder/archive/master.zip
    unzip master.zip
    cd net-speeder-master
    yum install -y gcc gcc-c++ make zlib-devel
    sh build.sh
    cp ./net_speeder /usr/bin
    nohup /usr/bin/net_speeder eth0 "ip" >/dev/null 2>&1 &
    echo 'nohup /usr/bin/net_speeder eth0 "ip" >/dev/null 2>&1 &' >> /etc/rc.local
    echo "net-speeder 启动成功..."
    rm -f epel-release-6-8.noarch.rpm
    rm -f rpmforge-release-0.5.2-2.el6.rf.i686.rpm
    rm -f master.zip

    ;;
}

function install_denyhosts() {
    case $isDenyhosts in
    y|Y|yes|Yes)
    echo "安装denyhosts..."
    yum -y install denyhosts
    cat << EOF > /etc/denyhosts.conf
SECURE_LOG = /var/log/secure
HOSTS_DENY = /etc/hosts.deny
PURGE_DENY = 4w
BLOCK_SERVICE  = sshd
DENY_THRESHOLD_INVALID = 2
DENY_THRESHOLD_VALID = 2
DENY_THRESHOLD_ROOT = 2
DENY_THRESHOLD_RESTRICTED = 1
WORK_DIR = /var/lib/denyhosts
SUSPICIOUS_LOGIN_REPORT_ALLOWED_HOSTS=YES
HOSTNAME_LOOKUP=YES
LOCK_FILE = /var/lock/subsys/denyhosts
ADMIN_EMAIL = root
SMTP_HOST = localhost
SMTP_PORT = 25
SMTP_FROM = DenyHosts <nobody@localhost>
SMTP_SUBJECT = DenyHosts Report from $[HOSTNAME]
AGE_RESET_VALID=5d
AGE_RESET_ROOT=25d
AGE_RESET_RESTRICTED=25d
AGE_RESET_INVALID=10d
DAEMON_LOG = /var/log/denyhosts
DAEMON_SLEEP = 30s
DAEMON_PURGE = 1h
EOF
    service denyhosts start
    ;;
}

funcation installNginx() {
    echo "installing Nginx..."
    yum -y install nginx
    service nginx start
    chkconfig nginx on
}

funcation insstallMysql() {
    echo "installing mysql"
    yum -y install mysql-server
    service mysqld restart
    chkconfig mysqld on
}

funcation installPHP() {
    echo "installing php"
    yum -y install php-fpm php-mysql
    service php-fpm start
    chkconfig php-fpm on
    mkdir /var/lib/php/session/
    chown -R apache:apache /var/lib/php/session/
}

#自动化安装并启动一个博客程序及其运行环境的docker容器
#google authentication

install_vps


