# Magpie Mobile — 整体 UI 重构计划

更新于 2026-11-26。目标：把 Flutter 端整体视觉与信息架构对齐 `yetone/magpie` 桌面 GUI。

## 一、基准

上游固定提交 **`6346f3835092400206f330ddf4a4fe1eaef1dc73`**（2026-11-26 拉取，main 头）。

- `internal/gui/assets/app.css`（484 KB）— 设计令牌与全部组件样式
- `internal/gui/assets/app.js`（1.35 MB）— 渲染逻辑与交互
- `internal/gui/assets/index.html`（54 KB）— 页面骨架与导航
- `internal/gui/assets/i18n.js`（2.6 MB）— 中英文案

研究时读取了固定提交中的样式、页面结构和文案。可直接查看[上游 GUI 源码](https://github.com/yetone/magpie/tree/6346f3835092400206f330ddf4a4fe1eaef1dc73/internal/gui/assets)。

**与原实现的差距**：原 Flutter 版用的是自创的「玉色/松绿」视觉（`jade #0E725C` + 22px 大圆角 + 大字号 32/36）。上游实际是**中性灰底 + 靛蓝 accent（`#4f46e5`）+ 12px 列表圆角 + 紧凑 13/11.5px 字号**。这不是修修补补，是换一套设计语言，所以要整体重写。

## 二、设计令牌（从 app.css 逐值核对）

### 色板

| 令牌 | 浅色 | 深色 | 用途 |
|---|---|---|---|
| `--bg` | `#f4f4f6` | `#1a1a1e` | 页面底色 |
| `--card` | `#ffffff` | `#232327` | 列表/卡片 |
| `--card-2` | `#f9f9fb` | `#1f1f23` | 展开的编辑器 |
| `--pill` | `#f1f1f4` | `#2d2d33` | 字段按钮底 |
| `--pill-hover` | `#e9e9ee` | `#36363d` | 字段悬停 |
| `--line` | `#e3e3e8` | `#333339` | 列表边框 |
| `--line-2` | `#ececf0` | `#2c2c32` | 行间分隔 |
| `--fg` | `#1c1c21` | `#ededf1` | 主文字 |
| `--fg-2` | `#4b4b53` | `#b9b9c1` | 次级文字 |
| `--muted` | `#85858d` | `#9c9ca6` | 说明文字 |
| `--faint` | `#b9b9c2` | `#90909a` | 最弱文字 |
| `--ctl-fg` | `#63636b` | `#a1a1aa` | 控件静默文字 |
| `--accent` | `#4f46e5` | `#a5b4fc` | 主色 |
| `--accent-soft` | `#eeedfd` | `#2b2c47` | 主色浅底 |
| `--accent-fg` | `#ffffff` | `#14142a` | 主色上的文字 |
| `--sel` | `#ecebfb` | `#33345a` | 选中底 |
| `--green` | `#189a58` | `#6fd99b` | 成功/在线 |
| `--green-soft` | `#e4f6ec` | `#1e3a2b` | |
| `--red` | `#d64545` | `#f28b82` | 失败/危险 |
| `--red-soft` | `#fbe9e9` | `#45272a` | |
| `--amber` | `#b45309` | `#f2b544` | 警告 |
| `--amber-soft` | `#fbf0df` | `#3f3220` | |

### 度量

- 圆角：列表 `12`、字段 `6`、分段 `8`、徽标 `4`、弹层 `12`、编辑器 `10`
- 行高：`min-height: 40`（紧凑）/ `48`（宽松），`padding: 5px 9px 5px 11px`，`gap: 9`
- 字号：基准 `14`（移动端）、行名 `13`/字重 500、行说明 `11.5`、徽标 `9.5` 大写、字段 `12.5`
- 移动端（`body.web`）：图标点按区 `44×44`、底栏 `50.5px + safe-area`、导航图标 `23`、标签 `10.5`
- 字体：`-apple-system, "SF Pro Text", "Segoe UI", system-ui`

## 三、信息架构（对齐上游导航）

上游 11 项、4 组：

```
使用 (Work)     Agent · 会话 · 资源库 · Artifacts
模型 (Models)   供应商 · 路由 · 路由组 · 网关
观测 (Insights)  用量 · 脱敏
扩展 (Extend)   插件
```

重构前 Flutter 有 9 个未分组的栏目。本轮按上游调整栏目顺序与分组，并加入 `Artifacts` 和 `路由组`。缺少运行时能力的页面显示明确说明。

Flutter 端沿用 700 逻辑像素作为断点。窄屏采用紧凑顶栏与五项底栏，完整栏目在抽屉中。宽屏采用分组停靠侧栏，折叠后可用横向栏目切换。

## 四、执行阶段

### Phase 0 — 地基（主线完成，subAgent 依赖）

- [x] 恢复工作区编译，将网关回归迁至供应商目录 API。
- [x] 更新 `lib/core/magpie_theme.dart` 的浅深色主题、圆角和字号。
- [x] 新增 `MagpieList`、`MagpieRow`、`MagpieField`、`MagpieBadge` 和 `MagpieSegmented`。开关沿用 Flutter 的平台适配控件。
- [x] 在 `lib/core/magpie_tokens.dart` 定义共享设计令牌。

### Phase 1 — 页面并行重写（5 个 subAgent 并行，互不重叠）

| Agent | 负责文件 | 内容 |
|---|---|---|
| **A 壳层** | `screens/app_shell.dart` | 分组侧栏 + 底部 tab 栏；顶部 46px 紧凑头 + 品牌 + 导航；11 项 4 组；选中态 `--sel`；宽窄切换 |
| **B Agent 页** | `screens/agents_page.dart`、`agent_editor_page.dart` | 紧凑列表行（图标/名称+版本/接入状态/模型 pill/开关）；展开面板；底部「显示其余 / 管理」 |
| **C 供应商页** | `screens/providers_page.dart`、`provider_detail_page.dart`、`provider_editor_page.dart`、`gateway_routes_page.dart` | 按供应商分行（品牌/域名/模型数/关联 Agent/账号状态/开关/详情）；详情里放协议配置；搜索与选择模式 |
| **D 资源库** | `screens/resources_page.dart`、`widgets/sheets.dart` | 二级栏目「技能 / MCP 服务器」；列表工具区、行结构、开关、导出预览 |
| **E 设置/网关** | `screens/settings_page.dart`、`gateway_page.dart`、`overview_page.dart` | 设置分页（通用/用量/网络/模型/隐私/插件/关于）；网关页状态卡与启停；概览并入网关 |

每个 Agent 只改自己那组文件，共享层（theme / primitives / tokens / l10n）由主线先写完并冻结，避免写冲突。若确需新增共享组件，先报给主线，不自行动手。

### Phase 2 — 收口（主线）

- [x] 格式化改动并运行 `flutter analyze --no-pub`，无问题
- [x] `flutter test --no-pub`，38 项通过
- [x] 响应式测试覆盖 320 / 390 / 1024，验证导航、焦点和旋转后的状态保持
- [x] 更新 `THIRD_PARTY_NOTICES.md` 的上游源码引用
- [x] 记录已知差异。移动端网关按协议选用一个账号，不使用账户池或跨协议转换。插件运行时和用量统计尚未接入。

## 五、验收口径

1. **视觉**：色板、圆角、字号、行高与上表逐值一致；无残留松绿/大圆角。
2. **结构**：11 个栏目 4 组，顺序与上游一致；手机底栏、宽屏侧栏。
3. **行为**：每个可见控件都有真实响应或明确的「移动端不支持」说明，不出现点击无反馈的假按钮。
4. **回归**：`analyze` 0 issue、`test` 全通过、三宽度走查通过。

## 六、检查点

- **基础与页面改造已落地。** 工作区恢复编译。主线完成共享主题、紧凑组件和导航壳层，接入供应商批量启停、账号名称隐藏与 JSON 导入。并行完成 Agent、供应商、资源库、设置和网关页面，以及对应回归测试。
- **移动端适配。** 宽屏侧栏分四组、提供 11 个入口。手机底栏固定 5 个常用入口，抽屉提供全部 11 个入口。Agent 暂无版本发现、更新或系统接入能力。资源库当前支持技能和 MCP 的管理与导出预览。会话、Artifacts、规则路由、路由组、用量、脱敏和插件页显示能力说明。
- **验证结果。** 图标替换后 `flutter analyze` 无问题，62 项测试通过。回归覆盖 320、390、1024 三种宽度、文字缩放、语言切换、供应商配置和真实网关启停。`git diff --check` 通过，Android 调试包构建成功。
- **供应商功能差异。** 自动检测协议尚未接入，自定义供应商需手动选择 API 类型。System One 目前只能手动填写模型 ID，暂不支持获取模型和测试模型。
- **图标。** 主导航、标题栏和供应商页优先使用上游 Magpie 图标。供应商目录与可明确识别的服务使用上游品牌标志，其他服务使用上游通用图标。部分操作按钮仍使用 Flutter Material 图标。来源与许可证见 [THIRD_PARTY_NOTICES.md](../THIRD_PARTY_NOTICES.md)。
- **待验收。** 逐页截图与上游视觉对照、Android 文件选择器真机验证、iOS 构建与真机验证。
