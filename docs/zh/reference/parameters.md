# 参数参考

## 分析类型

| 界面标签 | 上游取值 | 必需输入 |
| --- | --- | --- |
| MCMCtree | `MCMCtree` | FigTree 输出，或后验表 + 树 |
| MrBayes | `MrBayes` | `.con.tre` 与 run 文件 |
| RevBayes | `RevBayes` | Nexus 与 `.trees` 文件 |
| User | `User` | 时间树与节点年龄表 |

## 模块 A 分布

| 分布类型 | 函数 | 参数 |
| --- | --- | --- |
| `cauchy` | `estimateCauchy` | `scale`、`offset`、`minProb`、`maxProb`、`estimateScale` |
| `skewT` | `estimateSkewT` | `shape`、`scale`、`df`、`addMode`、`minProb`、`maxProb`、`estimateScale`、`estimateShape`、`estimateMode` |
| `skewNormal` | `estimateSkewNormal` | `shape`、`scale`、`addMode`、`minProb`、`maxProb`、`estimateScale`、`estimateShape`、`estimateMode` |
| `gamma` | `estimateGamma` | `alpha`、`beta`、`offset`、`estimateAlpha`、`estimateBeta` |
| `bound` | `estimateBound` | `minProb`、`rightTail` |
| `upper` | `estimateUpper` | `rightTail` |
| `fixed` | `estimateFixed` | 无 |

## 模块 A 高级参数

| 参数 | 类型 | 默认值 | 范围 |
| --- | --- | --- | --- |
| `scale` | 数值 | 1.5 | > 0 |
| `offset` | 数值 | 50 或 0.1 | >= 0 |
| `shape` | 数值 | 50 | > 0 |
| `df` | 数值 | 1 | > 0 |
| `alpha` | 数值 | 188 | > 0 |
| `beta` | 数值 | 2690 | > 0 |
| `minProb` | 数值 | 0、0.003 或 0.025 | 0 到 1 |
| `maxProb` | 数值 | 0.975 | 0 到 1 |
| `rightTail` | 数值 | 0.025 | 0 到 1 |
| `addMode` | 数值 | 0 | >= 0 |
| `estimateScale` | 逻辑 | `TRUE` | `TRUE` / `FALSE` |
| `estimateShape` | 逻辑 | `FALSE` | `TRUE` / `FALSE` |
| `estimateMode` | 逻辑 | `FALSE` | `TRUE` / `FALSE` |
| `estimateAlpha` | 逻辑 | `TRUE` | `TRUE` / `FALSE` |
| `estimateBeta` | 逻辑 | `FALSE` | `TRUE` / `FALSE` |

## 模块 B 参数

| 分组 | 参数 |
| --- | --- |
| 数据源 | `analysis.type`、`MCMC.chain`、`node.ages`、`directory.files`、`build.tree` |
| 绘图类型 | `plot.type`、`all.nodes` |
| 时间尺 | `add.time.scale`、`add.abs.time`、`scale.res`、`label.timescale.names`、`grey.bars`、`relative.height`、`cex.age`、`cex.labels`、`cex.names`、`pos.age`、`abs.age.mgp`、`abs.age.lwd`、`abs.age.lwd.ticks`、`tck.abs.age`、`abs.age.line` |
| 节点不确定性 | `node.method`、`col.age`、`lwd.bar`、`tip.lengths`、`tip.bar.col`、`distribution.height`、`density.col`、`density.border.col` |
| 树外观 | `cex.tips`、`show.tip.label`、`col.tree`、`tip.color`、`ladderize.tree`、`time.correction` |
| 分析设置 | `burn.in`、`n.runs` |

## 默认值与校验

界面只保存用户显式覆盖的值。高级参数留空时会从上游调用中省略。测试套件会把每个
输出的参数名与 `formals(MCMC.tree.plot)` 逐一比对，因此拼写错误的参数不会被
函数的 `...` 静默吞掉。
