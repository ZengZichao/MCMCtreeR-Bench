# 部署到 Posit Connect Cloud

## 凭据

在 R 会话中完成一次授权：

```r
rsconnect::connectCloudUser()
rsconnect::accounts()
```

在非交互环境中，创建 Connect Cloud 凭据并注册，无需浏览器流程。客户端密钥
必须放在仓库之外：

```r
rsconnect::connectCloudClientCredentials(
  clientId = Sys.getenv("CONNECT_CLOUD_CLIENT_ID"),
  clientSecret = Sys.getenv("CONNECT_CLOUD_CLIENT_SECRET"),
  accountName = Sys.getenv("CONNECT_CLOUD_ACCOUNT")
)
```

账户保存在 `~/.rsconnect/connect.posit.cloud/`，不会写入本仓库。服务器名为
`connect.posit.cloud`。

## 创建应用

部署脚本首次运行时会创建内容，之后复用同一内容。Free 计划允许五个应用。

| 用途 | 公开地址 |
| --- | --- |
| staging | 由同一脚本以独立内容名创建 |
| production | <https://zengzichao-mcmctreer-bench.share.connect.posit.cloud/> |

两个内容均为公开。Connect Cloud 当前使用 R 4.6.1 构建，与 `renv.lock`
一致；平台升级后请在内容设置中确认运行时。

## 部署

```bash
CONNECT_CLOUD_APP=mcmctreer-gui-staging Rscript dev/deploy.R
CONNECT_CLOUD_APP=mcmctreer-gui Rscript dev/deploy.R
```

`dev/deploy.R` 会检查账户、运行测试、核对 bundle 与部署记录，然后调用
`rsconnect::deployApp()`，传入 `server = "connect.posit.cloud"`、
`manifestPath = "manifest.json"` 与 `appVisibility = "public"`。显式使用仓库中的
manifest 是有意为之：即使本地库不完整，也能保留固定到 GitHub commit 的
`MCMCtreeR` 以及 `ragg`/`svglite` 依赖。

## 查看日志

部署时使用 `logLevel = "verbose"` 可实时查看 bundle、安装与运行日志。失败信息
也会出现在内容页的 revision 历史中：

```r
rsconnect::deployApp(
  appDir = ".", manifestPath = "manifest.json",
  appName = "mcmctreer-gui", account = "zengzichao",
  server = "connect.posit.cloud", appVisibility = "public",
  launch.browser = FALSE, forceUpdate = TRUE, logLevel = "verbose"
)
```

重点检查依赖安装失败、找不到固定的 `MCMCtreeR` commit 以及 Shiny 启动错误。
首次部署安装依赖时不要中断。

## URL

Connect Cloud 为每个 revision 提供
`https://[content-id].share.connect.posit.cloud`，管理页为
`https://connect.posit.cloud/[account]/content/[content-id]`。自定义名称可把
content ID 替换为 `[account]-[name]`；本仓库以上述默认地址为准。

## Bundle 规则

`.rscignore` 是 bundle 的权威清单。它排除 `dev/`、`tests/`、`man/`、`docs/`、
`mkdocs.yml`、`.github/`、`renv/`、`.Rprofile`、`rsconnect/`、`README*`、
`CONTRIBUTING*`、`CODE_OF_CONDUCT*`、`SECURITY*`、`CITATION.cff` 与 `site/`。
它不能排除 `app.R`、`DESCRIPTION`、`NAMESPACE`、`R/`、`inst/`、`renv.lock`
或 `manifest.json`。

每次发布前用以下命令核对，并把 bundle 控制在 30 MB 以内：

```r
files <- rsconnect::listDeploymentFiles(".")
length(files)
sum(file.info(files)$size) / 1024^2
```
