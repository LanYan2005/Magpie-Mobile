# Magpie Mobile

Magpie 的非官方 Android / iOS 界面原型，使用 Flutter 构建。不是上游项目发布的客户端，也没有接入其 Go 核心。 / An unofficial Flutter prototype inspired by [Magpie](https://github.com/yetone/magpie), not an official client.

## 当前范围

- 设置中可切换简体中文和 English，偏好会保留。部分演示文案尚未完全翻译。
- 概览页的本机 HTTP 网关为真实功能：手动启动后只监听 IPv4 `127.0.0.1:3425`。支持 Chat Completions、Responses、Anthropic Messages/token counting、Gemini generate/stream/countTokens、System One 五种独立同协议转发；Chat 与 Responses 地址是各自完整端点，Anthropic 与 System One 也是完整端点，Gemini 使用版本 API 根地址并按模型和操作构造路径。支持 JSON 与 SSE 流式字节透传，不实现协议互译。
- 每种协议的上游地址和认证需求独立保存在应用偏好设置；供应商 API 密钥只保存在当前应用进程内存中，需在每次进程启动后重新输入。本机客户端密钥是独立随机启动令牌，可通过协议支持的认证头发送，Gemini 也支持 `key` 查询参数。停止网关或退出进程后该令牌失效；网关不会自动启动。客户端请求不可指定上游；拒绝带 Origin 的请求、重定向和超限请求体。
- Android 应用声明 `INTERNET` 权限以监听和访问已配置的上游。网关在应用进程内运行，Android 挂起/结束应用或系统回收进程时服务会中断；没有前台服务或开机自启。
- iOS 的监听仅在应用进程运行时有效，应用进入后台后不承诺继续服务，也没有后台常驻能力。
- 供应商页直接显示本机网关的五种协议及各自上游配置，包括未配置的协议。Agent 和资源库仍使用本地演示数据；内部供应商示例不参与网关转发。Skills 和 MCP 支持演示管理与导出预览；不写入导出文件，不启动本地 stdio 进程，不访问其他 App 的私有目录。没有接入原版 Magpie Go 核心。

## 启动和调用本机网关

在“供应商”页直接点击对应协议，填写上游地址和所需的供应商 API 密钥，再到“概览”手动启动。每种协议仅支持一个上游，不支持多账号或账号池；未配置的协议不会回退到其他上游。地址必须为 HTTPS，或其他端口上的 HTTP `127.0.0.1`；Chat/Responses/Anthropic/System One 填写完整端点，Gemini 填写版本化根地址（如 `/v1beta`）。配置变更须停止网关后保存。运行状态下概览显示本次启动的随机本机客户端密钥（与供应商密钥无关）。仅将本机密钥交给同机客户端，不要放入共享日志或截图。网关不做跨协议转换、用户路由或模型发现，也不提供工具或 CLI 运行时。

```sh
# 健康检查
curl -H 'Authorization: Bearer TOKEN' http://127.0.0.1:3425/health

# Chat Completions / Responses / System One：Bearer 本机客户端密钥
curl http://127.0.0.1:3425/v1/chat/completions \
  -H 'Authorization: Bearer TOKEN' -H 'Content-Type: application/json' \
  -d '{"model":"MODEL","messages":[{"role":"user","content":"你好"}],"stream":true}'

# Anthropic Messages：可用 x-api-key 本机客户端密钥
curl http://127.0.0.1:3425/v1/messages \
  -H 'x-api-key: TOKEN' -H 'anthropic-version: 2023-06-01' \
  -H 'Content-Type: application/json' -d '{"model":"MODEL","max_tokens":128,"messages":[{"role":"user","content":"你好"}]}'

# Gemini：本机客户端密钥只用于 key 参数；供应商密钥单独以 x-goog-api-key 发往上游
curl 'http://127.0.0.1:3425/v1beta/models/MODEL:streamGenerateContent?alt=sse&key=TOKEN' \
  -H 'Content-Type: application/json' -d '{"contents":[{"parts":[{"text":"你好"}]}]}'
```

它只在运行中的应用进程内可用，绑定 IPv4 loopback，不接受 LAN 连接。停止按钮关闭监听。HTTPS 上游 TLS 校验保持启用；转发器不会跟随重定向，也不把客户端认证头、任意头部或本机访问凭据传给上游。上游凭据不会持久化，成功响应正文中的字面回显会遮蔽；错误响应细节会压制。Anthropic 兼容性取决于上游要求：当前仅转发 `anthropic-version` 和格式校验后的 `anthropic-beta`，未配置 workspace id 的 UI。

## 本地运行

使用 Flutter 3.38.9（Dart 3.10.8）。Android 建议使用 JDK 17、Android SDK Platform 36；iOS 需要 macOS 和 Xcode，尚未完成真机验证。

```sh
flutter pub get
flutter run
flutter analyze
flutter test
```

首次 Android 构建时 Flutter 会补齐本地 Gradle Wrapper 文件。此仓库不包含签名材料或本机 SDK 配置。

## 图标来源

桌面和应用内图标由 [上游 Magpie SVG](https://github.com/yetone/magpie/blob/95e6a4180866afde186e0f1a25369388c7fd7e7f/build/icon/magpie.svg) 适配生成。参见 [图标说明](assets/brand/README.md) 和 [上游 MIT 许可及版权声明](THIRD_PARTY_NOTICES.md)。名称与标志仅用于说明项目来源，不代表上游认可或官方发布。
