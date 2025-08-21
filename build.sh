#!/usr/bin/env bash
# 检查git是否安装
if ! command -v git &> /dev/null; then
  echo "git未安装，请先安装git。"
  exit 1
fi
# 检查是否存在pg_jieba目录，如果存在则更新,不存在就创建
if [ -d "pg_jieba" ]; then
  echo "pg_jieba目录已存在，正在更新..."
  cd pg_jieba
  git pull origin master
  git submodule update --init --recursive
  if [ $? -ne 0 ]; then
    echo "更新pg_jieba仓库失败，请检查网络连接或仓库地址。"
    exit 1
  fi
  cd ..
  echo "pg_jieba目录更新成功。"
else
  mkdir -p pg_jieba
  echo "pg_jieba目录不存在，已创建。"
  # 克隆pg_jieba仓库到pg_jieba目录
  echo "正在克隆pg_jieba仓库..."
  git clone https://github.com/jaiminpan/pg_jieba.git pg_jieba
  if [ $? -ne 0 ]; then
    echo "克隆pg_jieba仓库失败，请检查网络连接或仓库地址。"
    exit 1
  fi
  echo "pg_jieba仓库克隆成功。"
  cd pg_jieba
  git submodule update --init --recursive
  if [ $? -ne 0 ]; then
    echo "更新pg_jieba子模块失败，请检查网络连接或仓库地址。"
    exit 1
  fi
  echo "pg_jieba子模块更新成功。"
  cd ..
fi

# 检查是否存在age目录，如果存在则更新,不存在就创建
if [ -d "age" ]; then
  echo "age目录已存在，正在更新..."
  cd age
  git pull origin master
  if [ $? -ne 0 ]; then
    echo "更新age仓库失败，请检查网络连接或仓库地址。"
    exit 1
  fi
  cd ..
  echo "age目录更新成功。"
else
  mkdir -p age
  echo "age目录不存在，已创建。"
  # 克隆age仓库到age目录
  echo "正在克隆age仓库..."
  git clone https://github.com/apache/age.git age
  if [ $? -ne 0 ]; then
    echo "克隆age仓库失败，请检查网络连接或仓库地址。"
    exit 1
  fi
  echo "age仓库克隆成功。"
fi

# 检查是否存在pgvector目录，如果存在则更新,不存在就创建
#if [ -d "pgvector" ]; then
#  echo "pgvector目录已存在，正在更新..."
#  cd pgvector
#  git pull origin master
#  if [ $? -ne 0 ]; then
#    echo "更新pgvector仓库失败，请检查网络连接或仓库地址。"
#    exit 1
#  fi
#  cd ..
#  echo "pgvector目录更新成功。"
#else
#  mkdir -p pgvector
#  echo "pgvector目录不存在，已创建。"
#  # 克隆pgvector仓库到pgvector目录
#  echo "正在克隆pgvector仓库..."
#  git clone https://github.com/pgvector/pgvector.git pgvector
#  if [ $? -ne 0 ]; then
#    echo "克隆pgvector仓库失败，请检查网络连接或仓库地址。"
#    exit 1
#  fi
#  echo "pgvector仓库克隆成功。"
#fi

# 检查是否存在pg_data 目录,不存在就创建
if [ ! -d "pg_data" ]; then
  mkdir -p pg_data
  echo "pg_data目录不存在，已创建。"
else
  echo "pg_data目录已存在。"
fi
# 运行docker build命令
echo "正在构建Docker镜像..."
docker build -t pgvecto-rs-zh:latest .
#docker image rm pgvecto-rs-zh:latest
if [ $? -ne 0 ]; then
  echo "构建Docker镜像失败，请检查Dockerfile或网络连接。"
  exit 1
fi
echo "Docker镜像构建成功。"
