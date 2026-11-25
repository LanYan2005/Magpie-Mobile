part of 'demo_data.dart';

// Only unchanged fixture fields are translated. Edits and identifiers stay as entered.
String _fixtureText<T>(
  Iterable<T> fixtures,
  String id,
  String value,
  String Function(T) getId,
  String Function(T) getField,
  Map<String, String> translations,
  MagpieL10n l10n,
) {
  if (!l10n.isEnglish) return value;
  for (final fixture in fixtures) {
    if (getId(fixture) == id && getField(fixture) == value) {
      return translations[id] ?? value;
    }
  }
  return value;
}

extension ProviderDemoLocalization on ProviderConfig {
  String localizedName(MagpieL10n l10n) => _fixtureText(
    DemoData.providers,
    id,
    name,
    (p) => p.id,
    (p) => p.name,
    const {
      'provider-anthropic': 'Anthropic Official',
      'provider-openai-gateway': 'OpenAI-compatible Gateway',
      'provider-ollama': 'Local Ollama',
      'provider-litellm': 'Self-hosted LiteLLM',
    },
    l10n,
  );

  String localizedNote(MagpieL10n l10n) => _fixtureText(
    DemoData.providers,
    id,
    note,
    (p) => p.id,
    (p) => p.note,
    const {
      'provider-anthropic':
          'Primary route. Demo endpoint; no real credentials.',
      'provider-openai-gateway':
          'For models compatible with OpenAI Chat Completions.',
      'provider-gemini': 'Waiting for a key reference and default model.',
      'provider-ollama': 'Offline demo. No local ports are probed.',
      'provider-openrouter': 'Routing aggregator for multi-model fallback.',
      'provider-litellm':
          'Placeholder for a private team endpoint. Not connected.',
    },
    l10n,
  );
}

extension AgentDemoLocalization on AgentConfig {
  String localizedName(MagpieL10n l10n) => _fixtureText(
    DemoData.agents,
    id,
    name,
    (a) => a.id,
    (a) => a.name,
    const {'agent-bridge': 'Local Model Bridge'},
    l10n,
  );

  String localizedNote(MagpieL10n l10n) => _fixtureText(
    DemoData.agents,
    id,
    note,
    (a) => a.id,
    (a) => a.note,
    const {
      'agent-claude':
          'Primary coding Agent. Manual confirmation stays in place.',
      'agent-codex':
          'Placeholder for a remote build machine. Connection not verified.',
      'agent-gemini': 'Example of persistent Termux access on Android.',
      'agent-bridge': 'For a self-hosted OpenAI-compatible service.',
    },
    l10n,
  );
}

extension SkillDemoLocalization on SkillResource {
  String localizedDescription(MagpieL10n l10n) => _fixtureText(
    DemoData.skills,
    id,
    description,
    (s) => s.id,
    (s) => s.description,
    const {
      'skill-code-review':
          'Review changes by severity and produce a list of actionable fixes.',
      'skill-frontend-design':
          'Suggest layouts, hierarchy, and visual direction for mobile interfaces.',
      'skill-docx':
          'Create, read, and revise Word documents while preserving basic styles.',
      'skill-pdf':
          'Merge or split PDFs and extract text for pre-delivery checks.',
      'skill-webapp-testing':
          'Use a browser to check pages and test key flows for regressions.',
      'skill-creator':
          'Turn a workflow description into a Skill scaffold and acceptance checklist.',
    },
    l10n,
  );

  String localizedInstructions(MagpieL10n l10n) => _fixtureText(
    DemoData.skills,
    id,
    instructions,
    (s) => s.id,
    (s) => s.instructions,
    const {
      'skill-code-review':
          '1. Review the scope of the changes and related files.\n'
          '2. Group findings by correctness, security, and maintainability.\n'
          '3. Include a file location and actionable fix for each finding.\n'
          '(Demo content. Edited locally and never executed.)',
      'skill-frontend-design':
          '1. Confirm the target platform and information hierarchy.\n'
          '2. Suggest practical layouts and components.\n'
          '3. Identify what needs real data to verify.\n'
          '(Demo content. Edited locally and never executed.)',
      'skill-docx':
          'Bundled demo Skill: shows how a document-processing Skill is configured.',
      'skill-pdf':
          'Bundled demo Skill: currently paused. No file operations are executed.',
      'skill-webapp-testing':
          'Remote demo Skill: shows declared permissions only. The prototype makes no browser or network requests.',
      'skill-creator':
          '1. Summarize the goal, inputs, and outputs.\n'
          '2. Generate a Skill scaffold.\n'
          '3. Include an acceptance checklist.\n(Demo content.)',
    },
    l10n,
  );
}

/// Descriptions supplied by the app when an optional MCP description is empty.
const mcpStdioDemoDescription = 'stdio 配置示例：仅保存参数，不启动进程。';
const mcpRemoteDemoDescription = '远程 HTTP 配置示例：仅保存参数，不发起连接。';

extension McpDemoLocalization on McpServerConfig {
  String localizedDescription(MagpieL10n l10n) => switch (description) {
    mcpStdioDemoDescription => l10n.text(
      description,
      'stdio demo: stores settings without starting a process.',
    ),
    mcpRemoteDemoDescription => l10n.text(
      description,
      'Remote HTTP demo: stores settings without connecting.',
    ),
    _ => _fixtureText(
      DemoData.mcpServers,
      id,
      description,
      (s) => s.id,
      (s) => s.description,
      const {
        'mcp-filesystem':
            'stdio demo: records the launch command without running it on Android/iOS.',
        'mcp-github':
            'Remote HTTP demo: settings can be edited and exported. No handshake yet.',
        'mcp-playwright':
            'stdio demo: stores local process settings without starting a process.',
      },
      l10n,
    ),
  };
}
