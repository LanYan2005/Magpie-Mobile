import '../core/magpie_l10n.dart';
import '../models/magpie_models.dart';

part 'demo_localization.dart';

/// 所有内容均为界面演示数据。端点使用 example.com / localhost 占位，
/// 不包含 API 凭据，也不会发起真实网络请求。
abstract final class DemoData {
  static const providers = <ProviderConfig>[
    ProviderConfig(
      id: 'provider-anthropic',
      name: 'Anthropic 官方',
      kind: ProviderKind.anthropic,
      endpoint: 'https://api.example.com/v1',
      health: ProviderHealth.online,
      models: ['claude-sonnet-5', 'claude-opus-5', 'claude-haiku-5'],
      keyReference: 'env:ANTHROPIC_API_KEY',
      note: '主路由。演示端点，不包含真实密钥。',
      latencyMs: 42,
      isDefaultRoute: true,
    ),
    ProviderConfig(
      id: 'provider-openai-gateway',
      name: 'OpenAI 兼容网关',
      kind: ProviderKind.openAiCompatible,
      endpoint: 'https://gateway.example.com/v1',
      health: ProviderHealth.online,
      models: ['gpt-5.1', 'gpt-5-mini', 'o4'],
      keyReference: 'env:OPENAI_API_KEY',
      note: '用于兼容 OpenAI Chat Completions 的模型。',
      latencyMs: 68,
    ),
    ProviderConfig(
      id: 'provider-gemini',
      name: 'Gemini CLI',
      kind: ProviderKind.gemini,
      endpoint: 'https://generativelanguage.example.com',
      health: ProviderHealth.needsSetup,
      models: ['gemini-2.5-pro', 'gemini-2.5-flash'],
      keyReference: '未设置',
      note: '等待补充密钥引用与默认模型。',
    ),
    ProviderConfig(
      id: 'provider-ollama',
      name: '本地 Ollama',
      kind: ProviderKind.ollama,
      endpoint: 'http://127.0.0.1:11434',
      health: ProviderHealth.offline,
      models: ['qwen3:8b', 'llama3.3:8b'],
      keyReference: '无需密钥',
      note: '离线演示项，不会探测本机端口。',
    ),
    ProviderConfig(
      id: 'provider-openrouter',
      name: 'OpenRouter',
      kind: ProviderKind.aggregator,
      endpoint: 'https://openrouter.ai/api/v1',
      health: ProviderHealth.online,
      models: ['anthropic/claude-sonnet', 'google/gemini', 'openai/gpt'],
      keyReference: 'env:OPENROUTER_API_KEY',
      note: '聚合路由，用于多模型回退。',
      latencyMs: 96,
    ),
    ProviderConfig(
      id: 'provider-litellm',
      name: '自建 LiteLLM',
      kind: ProviderKind.openAiCompatible,
      endpoint: 'https://litellm.demo.local/v1',
      health: ProviderHealth.needsSetup,
      models: ['team-default'],
      keyReference: '未设置',
      note: '团队内网占位配置，未接入真实地址。',
    ),
  ];

  static const agents = <AgentConfig>[
    AgentConfig(
      id: 'agent-claude',
      name: 'Claude Code',
      runtime: AgentRuntime.claudeCode,
      access: AgentAccess.localCli,
      endpoint: '~/work/magpie',
      model: 'claude-sonnet-5',
      status: AgentStatus.online,
      permissions: ['工作区读写', '命令执行'],
      note: '主力编码 Agent，保留人工确认步骤。',
    ),
    AgentConfig(
      id: 'agent-codex',
      name: 'Codex',
      runtime: AgentRuntime.codex,
      access: AgentAccess.ssh,
      endpoint: 'builder@build.example.com:22',
      model: 'gpt-5-codex',
      status: AgentStatus.needsSetup,
      permissions: ['工作区读写'],
      note: '远程构建机占位配置，尚未验证连接。',
    ),
    AgentConfig(
      id: 'agent-gemini',
      name: 'Gemini CLI',
      runtime: AgentRuntime.geminiCli,
      access: AgentAccess.termux,
      endpoint: '127.0.0.1:8787',
      model: 'gemini-2.5-pro',
      status: AgentStatus.online,
      permissions: ['工作区读写', '网络访问'],
      note: 'Android 上的 Termux 常驻示例。',
    ),
    AgentConfig(
      id: 'agent-bridge',
      name: '本地模型桥',
      runtime: AgentRuntime.openAiCompatible,
      access: AgentAccess.httpBridge,
      endpoint: 'http://127.0.0.1:8090',
      model: 'local-model',
      status: AgentStatus.paused,
      permissions: ['网络访问'],
      note: '用于接入自建 OpenAI-compatible 服务。',
    ),
  ];

  static const skills = <SkillResource>[
    SkillResource(
      id: 'skill-code-review',
      name: 'code-review',
      description: '按风险等级审阅改动，输出可执行的修复清单。',
      origin: ResourceOrigin.local,
      version: 'v2.1',
      permissions: ['读取工作区', '生成报告'],
      enabled: true,
      toolCount: 3,
      instructions:
          '1. 先阅读改动范围与相关文件。\n'
          '2. 按「正确性 / 安全性 / 可维护性」分组列出问题。\n'
          '3. 每条问题给出文件位置与可执行的修复建议。\n'
          '（以上为演示内容，仅在本机编辑，不会执行。）',
    ),
    SkillResource(
      id: 'skill-frontend-design',
      name: 'frontend-design',
      description: '为移动端界面提供版式、层级与视觉方向建议。',
      origin: ResourceOrigin.local,
      version: 'v1.4',
      permissions: ['读取工作区', '生成文件'],
      enabled: true,
      toolCount: 5,
      instructions:
          '1. 先确认目标平台与信息层级。\n'
          '2. 给出一套可落地的版式与组件建议。\n'
          '3. 标出需要真实数据才能验证的部分。\n'
          '（以上为演示内容，仅在本机编辑，不会执行。）',
    ),
    SkillResource(
      id: 'skill-docx',
      name: 'docx',
      description: '创建、读取与修订 Word 文档，保留基础样式。',
      origin: ResourceOrigin.bundled,
      version: 'v3.0',
      permissions: ['文件读写'],
      enabled: true,
      toolCount: 4,
      instructions: '内置演示 Skill：展示文档处理类 Skill 的配置形态。',
    ),
    SkillResource(
      id: 'skill-pdf',
      name: 'pdf',
      description: '合并、拆分与提取 PDF 文本，适合交付前检查。',
      origin: ResourceOrigin.bundled,
      version: 'v2.2',
      permissions: ['文件读取'],
      enabled: false,
      toolCount: 6,
      instructions: '内置演示 Skill：当前已暂停，不会执行任何文件操作。',
    ),
    SkillResource(
      id: 'skill-webapp-testing',
      name: 'webapp-testing',
      description: '驱动浏览器完成页面巡检与关键路径回归。',
      origin: ResourceOrigin.remote,
      version: 'v1.8',
      permissions: ['浏览器控制', '网络访问'],
      enabled: true,
      toolCount: 3,
      instructions: '远程演示 Skill：仅展示权限声明，本原型不会发起浏览器或网络请求。',
    ),
    SkillResource(
      id: 'skill-creator',
      name: 'skill-creator',
      description: '从流程说明生成新的 Skill 骨架与验收提示。',
      origin: ResourceOrigin.local,
      version: 'v1.1',
      permissions: ['工作区读写'],
      enabled: true,
      toolCount: 2,
      instructions: '1. 汇总目标与输入输出。\n2. 生成 Skill 骨架。\n3. 附带验收清单。\n（演示内容。）',
    ),
  ];

  static const mcpServers = <McpServerConfig>[
    McpServerConfig(
      id: 'mcp-filesystem',
      name: 'filesystem',
      description: 'stdio 配置示例：只记录启动命令，不在 Android/iOS 上运行。',
      transport: McpTransport.stdio,
      remote: false,
      status: McpStatus.offline,
      endpoint: 'stdio://workspace',
      permissions: ['受限目录读写'],
      toolCount: 8,
      enabled: false,
      authReference: '无需密钥',
    ),
    McpServerConfig(
      id: 'mcp-github',
      name: 'github',
      description: '远程 HTTP 配置示例：可编辑参数并导出清单，尚未握手。',
      transport: McpTransport.streamableHttp,
      remote: true,
      status: McpStatus.needsSetup,
      endpoint: 'https://mcp.example.com/github',
      permissions: ['仓库只读'],
      toolCount: 24,
      enabled: true,
      authReference: 'env:GITHUB_TOKEN',
    ),
    McpServerConfig(
      id: 'mcp-playwright',
      name: 'playwright',
      description: 'stdio 配置示例：仅保存本地进程参数，不启动进程。',
      transport: McpTransport.stdio,
      remote: false,
      status: McpStatus.offline,
      endpoint: 'stdio://playwright',
      permissions: ['浏览器控制'],
      toolCount: 12,
      enabled: false,
      authReference: '无需密钥',
    ),
  ];

  static const activities = <ActivityEvent>[
    ActivityEvent(
      title: 'Anthropic 路由同步完成',
      detail: '3 个模型 · 演示响应 42 ms',
      time: '刚刚',
      tone: ActivityTone.provider,
    ),
    ActivityEvent(
      title: 'Skill「code-review」已启用',
      detail: '本地资源 · 仅更新界面状态',
      time: '12 分钟前',
      tone: ActivityTone.resource,
    ),
    ActivityEvent(
      title: '远程 MCP 握手（演示）',
      detail: 'github · Streamable HTTP',
      time: '1 小时前',
      tone: ActivityTone.gateway,
    ),
    ActivityEvent(
      title: 'Agent「Claude Code」配置已更新',
      detail: '接入方式：本机 CLI',
      time: '昨天 18:40',
      tone: ActivityTone.agent,
    ),
  ];

  static List<ActivityEvent> localizedActivity(MagpieL10n l10n) =>
      l10n.isEnglish ? _englishActivities : activities;

  static const _englishActivities = [
    ActivityEvent(
      title: 'Anthropic route synced',
      detail: '3 models · Demo response: 42 ms',
      time: 'Just now',
      tone: ActivityTone.provider,
    ),
    ActivityEvent(
      title: 'Skill “code-review” enabled',
      detail: 'Local resource · UI state updated only',
      time: '12 min ago',
      tone: ActivityTone.resource,
    ),
    ActivityEvent(
      title: 'Remote MCP handshake (demo)',
      detail: 'github · Streamable HTTP',
      time: '1 hr ago',
      tone: ActivityTone.gateway,
    ),
    ActivityEvent(
      title: 'Agent “Claude Code” settings updated',
      detail: 'Access: Local CLI',
      time: 'Yesterday 18:40',
      tone: ActivityTone.agent,
    ),
  ];
}
