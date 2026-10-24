# 安全策略

## 支持版本

0.1.0 接收安全修复。更早的开发快照不受支持。

## 报告漏洞

请发送邮件至 <zengzichao@sjtu.edu.cn>，内容包括：

- 问题简述；
- 复现步骤；
- 受影响版本与部署方式（本地或 Posit Connect Cloud）；
- 建议的缓解措施。

不要在公开 Issue 中附上可工作的利用代码、用户数据或部署凭据。您应在合理的
学术维护窗口内收到确认。本项目不提供赏金或 SLA。

## 范围

相关报告包括路径穿越、跨会话数据泄漏、不安全文件处理、渲染 HTML 注入、依赖
来源篡改与凭据泄露。本应用不运行 MCMCtree/PAML，也不接收认证数据。

## 部署凭据

交互使用时，Connect Cloud 凭据保存在 `~/.rsconnect/connect.posit.cloud/`。
CI 环境请把 `CONNECT_CLOUD_CLIENT_ID` 与 `CONNECT_CLOUD_CLIENT_SECRET` 放入
Secret 存储。任一 secret 泄露时，请在 Posit 账户设置中删除该凭据、创建新凭据、
重新注册，并重新部署 staging。
