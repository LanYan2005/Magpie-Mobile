import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

import '../models/magpie_models.dart';

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
    AgentStatus.online => 'Online (demo)',
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
