# 架构

## 模块布局

应用是 golem 包，包含两个 `nav_panel` 模块：

- `mod_a_wizard.R` 装配六步先验流程与常驻预览。
- `mod_b_viz.R` 装配设置侧栏、实时绘图与导出。
- 共享模块提供会话级语言、主题与导出控件。
- 纯函数处理树分组、参数组装、估计、校验、工作区、限额、错误、导出与元数据。

`app.R` 是生产入口。它用 `pkgload` 加载包，设置请求大小与错误脱敏选项，然后
调用 `run_app()`。

## 状态模型

`app_server.R` 持有一个 `reactiveValues` 对象，包含互不污染的 `a` 与 `b` 两棵
子树。所有写入都经过 `set_a()` 或 `set_b()`，并整体替换子树：

```r
a <- state$a
a$calibrated <- update_calibration(a$calibrated, node = 8, minAge = 1.5)
set_a(a)
```

直接嵌套赋值（如 `state$a$calibrated[[1]]$minAge <- 1.5`）不会使响应式消费者
失效，因此被禁止。

## 国际化与主题

语言与主题是表现层偏好，放在 `moduleServer()` 作用域，而不是 `state` 中，也不
参与结果哈希。字典是纯数据；`tr(lang, key, ...)` 是带英文回退与可见 `⟨key⟩`
标记的纯函数。界面文本按当前会话语言渲染，动态控件从状态回填，因此切换语言不会
重置用户输入。

## 会话工作区

所有用户文件位于 `tempdir()/session$token/<子目录>`。上传文件名会被安全化，在
上游需要推导兄弟文件时保留原始名称，下载路径用 `assert_in_workspace()` 校验。
整个 token 目录在 `onSessionEnded()` 中删除。

## 错误处理

预期问题使用 `app_error("key", ...)`。模块翻译键与参数。意外错误保留技术文本，
但会把 `tempdir()` 路径替换为 `<tmp>`。上游 `node.label` 长度警告被归类为已知
警告，记录日志，但不显示为失败。

## 上游规避

本界面不修改 `MCMCtreeR`。它逐节点调用 `estimateXxx()` 而不是 `MCMCtreePhy()`，
重建完整长度的 node label 向量以避免标签复制，在上游分布图守卫错误地要求 chain
时提供占位 chain，并为每次导出自行控制图形设备。
