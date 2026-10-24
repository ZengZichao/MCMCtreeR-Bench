# 安装

## 环境要求

- R 4.1 或更高版本。
- 图形界面本身不需要编译工具链，但 `ape`、`data.table`、`ragg` 与 `svglite`
  可能根据平台需要二进制或源码安装。
- 首次安装需要联网。安装完成后，应用本身可在本地运行。

## 安装固定的上游包

`MCMCtreeR` 已从 CRAN 归档。请安装 MCMCtreeR Bench 测试所用的官方 GitHub commit：

```r
remotes::install_github(
  "PuttickMacroevolution/MCMCtreeR@2330e7a9916c3929513ee217d3854be993965f6b",
  build_vignettes = FALSE,
  upgrade = "never"
)
```

检查元数据：

```r
stopifnot(packageDescription("MCMCtreeR")$RemoteType == "github")
stopifnot(startsWith(packageDescription("MCMCtreeR")$RemoteSha, "2330e7a"))
```

## 安装图形界面

```r
remotes::install_github("ZengZichao/MCMCtreeR-Bench")
mcmctreer::run_app()
```

从源码目录运行时：

```r
pkgload::load_all()
mcmctreer::run_app()
```

## 可复现还原

存在 `renv.lock` 时，先还原依赖库：

```r
renv::restore()
```

锁文件记录的上游 `MCMCtreeR` commit 必须与 `DESCRIPTION` 的 `Remotes` 一致。
只有在能访问 GitHub 的环境中才重新生成锁文件。

## 为什么 install.packages() 会失败

`install.packages("MCMCtreeR")` 会向 CRAN 请求一个已归档的包，并返回 404 类
错误。请使用固定的 GitHub commit 或经过验证的镜像。MCMCtreeR Bench 不会在运行期安装
任何包。

## 常见安装问题

- **提示找不到 `MCMCtreeR`**：先安装上游 commit；本界面不内置上游源码。
- **Posit Connect Cloud 报 `Unsupported R version`**：改用平台支持的 R 版本，再重新生成
  `renv.lock`。
- **`ragg` 或 `svglite` 编译失败**：它们是声明依赖，但应用仍可启动。PNG 会退回
  `grDevices::png(type = "cairo")`，SVG 在 Cairo 可用时退回
  `grDevices::svg()`。若平台无法编译，请安装二进制包。
- **无法访问 GitHub**：从本地源码安装并手动记录 commit；不要把 CRAN URL 写进
  `renv.lock`。
