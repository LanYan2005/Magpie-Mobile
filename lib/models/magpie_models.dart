enum ProviderKind {
  anthropic('Anthropic API', 'Anthropic'),
  openAiCompatible('OpenAI-compatible', 'OpenAI 兼容'),
  gemini('Google Gemini', 'Gemini'),
  ollama('本地 Ollama', 'Ollama'),
  aggregator('聚合路由', '聚合');

  const ProviderKind(this.label, this.shortLabel);

  final String label;
  final String shortLabel;
}

enum ProviderHealth {
  online('在线'),
  needsSetup('需配置'),
  offline('离线');

  const ProviderHealth(this.label);

  final String label;
}

class ProviderConfig {
  const ProviderConfig({
    required this.id,
    required this.name,
    required this.kind,
    required this.endpoint,
    required this.health,
    required this.models,
    required this.keyReference,
    required this.note,
    this.latencyMs,
    this.isDefaultRoute = false,
  });

  final String id;
  final String name;
  final ProviderKind kind;
  final String endpoint;
  final ProviderHealth health;
  final List<String> models;
  final String keyReference;
  final String note;
  final int? latencyMs;
  final bool isDefaultRoute;

  ProviderConfig copyWith({
    String? name,
    ProviderKind? kind,
    String? endpoint,
    ProviderHealth? health,
    List<String>? models,
    String? keyReference,
    String? note,
    int? latencyMs,
    bool? isDefaultRoute,
  }) {
    return ProviderConfig(
      id: id,
      name: name ?? this.name,
      kind: kind ?? this.kind,
      endpoint: endpoint ?? this.endpoint,
      health: health ?? this.health,
      models: models ?? this.models,
      keyReference: keyReference ?? this.keyReference,
      note: note ?? this.note,
      latencyMs: latencyMs ?? this.latencyMs,
      isDefaultRoute: isDefaultRoute ?? this.isDefaultRoute,
    );
  }
}

enum AgentRuntime {
  claudeCode('Claude Code', 'Anthropic 的终端编码 Agent', '擅长长上下文代码修改与工具调用。'),
  codex('Codex', 'OpenAI 编码 Agent', '偏重代码生成、重构与命令执行。'),
  geminiCli('Gemini CLI', 'Google 终端 Agent', '适合多模态资料与长文档工作流。'),
  openAiCompatible('OpenAI-compatible', '自定义兼容端点', '接入自建网关、LiteLLM 或私有模型。');

  const AgentRuntime(this.label, this.subtitle, this.description);

  final String label;
  final String subtitle;
  final String description;
}

enum AgentAccess {
  localCli('本机 CLI', '在本机终端直接启动 Agent。', '工作目录', '例如 ~/work/magpie'),
  ssh('SSH 远程', '通过 SSH 连接远端开发机。', 'SSH 目标', '例如 builder@build.example.com:22'),
  termux('Termux 常驻', '在 Android 用户空间终端中常驻。', '本地端口', '例如 127.0.0.1:8787'),
  httpBridge(
    'HTTP 桥接',
    '通过本地或远程 HTTP 网关转发。',
    '桥接地址',
    '例如 http://127.0.0.1:8090',
  );

  const AgentAccess(this.label, this.blurb, this.fieldLabel, this.fieldHint);

  final String label;
  final String blurb;
  final String fieldLabel;
  final String fieldHint;
}

enum AgentStatus {
  online('演示在线'),
  needsSetup('待配置'),
  paused('已暂停');

  const AgentStatus(this.label);

  final String label;
}

class AgentConfig {
  const AgentConfig({
    required this.id,
    required this.name,
    required this.runtime,
    required this.access,
    required this.endpoint,
    required this.model,
    required this.status,
    required this.permissions,
    required this.note,
  });

  final String id;
  final String name;
  final AgentRuntime runtime;
  final AgentAccess access;
  final String endpoint;
  final String model;
  final AgentStatus status;
  final List<String> permissions;
  final String note;

  AgentConfig copyWith({
    String? name,
    AgentRuntime? runtime,
    AgentAccess? access,
    String? endpoint,
    String? model,
    AgentStatus? status,
    List<String>? permissions,
    String? note,
  }) {
    return AgentConfig(
      id: id,
      name: name ?? this.name,
      runtime: runtime ?? this.runtime,
      access: access ?? this.access,
      endpoint: endpoint ?? this.endpoint,
      model: model ?? this.model,
      status: status ?? this.status,
      permissions: permissions ?? this.permissions,
      note: note ?? this.note,
    );
  }
}

enum ResourceOrigin {
  bundled('内置'),
  local('本地'),
  remote('远程');

  const ResourceOrigin(this.label);

  final String label;
}

class SkillResource {
  const SkillResource({
    required this.id,
    required this.name,
    required this.description,
    required this.origin,
    required this.version,
    required this.permissions,
    required this.enabled,
    required this.toolCount,
    this.instructions = '',
  });

  final String id;
  final String name;
  final String description;
  final ResourceOrigin origin;
  final String version;
  final List<String> permissions;
  final bool enabled;
  final int toolCount;

  /// 演示内容：仅保存在 Magpie 的演示会话中，不会被读取或执行。
  final String instructions;

  SkillResource copyWith({
    String? name,
    String? description,
    ResourceOrigin? origin,
    String? version,
    List<String>? permissions,
    bool? enabled,
    int? toolCount,
    String? instructions,
  }) {
    return SkillResource(
      id: id,
      name: name ?? this.name,
      description: description ?? this.description,
      origin: origin ?? this.origin,
      version: version ?? this.version,
      permissions: permissions ?? this.permissions,
      enabled: enabled ?? this.enabled,
      toolCount: toolCount ?? this.toolCount,
      instructions: instructions ?? this.instructions,
    );
  }
}

enum McpTransport {
  stdio('stdio', '本地进程'),
  sse('SSE', 'Server-Sent Events'),
  streamableHttp('Streamable HTTP', '远程 HTTP');

  const McpTransport(this.label, this.subtitle);

  final String label;
  final String subtitle;
}

extension McpTransportKind on McpTransport {
  /// stdio 只保存配置，不在 Android/iOS 上启动本地进程。
  bool get isStdio => this == McpTransport.stdio;

  /// 只有远程 HTTP(S) / SSE 配置参与导出。
  bool get isRemote => !isStdio;
}

enum McpStatus {
  connected('已连接'),
  needsSetup('待配置'),
  offline('未启动');

  const McpStatus(this.label);

  final String label;
}

class McpServerConfig {
  const McpServerConfig({
    required this.id,
    required this.name,
    required this.description,
    required this.transport,
    required this.remote,
    required this.status,
    required this.endpoint,
    required this.permissions,
    required this.toolCount,
    required this.enabled,
    required this.authReference,
  });

  final String id;
  final String name;
  final String description;
  final McpTransport transport;
  final bool remote;
  final McpStatus status;
  final String endpoint;
  final List<String> permissions;
  final int toolCount;
  final bool enabled;
  final String authReference;

  McpServerConfig copyWith({
    String? name,
    String? description,
    McpTransport? transport,
    bool? remote,
    McpStatus? status,
    String? endpoint,
    List<String>? permissions,
    int? toolCount,
    bool? enabled,
    String? authReference,
  }) {
    return McpServerConfig(
      id: id,
      name: name ?? this.name,
      description: description ?? this.description,
      transport: transport ?? this.transport,
      remote: remote ?? this.remote,
      status: status ?? this.status,
      endpoint: endpoint ?? this.endpoint,
      permissions: permissions ?? this.permissions,
      toolCount: toolCount ?? this.toolCount,
      enabled: enabled ?? this.enabled,
      authReference: authReference ?? this.authReference,
    );
  }
}

enum ActivityTone { gateway, provider, agent, resource }

class ActivityEvent {
  const ActivityEvent({
    required this.title,
    required this.detail,
    required this.time,
    required this.tone,
  });

  final String title;
  final String detail;
  final String time;
  final ActivityTone tone;
}
