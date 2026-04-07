# 魔塔游戏 Docker 化部署

这是魔塔游戏的Docker化版本，基于nginx提供静态文件服务。

## 快速开始

### 前提条件

- 安装 [Docker](https://docs.docker.com/get-docker/)
- 安装 [Docker Compose](https://docs.docker.com/compose/install/)

### 部署步骤

1. **进入项目目录**
   ```bash
   cd /vol1/1000/文件/github/mota
   ```

2. **一键部署**
   ```bash
   ./deploy.sh
   ```

   或者手动部署：
   ```bash
   docker-compose up -d
   ```

3. **访问游戏**
   打开浏览器访问：http://localhost:8080

## 文件结构

```
/vol1/1000/文件/github/mota/
├── mt/                    # 游戏源文件
│   ├── index.html        # 主页面
│   ├── main.js           # 主逻辑
│   ├── styles.css        # 样式表
│   ├── libs/             # 游戏库文件
│   ├── images/           # 图片资源
│   ├── animates/         # 动画资源
│   └── ...
├── Dockerfile            # Docker构建文件
├── docker-compose.yml    # Docker编排配置
├── deploy.sh             # 一键部署脚本
├── test-deployment.sh    # 部署测试脚本
├── cleanup.sh            # 清理脚本
├── nginx.conf            # nginx配置文件
├── .env                  # 环境变量配置
└── README.md             # 本文档
```

## 配置说明

### 端口配置

默认将容器的80端口映射到主机的8080端口，如需修改，请编辑 `docker-compose.yml`：

```yaml
ports:
  - "自定义端口:80"  # 例如: "3000:80"
```

### 自定义nginx配置

如需自定义nginx配置，可以创建 `nginx.conf` 文件并修改Dockerfile：

```dockerfile
COPY nginx.conf /etc/nginx/nginx.conf
```

## 管理命令

### 启动服务
```bash
docker-compose up -d
```

### 停止服务
```bash
docker-compose down
```

### 查看日志
```bash
docker-compose logs -f
```

### 重启服务
```bash
docker-compose restart
```

### 更新服务（重新构建）
```bash
docker-compose build --no-cache
docker-compose up -d
```

## 技术实现

- **基础镜像**: nginx:alpine（轻量级）
- **工作目录**: /usr/share/nginx/html
- **服务端口**: 80（容器内）
- **数据持久化**: 无（纯静态游戏，无需数据库）
- **游戏保存**: 使用浏览器localStorage保存游戏进度

## 注意事项

1. 游戏为纯前端实现，无需后端服务器
2. 浏览器关闭后游戏进度仍会保留（localStorage）
3. 不同浏览器/设备间的游戏进度不共享
4. 如需要多用户或云端保存功能，需额外开发后端服务

## 故障排除

### 端口占用
如果8080端口已被占用，请修改 `docker-compose.yml` 中的端口映射。

### 权限问题
确保对游戏文件有读取权限。

### Docker问题
确保Docker服务正常运行：
```bash
sudo systemctl status docker
```

## ✅ 已完成的工作

### 已完成步骤:
1. ✅ **Docker化配置**: 创建完整的Docker部署套件
2. ✅ **游戏分析**: 确认魔塔为纯前端HTML5游戏
3. ✅ **镜像构建**: 成功构建 `mota-game:latest` 镜像 (64.4MB)
4. ✅ **本地标记**: 镜像已标记为 `ghcr.io/liangminmx/mota:latest`
5. ✅ **Git初始化**: 项目已初始化为Git仓库，包含完整提交历史
6. ✅ **自动化脚本**: 提供一键部署、测试、清理、发布脚本
7. ✅ **详细文档**: README.md, PUBLISH_GUIDE.md 提供完整指南

### 待完成步骤（需要您的操作）:
1. **创建GitHub仓库**: 在GitHub创建新仓库（建议名称 `mota`）
2. **获取GitHub Token**: 创建有 write:packages 权限的Token
3. **推送代码**: 将本地代码推送到GitHub仓库
4. **推送镜像**: 使用Token登录并推送镜像到GitHub Packages

## 🚀 发布到GitHub和Docker镜像

### 发布到GitHub仓库

1. **在GitHub上创建新仓库**
   - 访问 https://github.com/new
   - 仓库名称: `mota` (建议)
   - 描述: "魔塔游戏Docker化版本"
   - 选择公共或私有
   - 不初始化README.md (因为我们已有)

2. **推送代码到GitHub**
   ```bash
   # 添加远程仓库
   git remote add origin git@github.com:liangminmx/mota.git
   
   # 推送代码
   git push -u origin main
   ```

### 发布Docker镜像到GitHub Packages

1. **登录GitHub Container Registry**
   ```bash
   # 创建GitHub Token (需要有 write:packages 权限)
   # 然后登录
   echo $GITHUB_TOKEN | docker login ghcr.io -u liangminmx --password-stdin
   ```

2. **标记并推送镜像**
   ```bash
   # 标记镜像
   docker tag mota-game:latest ghcr.io/liangminmx/mota:latest
   
   # 推送镜像
   docker push ghcr.io/liangminmx/mota:latest
   ```

3. **使用GitHub镜像**
   ```bash
   # 拉取镜像
   docker pull ghcr.io/liangminmx/mota:latest
   
   # 运行容器
   docker run -d -p 8080:80 ghcr.io/liangminmx/mota:latest
   ```

### 自动化脚本

提供了自动化发布脚本 `publish.sh`:

```bash
./publish.sh --token YOUR_GITHUB_TOKEN --repo liangminmx/mota
```

## 扩展功能（可选）

如需添加以下功能，请自行修改：

1. **HTTPS支持**: 添加SSL证书，配置nginx支持HTTPS
2. **CDN加速**: 配置CDN加速静态资源
3. **多语言支持**: 修改游戏界面支持多语言
4. **用户系统**: 添加后端服务支持用户注册和云存档

## 许可证

游戏源文件版权归原作者所有。
Docker化部署文件遵循MIT许可证。