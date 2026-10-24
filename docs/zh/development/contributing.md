# 贡献指南

## 开发环境

先安装固定的上游包，再从源码加载本包：

```r
remotes::install_github(
  "PuttickMacroevolution/MCMCtreeR@2330e7a9916c3929513ee217d3854be993965f6b",
  build_vignettes = FALSE
)
pkgload::load_all()
mcmctreer::run_app()
```

## 分支与合并请求

使用聚焦的分支，并在合并请求中描述用户可见的变化。保持上游包边界：不要把上游
源码复制进本仓库。如果上游缺陷影响界面，请记录规避方案并增加回归测试。

## 测试与检查

```r
pkgload::load_all()
testthat::test_local()
```

提出发布前请运行 `R CMD check --no-manual`。Lint 警告仅供参考，不应阻止正确性
修复。

## 双语文档

任何用户可见的变化都需要在同一次合并请求中更新英文与中文文档。`docs/en` 与
`docs/zh` 的标题和代码围栏必须一致。截图必须来自真实运行的应用，使用示例数据，
且不得包含本地路径或 token。

## 安全

不要提交 `.Renviron`、`~/.rsconnect`、部署 token 或上传数据。漏洞请按
`SECURITY.md` 私下报告。不要在公开 Issue 中附上可工作的利用代码。
