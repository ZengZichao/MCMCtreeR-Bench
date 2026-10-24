# 运维

## 监控

每次发布后检查 revision 日志并运行 staging 冒烟测试。每周在内容页查看 usage
credits、内存峰值与错误日志。Free 计划提供 4 GB 内存、1 CPU、每月 20 个 usage
credits 与五个应用；公开分享不占用 seat。

## 回滚

Connect Cloud 保留每个 revision，旧 bundle 仍可查看。回滚需要检出上一个 commit
并重新部署：

```bash
git log --oneline
git checkout <previous-commit>
CONNECT_CLOUD_APP=mcmctreer-gui Rscript dev/deploy.R
```

只有当 `renv.lock` 与 `manifest.json` 固定到同一上游 commit 时，回滚才可复现。

## 额度

本应用按学术演示用量设计：

- 上传总量 50 MB；
- 每棵树 3,000 tips、6,000 节点；
- 后验 200,000 行；
- PDF 页面最大 16 x 12 英寸；
- PNG 最大 12 x 9 英寸、200 dpi。

长任务需要显式触发，大后验默认手动重绘。需要反复或大规模运行的用户应在本地
安装。

## Token 轮换

如果 Connect Cloud client secret 泄露，请在 Posit 账户设置中删除该凭据、创建
新凭据，再用 `rsconnect::connectCloudClientCredentials()` 重新注册，运行一次
staging 部署并确认旧凭据失效。仅用 `rsconnect::removeAccount()` 删除本地账户
不够；必须轮换 secret 本身。

## 迁移出口

Connect Cloud 每个应用运行在单实例上，更高计划最多 32 GB 内存与 8 CPU。如果
应用需要 SSO、数据源认证、自定义域名或 SLA，请迁移到付费 Connect Cloud 计划
或自托管 Posit Connect。迁移时保留仓库 commit、`renv.lock`、`manifest.json`
与固定的上游 commit。
