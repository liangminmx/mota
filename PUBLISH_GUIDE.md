# 魔塔游戏发布指南

本指南将帮助您将Docker化的魔塔游戏发布到GitHub仓库和GitHub Packages。

## 准备工作

### 1. 获取GitHub Token

1. 访问 https://github.com/settings/tokens
2. 点击 "Generate new token"
3. 输入令牌描述，如 "Mota Game Docker"
4. 选择以下权限：
   - `repo` (完全控制私有仓库) 或 `public_repo` (公开仓库)
   - `write:packages` (推送镜像到GitHub Packages)
   - `delete:packages` (可选，但建议选择)
5. 生成令牌并复制保存（只会显示一次）

### 2. 创建GitHub仓库

1. 访问 https://github.com/new
2. 填写仓库信息：
   - Repository name: `mota-dockerized` (或自定义名称)
   - Description: "魔塔游戏Docker化版本"
   - 选择 Public 或 Private
   - **不要**添加 README.md、.gitignore 或 license（我们已有）
3. 点击 "Create repository"

## 发布流程

### 方案一：使用自动化脚本（推荐）

```bash
# 1. 确保有执行权限
chmod +x publish.sh

# 2. 运行发布脚本
./publish.sh --token YOUR_GITHUB_TOKEN --repo 用户名/仓库名

# 示例：
./publish.sh --token ghp_xxxxxxxxxxxxx --repo liangminmx/mota-dockerized
```

### 方案二：手动发布

#### 第1步：创建并推送GitHub仓库

```bash
# 初始化Git仓库（如果还未初始化）
git init

# 配置用户信息
git config user.name "您的用户名"
git config user.email "您的邮箱"

# 提交所有文件
git add .
git commit -m "feat: Docker化魔塔游戏"

# 添加远程仓库
git remote add origin git@github.com:用户名/仓库名.git

# 推送代码
git push -u origin main
```

#### 第2步：构建并推送Docker镜像

```bash
# 1. 构建镜像
docker build -t mota-game:latest .

# 2. 登录GitHub Container Registry
echo YOUR_GITHUB_TOKEN | docker login ghcr.io -u 您的用户名 --password-stdin

# 3. 标记镜像
docker tag mota-game:latest ghcr.io/用户名/仓库名:latest

# 4. 推送镜像
docker push ghcr.io/用户名/仓库名:latest
```

## 验证发布

### 验证GitHub仓库
1. 访问 https://github.com/用户名/仓库名
2. 确认所有文件已上传

### 验证Docker镜像
1. 访问 https://ghcr.io/用户名/仓库名
2. 或运行测试：
   ```bash
   docker pull ghcr.io/用户名/仓库名:latest
   docker run -d -p 8080:80 ghcr.io/用户名/仓库名:latest
   # 访问 http://localhost:8080
   ```

## 使用已发布的镜像

### 直接运行容器
```bash
docker run -d -p 8080:80 ghcr.io/用户名/仓库名:latest
```

### 在docker-compose.yml中使用
```yaml
version: '3.8'
services:
  mota-game:
    image: ghcr.io/用户名/仓库名:latest
    ports:
      - "8080:80"
    restart: unless-stopped
```

### 拉取和运行一键命令
```bash
# 拉取镜像
docker pull ghcr.io/用户名/仓库名:latest

# 运行容器
docker run -d --name mota-game -p 8080:80 ghcr.io/用户名/仓库名:latest
```

## 更新镜像

当游戏有更新时：

```bash
# 1. 更新代码并提交
git add .
git commit -m "更新描述"
git push

# 2. 重新构建和推送镜像
./publish.sh --token YOUR_GITHUB_TOKEN --repo 用户名/仓库名 --tag v1.0.1

# 或手动
docker build -t ghcr.io/用户名/仓库名:v1.0.1 .
docker push ghcr.io/用户名/仓库名:v1.0.1
```

## 故障排除

### 常见问题

1. **权限错误**
   ```
   Error: Bad credentials
   ```
   **解决**: 检查GitHub Token是否正确，是否有足够权限

2. **镜像推送失败**
   ```
   denied: requested access to the resource is denied
   ```
   **解决**: 确保已登录 `docker login ghcr.io`

3. **Git推送失败**
   ```
   Permission denied (publickey)
   ```
   **解决**: 配置SSH密钥，或使用HTTPS URL:
   ```bash
   git remote set-url origin https://github.com/用户名/仓库名.git
   ```

### Docker镜像大小优化

当前镜像基于nginx:alpine已很轻量，如需进一步优化：
- 使用多阶段构建
- 清理不必要的文件
- 使用更小的基础镜像（如scratch + 静态二进制）

## 安全建议

1. **令牌安全**:
   - 不要提交.gitignore中的.env.local文件
   - 在服务器上使用环境变量而不是硬编码
   - 定期轮换GitHub Token

2. **镜像安全**:
   - 定期扫描镜像漏洞：`docker scan ghcr.io/用户名/仓库名:latest`
   - 使用特定版本标签而非latest

3. **仓库安全**:
   - 私有仓库保护游戏源代码
   - 使用分支保护规则
   - 启用自动依赖更新

## 生产部署建议

1. **使用专有域名**: 配置域名指向服务器
2. **启用HTTPS**: 添加SSL证书
3. **配置监控**: 设置健康检查和日志收集
4. **自动扩缩容**: 根据访问量调整实例数
5. **定期备份**: 备份游戏配置文件

---

**发布完成标志**: 
- ✅ 代码推送至GitHub仓库
- ✅ Docker镜像推送至GitHub Packages
- ✅ 可正常拉取和运行镜像
- ✅ 游戏可通过浏览器访问