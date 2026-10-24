# 快速开始

## 线上使用

打开
<https://zengzichao-mcmctreer-bench.share.connect.posit.cloud/>。
应用运行在 Posit Connect Cloud 的共享学术实例上。请在关闭页面之前下载产物。

## 本地使用

```r
remotes::install_github(
  "PuttickMacroevolution/MCMCtreeR@2330e7a9916c3929513ee217d3854be993965f6b",
  build_vignettes = FALSE
)
remotes::install_github("ZengZichao/MCMCtreeR-Bench")
mcmctreer::run_app()
```

## 模块 A 流程

1. **载入树**：上传文件、粘贴 Newick，或载入示例树。
2. **选择节点**：点击内部节点或选择节点编号。每次选择都会显示后代物种。
3. **标定配置**：选择分布类型并填写最小、最大年龄。`upper` 不使用最小年龄；
   `fixed` 不使用最大年龄。
4. **高级参数**：可选。留空即使用上游默认值。
5. **估计**：逐节点运行估计。面板显示每个节点的参数与先验曲线。
6. **预览与导出**：检查 `.tre` 文本，下载 `.tre` 与分布图。

## 模块 B 流程

1. 选择 MCMCtree、MrBayes、RevBayes 或 User。
2. 提供数据源并点击 **载入数据源**。
3. 调整绘图类型、时间尺、不确定性样式与外观。
4. 小数据可自动重绘；大后验请切换到手动重绘。
5. 下载 PDF、PNG 或 SVG。

## 下载产物

服务器不会在会话之间保留文件。请在关闭页面之前下载 `.tre` 文件、分布图和
时间树图。`.tre` 文本也会显示在只读文本块中；如果下载被浏览器阻止，可手动
复制。
