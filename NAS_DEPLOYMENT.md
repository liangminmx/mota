# 魔塔游戏NAS部署指南

本文档指导您将魔塔游戏部署到本地NAS设备。

## 📋 NAS部署准备

### 支持的NAS类型
1. **群晖 (Synology)** - Docker套件
2. **威联通 (QNAP)** - Container Station
3. **华芸 (ASUSTOR)** - Docker应用
4. **Linux NAS** - 手动Docker安装
5. **Windows NAS** - Docker Desktop

### 必要条件
- ✅ NAS支持Docker容器
- ✅ NAS有至少100MB可用空间
- ✅ 可从网络访问NAS

## 🚀 快速部署（三选一）

### 方案一：从GitHub镜像直接运行（最简单）

```bash
# 在NAS的SSH终端或Docker管理界面中执行
docker run -d \
  --name mota-game \
  -p 8080:80 \
  --restart unless-stopped \
  ghcr.io/liangminmx/mota:latest
```

### 方案二：使用docker-compose（推荐）

1. **在NAS上创建目录**
```bash
mkdir -p /volume1/docker/mota
cd /volume1/docker/mota
```

2. **下载docker-compose.yml**
```bash
wget https://raw.githubusercontent.com/liangminmx/mota/main/docker-compose.yml
wget https://raw.githubusercontent.com/liangminmx/mota/main/.env
```

3. **启动服务**
```bash
docker-compose up -d
```

### 方案三：手动构建和部署

1. **克隆项目**
```bash
cd /volume1/docker
git clone https://github.com/liangminmx/mota.git
cd mota
```

2. **构建镜像**
```bash
docker build -t mota-game:latest .
```

3. **运行容器**
```bash
docker run -d \
  --name mota-game \
  -p 8080:80 \
  -v /volume1/docker/mota/logs:/var/log/nginx \
  --restart unless-stopped \
  mota-game:latest
```

## 📱 各品牌NAS详细步骤

### 🖥️ 群晖DSM (Synology)

#### 方法A：通过Docker套件（图形界面）
1. 打开 **Docker** 套件
2. 点击 **注册表**，搜索 `ghcr.io/liangminmx/mota`
3. 双击镜像下载
4. 点击 **映像** → 选择 `ghcr.io/liangminmx/mota:latest` → **启动**
5. 容器设置：
   - **常规设置**：容器名称 `mota-game`
   - **端口设置**：本地端口 `8080` → 容器端口 `80`
   - **卷设置**（可选）：添加文件夹 `/docker/mota/logs` → `/var/log/nginx`
   - **环境**（可选）：无特殊要求
   - **重启策略**：`除非停止`
6. 点击 **应用** → **下一步** → **应用**

#### 方法B：通过SSH命令行
```bash
# 登录NAS SSH
ssh admin@你的NAS-IP

# 切换到高级权限
sudo -i

# 创建目录
mkdir -p /volume1/docker/mota
cd /volume1/docker/mota

# 下载并运行
docker run -d \
  --name mota-game \
  -p 8080:80 \
  -v $(pwd)/logs:/var/log/nginx \
  --restart unless-stopped \
  ghcr.io/liangminmx/mota:latest
```

### 🖥️ 威联通QNAP (Container Station)

#### 方法A：Web界面部署
1. 打开 **Container Station**
2. 点击 **创建** → **从Docker Hub搜索**
3. 搜索 `ghcr.io/liangminmx/mota`
4. 点击 **安装**
5. 配置：
   - **名称**: `mota-game`
   - **网络**：端口转发 `8080` → `80`
   - **挂载点**（可选）：`/share/Container/mota/logs` → `/var/log/nginx`
   - **高级设置** → **自动启动**：启用
6. 点击 **创建** → **确定**

#### 方法B：通过命令行
```bash
# 通过SSH登录QNAP
ssh admin@你的QNAP-IP

# 启用高级权限
sudo -i

# 运行容器
docker run -d \
  --name mota-game \
  -p 8080:80 \
  -v /share/Container/mota/logs:/var/log/nginx \
  --restart unless-stopped \
  ghcr.io/liangminmx/mota:latest
```

### 🖥️ 通用Linux NAS（OMV, Truenas等）

```bash
# 1. 确保Docker已安装
sudo apt update
sudo apt install docker.io docker-compose

# 2. 创建项目目录
sudo mkdir -p /opt/docker/mota
cd /opt/docker/mota

# 3. 使用docker-compose部署
sudo curl -L https://raw.githubusercontent.com/liangminmx/mota/main/docker-compose.yml -o docker-compose.yml
sudo curl -L https://raw.githubusercontent.com/liangminmx/mota/main/.env -o .env

# 4. 启动服务
sudo docker-compose up -d
```

## ⚙️ 自定义配置

### 修改端口
如果8080端口已被占用，修改端口映射：

```bash
# 改为9090端口
docker run -d \
  --name mota-game \
  -p 9090:80 \   # ← 修改这里
  ghcr.io/liangminmx/mota:latest
```

### 数据持久化
```bash
# 完整持久化配置
docker run -d \
  --name mota-game \
  -p 8080:80 \
  -v /your/nas/path/logs:/var/log/nginx \           # nginx日志
  -v /your/nas/path/nginx.conf:/etc/nginx/nginx.conf:ro \  # 自定义配置
  --restart unless-stopped \
  ghcr.io/liangminmx/mota:latest
```

### 环境变量
```bash
# 通过环境变量配置
docker run -d \
  --name mota-game \
  -p 8080:80 \
  -e NGINX_PORT=80 \
  -e TZ=Asia/Shanghai \
  ghcr.io/liangminmx/mota:latest
```

## 🔧 自动化脚本

### nas-deploy.sh（一键部署）
```bash
chmod +x nas-deploy.sh
./nas-deploy.sh
```
脚本将自动：
1. 检查Docker环境
2. 配置NAS专用路径
3. 启动容器服务
4. 验证部署状态

### web界面访问脚本
创建 `start-mota.sh`：
```bash
#!/bin/bash
# 启动魔塔游戏
docker-compose -f /volume1/docker/mota/docker-compose.yml up -d
echo "魔塔游戏已启动，访问：http://$(hostname -I | cut -d' ' -f1):8080"
```

## 🔍 验证部署

### 检查容器状态
```bash
docker ps | grep mota
docker logs mota-game --tail=20
docker inspect mota-game | grep -i "status\|health"
```

### 测试访问
```bash
# 在NAS上测试
curl -I http://localhost:8080

# 在局域网其他设备测试
curl -I http://NAS-IP:8080
```

### 查看游戏文件
```bash
# 进入容器
docker exec -it mota-game sh

# 查看游戏文件
ls -la /usr/share/nginx/html/
cat /usr/share/nginx/html/index.html
```

## 🌐 网络配置

### 局域网访问
- **NAS IP**: `192.168.x.x`（查看路由器分配）
- **端口**: `8080`（或自定义端口）
- **访问地址**: `http://NAS-IP:8080`

### 域名访问（如有公网IP）
1. 配置路由器端口转发：`8080` → `NAS-IP:8080`
2. 设置DDNS域名（如花生壳）
3. 访问：`http://your-domain.com:8080`

### 反向代理配置（推荐）
```nginx
# nginx反向代理配置
server {
    listen 80;
    server_name mota.your-nas.com;
    
    location / {
        proxy_pass http://localhost:8080;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
    }
}
```

## 📊 性能监控

### 资源使用
```bash
# 查看容器资源使用
docker stats mota-game

# 查看日志占用量
du -sh /volume1/docker/mota/logs/
```

### 健康检查
容器内置健康检查：
```bash
# 查看健康状态
docker inspect --format='{{json .State.Health}}' mota-game
```

## ⚠️ 故障排除

### 端口已被占用
```bash
# 查看端口占用
netstat -tulpn | grep :8080

# 停止占用进程
sudo fuser -k 8080/tcp

# 或使用其他端口
docker run -p 8090:80 ...
```

### 容器启动失败
```bash
# 查看错误日志
docker logs mota-game

# 常见问题解决：
# 1. 权限问题：添加 --user 1000:1000
# 2. 端口冲突：修改映射端口
# 3. 网络问题：检查防火墙
```

### 无法访问游戏
1. **检查防火墙**：
   ```bash
   # NAS防火墙规则
   iptables -I INPUT -p tcp --dport 8080 -j ACCEPT
   ```

2. **检查网络连通**：
   ```bash
   # 从外部测试
   telnet NAS-IP 8080
   ```

3. **重启容器**：
   ```bash
   docker restart mota-game
   ```

## 🔄 更新和维护

### 更新游戏
```bash
# 方法1：拉取最新镜像
docker pull ghcr.io/liangminmx/mota:latest
docker stop mota-game
docker rm mota-game
docker run ... # 重新运行

# 方法2：使用watchtower自动更新
docker run -d \
  --name watchtower \
  -v /var/run/docker.sock:/var/run/docker.sock \
  containrrr/watchtower mota-game
```

### 备份数据
```bash
# 备份容器配置
docker inspect mota-game > mota-backup.json

# 备份游戏数据（如有自定义）
tar -czf mota-backup.tar.gz /volume1/docker/mota/
```

### 清理空间
```bash
# 清理旧镜像
docker system prune -a

# 清理日志文件
find /volume1/docker/mota/logs -name "*.log" -mtime +7 -delete
```

## 📞 支持与帮助

### 快速诊断
```bash
# 运行诊断脚本
curl -s https://raw.githubusercontent.com/liangminmx/mota/main/test-deployment.sh | bash
```

### 获取帮助
- **GitHub Issues**: https://github.com/liangminmx/mota/issues
- **项目文档**: https://github.com/liangminmx/mota#readme
- **Docker镜像**: https://ghcr.io/liangminmx/mota

---

**部署成功标志**：
1. ✅ 容器运行正常：`docker ps` 显示状态 `Up`
2. ✅ 端口可访问：`curl -I http://localhost:8080` 返回200
3. ✅ 游戏可玩：浏览器访问显示魔塔游戏界面
4. ✅ 日志正常：`docker logs mota-game` 无错误

**祝您游戏愉快！** 🎮