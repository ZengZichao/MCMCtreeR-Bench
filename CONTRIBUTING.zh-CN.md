# 贡献指南

## 开发环境

安装固定的上游包，并从源码加载本包：

```r
remotes::install_github(
  "PuttickMacroevolution/MCMCtreeR@2330e7a9916c3929513ee217d3854be993965f6b",
  build_vignettes = FALSE
)
pkgload::load_all()
mcmctreer::run_app()
```

## 分支与合并请求

- 使用聚焦的分支。
- 描述用户可见的变化以及覆盖它的测试。
- 不要把 `MCMCtreeR` 源码复制进本仓库；使用固定的 `Remotes` 依赖。
- 如果上游缺陷需要界面规避，请记录并增加回归测试。

## 测试与检查

```r
pkgload::load_all()
testthat::test_local()
```

发布前运行 `R CMD check --no-manual`。Lint 结果仅供参考；正确性修复不应被风格
警告阻塞。

## 双语文档

在同一次合并请求中更新 `docs/en` 与 `docs/zh`。标题与代码围栏必须一致。截图
必须来自真实运行的应用，且不得包含本地路径、token 或私有数据。

## 安全

不要提交 `.Renviron`、`~/.rsconnect`、部署 token 或上传数据。漏洞请按
`SECURITY.md` 私下报告。
