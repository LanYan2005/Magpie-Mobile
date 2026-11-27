import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

import '../gateway/gateway_controller.dart';
import '../models/magpie_models.dart';

/// The order is shared by the top bar, sidebar, and page stack.
enum MagpieSection {
  agents,
  sessions,
  resources,
  artifacts,
  providers,
  routing,
  routingGroups,
  gateway,
  usage,
  redaction,
  plugins,
}

/// App chrome follows the same locale as Material and Cupertino controls.
class MagpieL10n {
  const MagpieL10n(this.locale);

  static const chinese = Locale('zh');
  static const english = Locale('en');
  static const supportedLocales = [chinese, english];
  static const delegate = _MagpieL10nDelegate();

  final Locale locale;

  bool get isEnglish => locale.languageCode == 'en';

  String text(String zh, String en) => isEnglish ? en : zh;

  String navigationLabel(MagpieSection section) => switch (section) {
    MagpieSection.agents => 'Agent',
    MagpieSection.sessions => text('会话', 'Sessions'),
    MagpieSection.resources => text('资源库', 'Library'),
    MagpieSection.artifacts => 'Artifacts',
    MagpieSection.providers => text('供应商', 'Providers'),
    MagpieSection.routing => text('路由', 'Routing'),
    MagpieSection.routingGroups => text('路由组', 'Routing groups'),
    MagpieSection.gateway => text('网关', 'Gateway'),
    MagpieSection.usage => text('用量', 'Usage'),
    MagpieSection.redaction => text('脱敏', 'Redaction'),
    MagpieSection.plugins => text('插件', 'Plugins'),
  };

  String get navigationTitle => text('栏目', 'Sections');
  String get showSidebar => text('显示侧栏', 'Show sidebar');
  String get hideSidebar => text('收起侧栏', 'Hide sidebar');
  String get closeSidebar => text('关闭侧栏', 'Close sidebar');
  String get settingsTool => text('设置', 'Settings');
  String get notImplemented => text('尚未实现', 'Not implemented yet');
  String get gatewayListener => text('本机监听器', 'Local listener');
  String get gatewayDescription => text(
    '查看并控制当前应用进程中的本机监听器。状态来自实际网关控制器。',
    'View and control the local listener in this app process. Status comes from the live gateway controller.',
  );

  String gatewayIssue(GatewayIssue issue) => switch (issue) {
    GatewayIssue.invalidUpstream => text(
      '填写符合协议的 HTTPS 端点，或其他端口上的 HTTP 127.0.0.1。移除 URL 中的凭据、查询参数和片段。',
      'Use a matching HTTPS endpoint, or HTTP 127.0.0.1 on another port. Remove URL credentials, queries and fragments.',
    ),
    GatewayIssue.invalidApiKey => text(
      '密钥格式无效，或配置字段含有密钥。',
      'The key is invalid or appears in a configuration field.',
    ),
    GatewayIssue.invalidProvider => text(
      '请检查名称、端点或模型清单的格式与长度。',
      'Check the format and length of names, endpoints and model IDs.',
    ),
    GatewayIssue.invalidImport => text(
      '导入失败。请选择无凭据的 Magpie 移动端供应商 JSON（版本 1）。',
      'Import failed. Select a Magpie Mobile provider JSON file (version 1) without credentials.',
    ),
    GatewayIssue.catalogLoadFailed => text(
      '供应商配置读取失败。原始配置已保留，修改已暂停。',
      'The provider catalog could not be read. The original is preserved and editing is paused.',
    ),
    GatewayIssue.migrationFailed => text(
      '旧上游迁移失败。原始配置已保留，修改已暂停。仍可使用已读取的旧路由。',
      'Legacy migration failed. The original settings are preserved and editing is paused. Readable legacy routes remain available.',
    ),
    GatewayIssue.credentialFailed => text(
      '系统凭据存储写入失败。请重试。',
      'Could not write to system credential storage. Try again.',
    ),
    GatewayIssue.saveFailed => text(
      '保存供应商配置失败。请重试。',
      'Could not save the provider settings. Try again.',
    ),
    GatewayIssue.missingUpstream => text(
      '请先为启用的供应商选择网关账号。',
      'Select a gateway account from an enabled provider first.',
    ),
    GatewayIssue.portInUse => text(
      '端口 3425 已被占用。',
      'Port 3425 is already in use.',
    ),
    GatewayIssue.startFailed => text(
      '监听 127.0.0.1:3425 失败。',
      'Could not listen on 127.0.0.1:3425.',
    ),
    GatewayIssue.listenerEnded => text(
      '本机监听已意外结束。',
      'The local listener ended unexpectedly.',
    ),
  };

  String? sectionUnavailable(MagpieSection section) => switch (section) {
    MagpieSection.sessions => text(
      '移动端尚未接入 Agent 会话或会话历史。',
      'Agent sessions and their history are not available on mobile yet.',
    ),
    MagpieSection.routing => text(
      '规则路由尚未实现。可在「供应商」为每种协议选择一个网关账号。',
      'Routing rules are not implemented yet. Select a gateway account for each protocol in Providers.',
    ),
    MagpieSection.artifacts => text(
      '移动端尚未接入 Artifacts 查看与运行。',
      'Artifact browsing and execution are not available on mobile yet.',
    ),
    MagpieSection.routingGroups => text(
      '路由组管理尚未接入移动端。',
      'Routing group management is not available on mobile yet.',
    ),
    MagpieSection.usage => text(
      '当前网关不收集或展示用量统计。',
      'The current gateway does not collect or display usage statistics.',
    ),
    MagpieSection.redaction => text(
      '本机网关尚未实现请求脱敏。',
      'Request redaction is not implemented in the local gateway yet.',
    ),
    MagpieSection.plugins => text(
      '移动端尚未接入插件安装或运行。',
      'Plugin installation and execution are not available on mobile yet.',
    ),
    _ => null,
  };

  String providerKind(ProviderKind kind) => text(kind.label, switch (kind) {
    ProviderKind.anthropic => kind.label,
    ProviderKind.openAiCompatible => kind.label,
    ProviderKind.gemini => kind.label,
    ProviderKind.ollama => 'Local Ollama',
    ProviderKind.aggregator => 'Routing aggregator',
  });

  String providerKindShort(ProviderKind kind) =>
      text(kind.shortLabel, switch (kind) {
        ProviderKind.openAiCompatible => 'OpenAI-compatible',
        ProviderKind.aggregator => 'Aggregator',
        _ => kind.shortLabel,
      });

  String providerHealth(ProviderHealth health) =>
      text(health.label, switch (health) {
        ProviderHealth.online => 'Online',
        ProviderHealth.needsSetup => 'Needs setup',
        ProviderHealth.offline => 'Offline',
      });

  String agentStatus(AgentStatus status) => text(status.label, switch (status) {
    AgentStatus.online => 'Not connected to Magpie',
    AgentStatus.needsSetup => 'Needs setup',
    AgentStatus.paused => 'Paused',
  });

  String agentRuntimeName(AgentRuntime runtime) => runtime.label;

  String agentRuntimeSubtitle(AgentRuntime runtime) =>
      text(runtime.subtitle, switch (runtime) {
        AgentRuntime.claudeCode => 'Anthropic terminal coding Agent',
        AgentRuntime.codex => 'OpenAI coding Agent',
        AgentRuntime.geminiCli => 'Google terminal Agent',
        AgentRuntime.openAiCompatible => 'Custom compatible endpoint',
      });

  String agentRuntimeDescription(AgentRuntime runtime) =>
      text(runtime.description, switch (runtime) {
        AgentRuntime.claudeCode =>
          'Suited to long-context code changes and tool use.',
        AgentRuntime.codex =>
          'Focuses on code generation, refactoring, and command execution.',
        AgentRuntime.geminiCli =>
          'Suited to multimodal inputs and long documents.',
        AgentRuntime.openAiCompatible =>
          'Use a self-hosted gateway, LiteLLM, or a private model.',
      });

  String agentAccess(AgentAccess access) => text(access.label, switch (access) {
    AgentAccess.localCli => 'Local CLI',
    AgentAccess.ssh => 'Remote SSH',
    AgentAccess.termux => 'Persistent Termux',
    AgentAccess.httpBridge => 'HTTP bridge',
  });

  String agentAccessBlurb(AgentAccess access) =>
      text(access.blurb, switch (access) {
        AgentAccess.localCli => 'Run the Agent from a local terminal.',
        AgentAccess.ssh => 'Connect to a remote development machine via SSH.',
        AgentAccess.termux =>
          'Keep the Agent running in an Android user-space terminal.',
        AgentAccess.httpBridge =>
          'Forward through a local or remote HTTP gateway.',
      });

  String agentAccessFieldLabel(AgentAccess access) =>
      text(access.fieldLabel, switch (access) {
        AgentAccess.localCli => 'Working directory',
        AgentAccess.ssh => 'SSH target',
        AgentAccess.termux => 'Local port',
        AgentAccess.httpBridge => 'Bridge URL',
      });

  String agentAccessFieldHint(AgentAccess access) =>
      text(access.fieldHint, switch (access) {
        AgentAccess.localCli => 'e.g. ~/work/magpie',
        AgentAccess.ssh => 'e.g. builder@build.example.com:22',
        AgentAccess.termux => 'e.g. 127.0.0.1:8787',
        AgentAccess.httpBridge => 'e.g. http://127.0.0.1:8090',
      });

  String resourceOrigin(ResourceOrigin origin) =>
      text(origin.label, switch (origin) {
        ResourceOrigin.bundled => 'Bundled',
        ResourceOrigin.local => 'Local',
        ResourceOrigin.remote => 'Remote',
      });

  String mcpTransportSubtitle(McpTransport transport) =>
      text(transport.subtitle, switch (transport) {
        McpTransport.stdio => 'Local process',
        McpTransport.sse => transport.subtitle,
        McpTransport.streamableHttp => 'Remote HTTP',
      });

  String mcpStatus(McpStatus status) => text(status.label, switch (status) {
    McpStatus.connected => 'Connected',
    McpStatus.needsSetup => 'Needs setup',
    McpStatus.offline => 'Not started',
  });

  String reference(String value) => text(value, switch (value) {
    '未设置' => 'Not set',
    '无需密钥' => 'No key required',
    _ => value,
  });

  List<String> permissions(List<String> values) => isEnglish
      ? [for (final value in values) _permissionLabels[value] ?? value]
      : values;

  static const _permissionLabels = {
    '工作区读写': 'Workspace read/write',
    '命令执行': 'Run commands',
    '网络访问': 'Network access',
    '读取工作区': 'Read workspace',
    '生成报告': 'Generate reports',
    '生成文件': 'Generate files',
    '文件读写': 'File read/write',
    '文件读取': 'Read files',
    '浏览器控制': 'Browser control',
    '受限目录读写': 'Read/write scoped folders',
    '仓库只读': 'Read-only repository access',
    '工具调用（待确认）': 'Tool calls (pending approval)',
  };
}

class _MagpieL10nDelegate extends LocalizationsDelegate<MagpieL10n> {
  const _MagpieL10nDelegate();

  @override
  bool isSupported(Locale locale) => MagpieL10n.supportedLocales.any(
    (item) => item.languageCode == locale.languageCode,
  );

  @override
  Future<MagpieL10n> load(Locale locale) =>
      SynchronousFuture(MagpieL10n(locale));

  @override
  bool shouldReload(_MagpieL10nDelegate old) => false;
}

extension MagpieLocalizationContext on BuildContext {
  MagpieL10n get l10n => Localizations.of<MagpieL10n>(this, MagpieL10n)!;

  String tr(String zh, String en) => l10n.text(zh, en);
}
