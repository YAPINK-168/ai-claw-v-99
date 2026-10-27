# 抓娃娃街机 · 联机服务器（账号 / 积分）

本地演示版：FastAPI + MySQL + 简易管理网页。

## 功能

- 玩家注册 / 登录，管理员登录
- 玩家资料、积分余额、积分流水（幂等防重复）
- 上机 / 下机会话
- 管理后台：查玩家、调整积分、启停账号

## 目录

```
server/
  app/           # 后端
  sql/           # 建表脚本
  static/        # 管理台页面
  scripts/       # 初始化数据
  requirements.txt
  .env.example
```

## 快速开始

### 1. 安装依赖

```powershell
cd "c:\Users\wmy10\Documents\街机小游戏\server"
py -3.12 -m venv .venv
.\.venv\Scripts\Activate.ps1
pip install -r requirements.txt
copy .env.example .env
```

### 2. MySQL（本机已装好可直接用）

本机开发环境已初始化：

- MySQL 8.4.9
- 库：`claw_arcade`
- 应用账号：`claw / claw123`
- 启动数据库：`scripts\start_mysql.bat`

表结构见 `sql/001_schema.sql`（stores / users / player_profiles / point_accounts / point_ledger / machines / machine_sessions / admin_audit_logs）。

### 3. 启动服务

```powershell
scripts\start_server.bat
```

或：

```powershell
.\.venv\Scripts\Activate.ps1
uvicorn app.main:app --host 0.0.0.0 --port 8000 --reload
```

浏览器打开：http://127.0.0.1:8000/  
接口文档：http://127.0.0.1:8000/docs  

更完整的本机账号见 `本地说明.txt`。

### 演示账号

| 账号 | 密码 | 角色 |
|------|------|------|
| admin | admin123 | 超级管理员 |
| storeadmin | admin123 | 门店管理员 |
| player1 | 123456 | 玩家 |
| player2 | 123456 | 玩家 |

## 主要 API

- `POST /api/auth/register` 玩家注册
- `POST /api/auth/login` 登录
- `GET /api/me` 当前用户
- `POST /api/session/start` 上机
- `POST /api/session/end` 下机
- `POST /api/points/add` 机台上报积分（需 `client_event_id` 幂等）
- `GET /api/points/ledger` 我的流水
- `GET /api/admin/players` 玩家列表
- `POST /api/admin/points/adjust` 管理员调分
- `GET /docs` Swagger 文档
