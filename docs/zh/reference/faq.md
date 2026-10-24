# 常见问题

## 我的数据会被上传吗？

使用线上应用时会。文件会发送到 Posit Connect Cloud 服务器，保存在会话专属临时
目录中。会话结束或实例重启后会删除。敏感数据请安装并在本地运行。

## 为什么导出被禁用？

上次估计运行后输入发生变化，或尚未运行估计。应用会对树、节点、年龄、分布与
高级参数做哈希。重新运行估计即可恢复导出。切换语言或主题不会禁用导出。

## 为什么图上的文字是英文？

绘图文字使用英文，是为了在没有 CJK 字体保证的 Linux 服务器上保持可读，并使
导出图符合常见期刊风格。界面本身完全双语。

## 为什么不能通过 MCMCtreePhy 固定 gamma alpha？

上游 `MCMCtreePhy()` 包装把数值 `alpha` 传给了逻辑参数 `estimateAlpha`，从而
强制估计 alpha。本界面直接调用 `estimateGamma()`，其中的
`estimateAlpha = FALSE` 按文档生效。

## 可以使用 BEAST2 数据吗？

0.1.0 不支持。界面暴露 MCMCtree、MrBayes、RevBayes 与 User 四种模式。固定的
上游 `MCMC.tree.plot()` 含有 BEAST2 分支，但本版本尚未验证。

## 应该如何引用？

请同时引用图形界面软件条目与原始 MCMCtreeR 论文。两条 BibTeX 均见 README 与
引用页面。上游 DOI 为 `10.1093/bioinformatics/btz554`。
