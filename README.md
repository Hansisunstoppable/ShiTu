# ShiTu - RAG 知识库服务端

一个基于 Golang 构建的企业级 RAG（检索增强生成）知识库系统，提供文档管理、智能检索和对话式问答功能。

## 📋 目录

- [技术栈](#技术栈)
- [核心特性](#核心特性)
- [数据库表结构](#数据库表结构)
- [项目结构](#项目结构)
- [快速开始](#快速开始)
- [API 文档](#api-文档)

## 🛠 技术栈

### 后端框架

- **Go 1.23** - 主要编程语言
- **Gin** - 高性能 HTTP Web 框架
- **GORM** - Go 语言 ORM 框架

### 数据存储

- **MySQL** - 关系型数据库，存储用户、文档元数据等
- **Redis** - 缓存和会话存储，用于对话历史管理
- **Elasticsearch** - 全文搜索引擎，支持混合检索
- **MinIO** - 对象存储服务，用于文件存储

### 消息队列

- **Kafka** - 异步文件处理任务队列

### 其他组件

- **JWT** - 用户认证和授权
- **Apache Tika** - 文档内容提取和解析
- **WebSocket** - 实时对话通信

## ✨ 核心特性

### 1. 文档管理

- **分块上传** - 支持大文件分块上传，提高上传稳定性
- **快速上传** - 支持小文件快速上传
- **多格式支持** - 支持 PDF、Word、Excel、PPT、TXT 等多种文档格式
- **文档解析** - 使用 Apache Tika 自动提取文档内容
- **文档预览** - 支持文档在线预览
- **文档下载** - 提供安全的文档下载链接

### 2. 智能检索

- **混合搜索** - 结合向量搜索和全文搜索的混合检索策略
- **语义理解** - 基于向量嵌入模型的语义检索
- **关键词匹配** - Elasticsearch 全文检索支持
- **权限过滤** - 基于组织标签的文档访问权限控制

### 3. RAG 对话

- **实时对话** - WebSocket 支持流式响应
- **上下文检索** - 自动从知识库检索相关文档片段
- **对话历史** - 保存和管理用户对话历史
- **引用标注** - 回答中自动标注信息来源

### 4. 用户与权限

- **用户认证** - JWT Token 认证机制
- **角色管理** - 支持普通用户和管理员角色
- **组织标签** - 层级化的组织标签体系
- **权限控制** - 基于组织标签的细粒度文档访问控制
- **公开/私有** - 支持文档公开和私有设置

### 5. 系统管理

- **管理员面板** - 用户管理、组织标签管理
- **对话监控** - 管理员可查看所有用户对话记录
- **异步处理** - 基于 Kafka 的异步文档处理管道

## 📊 数据库表结构

### users - 用户表

```sql
CREATE TABLE users (
    id BIGINT AUTO_INCREMENT PRIMARY KEY COMMENT '用户唯一标识',
    username VARCHAR(255) NOT NULL UNIQUE COMMENT '用户名，唯一',
    password VARCHAR(255) NOT NULL COMMENT '加密后的密码',
    role ENUM('USER', 'ADMIN') NOT NULL DEFAULT 'USER' COMMENT '用户角色',
    org_tags VARCHAR(255) DEFAULT NULL COMMENT '用户所属组织标签，多个用逗号分隔',
    primary_org VARCHAR(50) CHARACTER SET utf8mb4 COLLATE utf8mb4_bin DEFAULT NULL COMMENT '用户主组织标签',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
    INDEX idx_username (username) COMMENT '用户名索引'
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='用户表';
```

| 字段名      | 数据类型              | 是否允许NULL | 默认值                      | 约束        | 说明                             |
| ----------- | --------------------- | ------------ | --------------------------- | ----------- | -------------------------------- |
| id          | BIGINT                | NOT NULL     | AUTO_INCREMENT              | PRIMARY KEY | 用户唯一标识                     |
| username    | VARCHAR(255)          | NOT NULL     | -                           | UNIQUE      | 用户名，唯一                     |
| password    | VARCHAR(255)          | NOT NULL     | -                           | -           | 加密后的密码                     |
| role        | ENUM('USER', 'ADMIN') | NOT NULL     | 'USER'                      | -           | 用户角色                         |
| org_tags    | VARCHAR(255)          | NULL         | NULL                        | -           | 用户所属组织标签，多个用逗号分隔 |
| primary_org | VARCHAR(50)           | NULL         | NULL                        | -           | 用户主组织标签                   |
| created_at  | TIMESTAMP             | NOT NULL     | CURRENT_TIMESTAMP           | -           | 创建时间                         |
| updated_at  | TIMESTAMP             | NOT NULL     | CURRENT_TIMESTAMP ON UPDATE | -           | 更新时间                         |

### organization_tags - 组织标签表

```sql
CREATE TABLE organization_tags (
    tag_id VARCHAR(255) CHARACTER SET utf8mb4 COLLATE utf8mb4_bin PRIMARY KEY COMMENT '标签唯一标识',
    name VARCHAR(100) NOT NULL COMMENT '标签名称',
    description TEXT COMMENT '描述',
    parent_tag VARCHAR(255) CHARACTER SET utf8mb4 COLLATE utf8mb4_bin DEFAULT NULL COMMENT '父标签ID',
    created_by BIGINT NOT NULL COMMENT '创建者ID',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
    FOREIGN KEY (parent_tag) REFERENCES organization_tags(tag_id) ON DELETE SET NULL,
    FOREIGN KEY (created_by) REFERENCES users(id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='组织标签表';
```

| 字段名      | 数据类型     | 是否允许NULL | 默认值                      | 约束                                    | 说明                   |
| ----------- | ------------ | ------------ | --------------------------- | --------------------------------------- | ---------------------- |
| tag_id      | VARCHAR(255) | NOT NULL     | -                           | PRIMARY KEY, FOREIGN KEY (parent_tag)   | 标签唯一标识           |
| name        | VARCHAR(100) | NOT NULL     | -                           | -                                       | 标签名称               |
| description | TEXT         | NULL         | NULL                        | -                                       | 描述                   |
| parent_tag  | VARCHAR(255) | NULL         | NULL                        | FOREIGN KEY → organization_tags(tag_id) | 父标签ID，支持层级结构 |
| created_by  | BIGINT       | NOT NULL     | -                           | FOREIGN KEY → users(id)                 | 创建者ID               |
| created_at  | TIMESTAMP    | NOT NULL     | CURRENT_TIMESTAMP           | -                                       | 创建时间               |
| updated_at  | TIMESTAMP    | NOT NULL     | CURRENT_TIMESTAMP ON UPDATE | -                                       | 更新时间               |

### file_upload - 文件上传记录表

```sql
CREATE TABLE file_upload (
    id BIGINT NOT NULL AUTO_INCREMENT COMMENT '主键',
    file_md5 VARCHAR(32) NOT NULL COMMENT '文件 MD5',
    file_name VARCHAR(255) NOT NULL COMMENT '文件名称',
    total_size BIGINT NOT NULL COMMENT '文件大小',
    status TINYINT NOT NULL DEFAULT 0 COMMENT '上传状态',
    user_id VARCHAR(64) NOT NULL COMMENT '用户 ID',
    org_tag VARCHAR(50) DEFAULT NULL COMMENT '组织标签',
    is_public TINYINT(1) NOT NULL DEFAULT 0 COMMENT '是否公开',
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
    merged_at TIMESTAMP NULL DEFAULT NULL ON UPDATE CURRENT_TIMESTAMP COMMENT '合并时间',
    PRIMARY KEY (id),
    UNIQUE KEY uk_md5_user (file_md5, user_id),
    INDEX idx_user (user_id),
    INDEX idx_org_tag (org_tag)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='文件上传记录';
```

| 字段名     | 数据类型     | 是否允许NULL | 默认值            | 约束                       | 说明                                 |
| ---------- | ------------ | ------------ | ----------------- | -------------------------- | ------------------------------------ |
| id         | BIGINT       | NOT NULL     | AUTO_INCREMENT    | PRIMARY KEY                | 主键                                 |
| file_md5   | VARCHAR(32)  | NOT NULL     | -                 | UNIQUE (file_md5, user_id) | 文件 MD5 值，用于文件去重            |
| file_name  | VARCHAR(255) | NOT NULL     | -                 | -                          | 文件名称                             |
| total_size | BIGINT       | NOT NULL     | -                 | -                          | 文件大小（字节）                     |
| status     | TINYINT      | NOT NULL     | 0                 | -                          | 上传状态：0-上传中，1-已完成，2-失败 |
| user_id    | VARCHAR(64)  | NOT NULL     | -                 | INDEX                      | 用户 ID                              |
| org_tag    | VARCHAR(50)  | NULL         | NULL              | INDEX                      | 组织标签                             |
| is_public  | TINYINT(1)   | NOT NULL     | 0                 | -                          | 是否公开：0-私有，1-公开             |
| created_at | TIMESTAMP    | NOT NULL     | CURRENT_TIMESTAMP | -                          | 创建时间                             |
| merged_at  | TIMESTAMP    | NULL         | NULL              | -                          | 分块合并完成时间                     |

### chunk_info - 文件分块信息表

```sql
CREATE TABLE chunk_info (
    id BIGINT AUTO_INCREMENT PRIMARY KEY COMMENT '分块记录唯一标识',
    file_md5 VARCHAR(32) NOT NULL COMMENT '关联的文件MD5值',
    chunk_index INT NOT NULL COMMENT '分块序号',
    chunk_md5 VARCHAR(32) NOT NULL COMMENT '分块的MD5值',
    storage_path VARCHAR(255) NOT NULL COMMENT '分块在存储系统中的路径'
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='文件分块信息表';
```

| 字段名       | 数据类型     | 是否允许NULL | 默认值         | 约束        | 说明                        |
| ------------ | ------------ | ------------ | -------------- | ----------- | --------------------------- |
| id           | BIGINT       | NOT NULL     | AUTO_INCREMENT | PRIMARY KEY | 分块记录唯一标识            |
| file_md5     | VARCHAR(32)  | NOT NULL     | -              | -           | 关联的文件MD5值             |
| chunk_index  | INT          | NOT NULL     | -              | -           | 分块序号，从0开始           |
| chunk_md5    | VARCHAR(32)  | NOT NULL     | -              | -           | 分块的MD5值，用于校验完整性 |
| storage_path | VARCHAR(255) | NOT NULL     | -              | -           | 分块在存储系统中的路径      |

### document_vectors - 文档向量存储表

```sql
CREATE TABLE document_vectors (
    vector_id BIGINT AUTO_INCREMENT PRIMARY KEY COMMENT '向量记录唯一标识',
    file_md5 VARCHAR(32) NOT NULL COMMENT '关联的文件MD5值',
    chunk_id INT NOT NULL COMMENT '文本分块序号',
    text_content TEXT COMMENT '文本内容',
    model_version VARCHAR(32) COMMENT '向量模型版本',
    user_id VARCHAR(64) NOT NULL COMMENT '上传用户ID',
    org_tag VARCHAR(50) COMMENT '文件所属组织标签',
    is_public TINYINT(1) NOT NULL DEFAULT 0 COMMENT '文件是否公开'
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='文档向量存储表';
```

| 字段名        | 数据类型    | 是否允许NULL | 默认值         | 约束        | 说明                                     |
| ------------- | ----------- | ------------ | -------------- | ----------- | ---------------------------------------- |
| vector_id     | BIGINT      | NOT NULL     | AUTO_INCREMENT | PRIMARY KEY | 向量记录唯一标识                         |
| file_md5      | VARCHAR(32) | NOT NULL     | -              | INDEX       | 关联的文件MD5值                          |
| chunk_id      | INT         | NOT NULL     | -              | -           | 文本分块序号                             |
| text_content  | TEXT        | NULL         | NULL           | -           | 文本内容（实际向量存储在 Elasticsearch） |
| model_version | VARCHAR(32) | NULL         | NULL           | -           | 向量模型版本                             |
| user_id       | VARCHAR(64) | NOT NULL     | -              | -           | 上传用户ID                               |
| org_tag       | VARCHAR(50) | NULL         | NULL           | -           | 文件所属组织标签                         |
| is_public     | TINYINT(1)  | NOT NULL     | 0              | -           | 文件是否公开：0-私有，1-公开             |

### conversations - 对话记录表

```sql
CREATE TABLE conversations (
    id BIGINT AUTO_INCREMENT PRIMARY KEY COMMENT '对话记录唯一标识',
    user_id BIGINT NOT NULL COMMENT '用户ID',
    question TEXT NOT NULL COMMENT '用户问题',
    answer TEXT NOT NULL COMMENT 'AI回答',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
    INDEX idx_user_id (user_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='对话记录表';
```

| 字段名     | 数据类型  | 是否允许NULL | 默认值            | 约束        | 说明             |
| ---------- | --------- | ------------ | ----------------- | ----------- | ---------------- |
| id         | BIGINT    | NOT NULL     | AUTO_INCREMENT    | PRIMARY KEY | 对话记录唯一标识 |
| user_id    | BIGINT    | NOT NULL     | -                 | INDEX       | 用户ID           |
| question   | TEXT      | NOT NULL     | -                 | -           | 用户问题         |
| answer     | TEXT      | NOT NULL     | -                 | -           | AI回答           |
| created_at | TIMESTAMP | NOT NULL     | CURRENT_TIMESTAMP | -           | 创建时间         |

## 📁 项目结构

```
ShiTu/
├── configs/                 # 配置文件目录
│   ├── cmd/
│   │   └── server/
│   │       └── main.go      # 应用入口
│   └── config.yaml          # 应用配置
├── deployments/             # 部署相关文件
│   ├── docker-compose.yaml  # Docker Compose 配置
│   └── Dockerfile           # Docker 镜像构建文件
├── docs/                    # 文档目录
│   └── ddl.sql              # 数据库表结构定义
├── internal/                # 内部代码（不对外暴露）
│   ├── config/              # 配置管理
│   ├── handler/             # HTTP 请求处理器
│   ├── middleware/          # 中间件（认证、日志等）
│   ├── model/               # 数据模型
│   ├── pipeline/            # 文件处理管道
│   ├── repository/          # 数据访问层
│   └── service/             # 业务逻辑层
├── pkg/                     # 可复用的公共包
│   ├── database/            # 数据库连接（MySQL、Redis）
│   ├── embedding/           # 向量嵌入客户端
│   ├── es/                  # Elasticsearch 客户端
│   ├── hash/                # 密码加密
│   ├── kafka/               # Kafka 客户端
│   ├── llm/                 # LLM 客户端
│   ├── log/                 # 日志工具
│   ├── storage/             # MinIO 对象存储
│   ├── tika/                # Apache Tika 客户端
│   ├── token/               # JWT Token 管理
│   └── tasks/               # 后台任务
├── go.mod                   # Go 模块依赖
└── go.sum                   # Go 模块校验和
```

## 🚀 快速开始

### 前置要求

- Go 1.23
- MySQL 8.0
- Redis 7.2
- Elasticsearch 8.10
- Kafka 7.2.1
- MinIO
- Apache Tika Server

### 安装步骤

1. **克隆项目**

```bash
git clone https://github.com/Hansisunstoppable/ShiTu.git
cd ShiTu
```

2. **Docker 一键部署**

```bash
cd deployments
docker compose -f deployments/docker-compose.yaml up -d
```


3. **启动服务**

```bash
go run configs/cmd/server/main.go
```


## 📚 API 文档

### 认证相关

- `POST /api/v1/users/register` - 用户注册
- `POST /api/v1/users/login` - 用户登录
- `POST /api/v1/auth/refreshToken` - 刷新 Token
- `POST /api/v1/users/logout` - 用户登出

### 用户相关

- `GET /api/v1/users/me` - 获取当前用户信息
- `PUT /api/v1/users/primary-org` - 设置主组织
- `GET /api/v1/users/org-tags` - 获取用户组织标签

### 文件上传

- `POST /api/v1/upload/check` - 检查文件
- `POST /api/v1/upload/chunk` - 上传分块
- `POST /api/v1/upload/merge` - 合并分块
- `POST /api/v1/upload/fast-upload` - 快速上传
- `GET /api/v1/upload/status` - 获取上传状态
- `GET /api/v1/upload/supported-types` - 获取支持的文件类型

### 文档管理

- `GET /api/v1/documents/accessible` - 获取可访问的文档列表
- `GET /api/v1/documents/uploads` - 获取已上传的文档列表
- `DELETE /api/v1/documents/:fileMd5` - 删除文档
- `GET /api/v1/documents/download` - 生成下载链接
- `GET /api/v1/documents/preview` - 预览文档

### 搜索

- `GET /api/v1/search/hybrid` - 混合搜索

### 对话

- `GET /api/v1/users/conversation` - 获取对话历史
- `GET /chat/:token` - WebSocket 对话连接

### 管理员

- `GET /api/v1/admin/users/list` - 用户列表
- `PUT /api/v1/admin/users/:userId/org-tags` - 分配组织标签
- `GET /api/v1/admin/conversation` - 所有对话记录
- `POST /api/v1/admin/org-tags` - 创建组织标签
- `GET /api/v1/admin/org-tags` - 组织标签列表
- `GET /api/v1/admin/org-tags/tree` - 组织标签树
- `PUT /api/v1/admin/org-tags/:id` - 更新组织标签
- `DELETE /api/v1/admin/org-tags/:id` - 删除组织标签

