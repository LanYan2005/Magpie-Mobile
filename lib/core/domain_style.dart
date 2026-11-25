import 'package:flutter/material.dart';

import '../core/magpie_theme.dart';
import '../models/magpie_models.dart';

IconData providerIcon(ProviderKind kind) {
  return switch (kind) {
    ProviderKind.anthropic => Icons.graphic_eq_rounded,
    ProviderKind.openAiCompatible => Icons.hub_outlined,
    ProviderKind.gemini => Icons.auto_awesome_outlined,
    ProviderKind.ollama => Icons.dns_outlined,
    ProviderKind.aggregator => Icons.alt_route_rounded,
  };
}

Color providerAccent(BuildContext context, ProviderKind kind) {
  return switch (kind) {
    ProviderKind.anthropic => context.magpie.amber,
    ProviderKind.openAiCompatible => context.magpie.jade,
    ProviderKind.gemini => context.magpie.cobalt,
    ProviderKind.ollama => context.magpie.inkSoft,
    ProviderKind.aggregator => context.magpie.violet,
  };
}

Color providerSoft(BuildContext context, ProviderKind kind) {
  return switch (kind) {
    ProviderKind.anthropic => context.magpie.amberSoft,
    ProviderKind.openAiCompatible => context.magpie.mintSoft,
    ProviderKind.gemini => context.magpie.cobaltSoft,
    ProviderKind.ollama => context.magpie.canvas,
    ProviderKind.aggregator => context.magpie.violetSoft,
  };
}

Color healthColor(BuildContext context, ProviderHealth health) {
  return switch (health) {
    ProviderHealth.online => context.magpie.jade,
    ProviderHealth.needsSetup => context.magpie.amber,
    ProviderHealth.offline => context.magpie.muted,
  };
}

Color healthBackground(BuildContext context, ProviderHealth health) {
  return switch (health) {
    ProviderHealth.online => context.magpie.mintSoft,
    ProviderHealth.needsSetup => context.magpie.amberSoft,
    ProviderHealth.offline => context.magpie.canvas,
  };
}

IconData agentIcon(AgentRuntime runtime) {
  return switch (runtime) {
    AgentRuntime.claudeCode => Icons.auto_awesome_rounded,
    AgentRuntime.codex => Icons.code_rounded,
    AgentRuntime.geminiCli => Icons.diamond_outlined,
    AgentRuntime.openAiCompatible => Icons.hub_outlined,
  };
}

Color agentAccent(BuildContext context, AgentRuntime runtime) {
  return switch (runtime) {
    AgentRuntime.claudeCode => context.magpie.clay,
    AgentRuntime.codex => context.magpie.jade,
    AgentRuntime.geminiCli => context.magpie.cobalt,
    AgentRuntime.openAiCompatible => context.magpie.violet,
  };
}

Color agentSoft(BuildContext context, AgentRuntime runtime) {
  return switch (runtime) {
    AgentRuntime.claudeCode => context.magpie.claySoft,
    AgentRuntime.codex => context.magpie.mintSoft,
    AgentRuntime.geminiCli => context.magpie.cobaltSoft,
    AgentRuntime.openAiCompatible => context.magpie.violetSoft,
  };
}

Color agentStatusColor(BuildContext context, AgentStatus status) {
  return switch (status) {
    AgentStatus.online => context.magpie.jade,
    AgentStatus.needsSetup => context.magpie.amber,
    AgentStatus.paused => context.magpie.muted,
  };
}

Color agentStatusBackground(BuildContext context, AgentStatus status) {
  return switch (status) {
    AgentStatus.online => context.magpie.mintSoft,
    AgentStatus.needsSetup => context.magpie.amberSoft,
    AgentStatus.paused => context.magpie.canvas,
  };
}

Color originColor(BuildContext context, ResourceOrigin origin) {
  return switch (origin) {
    ResourceOrigin.bundled => context.magpie.cobalt,
    ResourceOrigin.local => context.magpie.jade,
    ResourceOrigin.remote => context.magpie.amber,
  };
}

Color originBackground(BuildContext context, ResourceOrigin origin) {
  return switch (origin) {
    ResourceOrigin.bundled => context.magpie.cobaltSoft,
    ResourceOrigin.local => context.magpie.mintSoft,
    ResourceOrigin.remote => context.magpie.amberSoft,
  };
}

Color mcpStatusColor(BuildContext context, McpStatus status) {
  return switch (status) {
    McpStatus.connected => context.magpie.jade,
    McpStatus.needsSetup => context.magpie.amber,
    McpStatus.offline => context.magpie.muted,
  };
}

Color mcpStatusBackground(BuildContext context, McpStatus status) {
  return switch (status) {
    McpStatus.connected => context.magpie.mintSoft,
    McpStatus.needsSetup => context.magpie.amberSoft,
    McpStatus.offline => context.magpie.canvas,
  };
}
