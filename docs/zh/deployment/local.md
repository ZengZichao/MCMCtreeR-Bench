# 本地部署

## 安装依赖

```r
remotes::install_github(
  "PuttickMacroevolution/MCMCtreeR@2330e7a9916c3929513ee217d3854be993965f6b",
  build_vignettes = FALSE
)
remotes::install_github("ZengZichao/MCMCtreeR-Bench")
```

## 启动应用

已安装包时：

```r
mcmctreer::run_app()
```

从源码目录运行时：

```r
pkgload::load_all()
mcmctreer::run_app()
```

## 运行测试

```r
pkgload::load_all()
testthat::test_local()
```

测试覆盖标定构造、估计、绘图参数、会话工作区、限额、导出、双语键对齐、文档
对齐以及应用冒烟流程。

## 生产模式检查

```r
shiny::runApp(".", port = 7788, launch.browser = FALSE)
```

这会加载根目录 `app.R`，通过 `pkgload` 加载包，启用生产选项，并启动与
Posit Connect Cloud 相同的服务器。部署前请检查首屏、示例流程、上传与下载。
