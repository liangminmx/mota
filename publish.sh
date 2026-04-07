#!/bin/bash

# 魔塔游戏发布脚本 - 推送到GitHub和GitHub Packages

set -e

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# 默认值
GITHUB_TOKEN=""
REPO_NAME="mota"
GITHUB_USER="liangminmx"
IMAGE_NAME="mota"
TAG="latest"

# 显示帮助信息
show_help() {
    cat << EOF
魔塔游戏发布脚本

用法: $0 [选项]

选项:
  -t, --token TOKEN       GitHub Token (必需)
  -r, --repo REPO         GitHub仓库名 [用户名/仓库名] (默认: liangminmx/mota)
  -u, --user USER         GitHub用户名 (默认: liangminmx)
  -i, --image IMAGE       Docker镜像名 (默认: mota)
  --tag TAG              Docker标签 (默认: latest)
  -h, --help             显示帮助信息

示例:
  $0 --token ghp_xxxxxx
  $0 --token ghp_xxxxxx --repo liangminmx/mota-game
  $0 --token ghp_xxxxxx --user myuser --image my-mota

注意:
  GitHub Token需要有:
    - repo (完全控制私有仓库) 或 public_repo (公开仓库)
    - write:packages (推送镜像到GitHub Packages)
    - delete:packages (可选，删除镜像)
EOF
}

# 解析参数
while [[ $# -gt 0 ]]; do
    case $1 in
        -t|--token)
            GITHUB_TOKEN="$2"
            shift 2
            ;;
        -r|--repo)
            REPO_NAME="$2"
            shift 2
            ;;
        -u|--user)
            GITHUB_USER="$2"
            shift 2
            ;;
        -i|--image)
            IMAGE_NAME="$2"
            shift 2
            ;;
        --tag)
            TAG="$2"
            shift 2
            ;;
        -h|--help)
            show_help
            exit 0
            ;;
        *)
            echo -e "${RED}错误: 未知选项 $1${NC}"
            show_help
            exit 1
            ;;
    esac
done

# 检查必需参数
if [[ -z "$GITHUB_TOKEN" ]]; then
    echo -e "${RED}错误: GitHub Token是必需的${NC}"
    show_help
    exit 1
fi

# 从REPO_NAME提取用户名和仓库名
if [[ "$REPO_NAME" == */* ]]; then
    GITHUB_USER="${REPO_NAME%%/*}"
    REPO_NAME="${REPO_NAME#*/}"
fi

echo -e "${BLUE}=== 魔塔游戏发布流程开始 ===${NC}"
echo "GitHub用户: $GITHUB_USER"
echo "仓库名称: $REPO_NAME"
echo "镜像名称: $IMAGE_NAME"
echo "镜像标签: $TAG"

# 第1步：构建Docker镜像
echo -e "\n${GREEN}1. 构建Docker镜像...${NC}"
if ! docker build -t ${IMAGE_NAME}:${TAG} .; then
    echo -e "${RED}✗ Docker镜像构建失败${NC}"
    exit 1
fi
echo -e "${GREEN}✓ Docker镜像构建成功${NC}"

# 第2步：登录GitHub Container Registry
echo -e "\n${GREEN}2. 登录GitHub Container Registry...${NC}"
if echo "$GITHUB_TOKEN" | docker login ghcr.io -u "$GITHUB_USER" --password-stdin; then
    echo -e "${GREEN}✓ 登录成功${NC}"
else
    echo -e "${RED}✗ 登录失败${NC}"
    exit 1
fi

# 第3步：标记镜像
echo -e "\n${GREEN}3. 标记Docker镜像...${NC}"
IMAGE_FULL="ghcr.io/${GITHUB_USER}/${IMAGE_NAME}:${TAG}"
docker tag ${IMAGE_NAME}:${TAG} ${IMAGE_FULL}
echo -e "${GREEN}✓ 镜像标记完成: ${IMAGE_FULL}${NC}"

# 第4步：推送镜像到GitHub Packages
echo -e "\n${GREEN}4. 推送镜像到GitHub Packages...${NC}"
if docker push ${IMAGE_FULL}; then
    echo -e "${GREEN}✓ 镜像推送成功${NC}"
else
    echo -e "${RED}✗ 镜像推送失败${NC}"
    exit 1
fi

# 第5步：检查代码是否已提交到Git
echo -e "\n${GREEN}5. 检查Git状态...${NC}"
if [[ -d ".git" ]]; then
    # 检查是否有未提交的更改
    if [[ -n $(git status --porcelain) ]]; then
        echo -e "${YELLOW}⚠ 发现未提交的更改${NC}"
        git status --short
    else
        echo -e "${GREEN}✓ 所有更改已提交${NC}"
    fi
    
    # 检查是否有远程仓库
    REMOTE_URL=$(git remote get-url origin 2>/dev/null || true)
    if [[ -z "$REMOTE_URL" ]]; then
        echo -e "${YELLOW}⚠ 未设置远程仓库${NC}"
        echo "请使用以下命令手动设置:"
        echo "  git remote add origin git@github.com:${GITHUB_USER}/${REPO_NAME}.git"
        echo "  git push -u origin main"
    else
        echo -e "${GREEN}✓ 远程仓库已配置: ${REMOTE_URL}${NC}"
    fi
else
    echo -e "${YELLOW}⚠ 未初始化Git仓库${NC}"
fi

# 第6步：创建GitHub仓库（如果不存在）
echo -e "\n${GREEN}6. 创建GitHub仓库（可选）...${NC}"
echo -e "${YELLOW}注意: 自动创建仓库需要GitHub API权限${NC}"
echo -e "${YELLOW}请手动创建仓库: https://github.com/new${NC}"
echo "仓库名称: $REPO_NAME"
echo "描述: 魔塔游戏Docker化版本"

# 第7步：使用说明
echo -e "\n${BLUE}=== 发布完成 ===${NC}"
echo ""
echo -e "${GREEN}使用说明:${NC}"
echo "1. 拉取镜像运行:"
echo "   docker pull ${IMAGE_FULL}"
echo "   docker run -d -p 8080:80 ${IMAGE_FULL}"
echo ""
echo "2. 在docker-compose.yml中使用:"
echo "   image: ${IMAGE_FULL}"
echo ""
echo -e "${GREEN}镜像信息:${NC}"
echo "   - 访问地址: https://ghcr.io/${GITHUB_USER}/${IMAGE_NAME}"
echo "   - 标签: ${TAG}"
echo ""
echo -e "${YELLOW}后续步骤:${NC}"
echo "1. 手动创建GitHub仓库: https://github.com/new"
echo "2. 推送代码到GitHub:"
echo "   git remote add origin git@github.com:${GITHUB_USER}/${REPO_NAME}.git"
echo "   git push -u origin main"
echo ""
echo -e "${BLUE}=== 发布流程结束 ===${NC}"