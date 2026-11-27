import 'gateway_upstream.dart';

/// Official public API base URLs and documentation sources.
/// Presets are opt-in, supply protocol and root URL, and never carry credentials.
class GatewayPreset {
  const GatewayPreset(this.provider, this.protocol, this.baseUrl, this.source);

  final String provider;
  final GatewayProtocol protocol;
  final String baseUrl;
  final String source;

  static const official = <GatewayPreset>[
    GatewayPreset(
      'OpenAI',
      GatewayProtocol.chat,
      'https://api.openai.com/v1',
      'https://platform.openai.com/docs/api-reference/chat/create',
    ),
    GatewayPreset(
      'OpenAI',
      GatewayProtocol.responses,
      'https://api.openai.com/v1',
      'https://platform.openai.com/docs/api-reference/responses/create',
    ),
    GatewayPreset(
      'OpenRouter',
      GatewayProtocol.chat,
      'https://openrouter.ai/api/v1',
      'https://openrouter.ai/docs/api/reference/overview',
    ),
    GatewayPreset(
      'OpenRouter',
      GatewayProtocol.responses,
      'https://openrouter.ai/api/v1',
      'https://openrouter.ai/docs/api/reference/overview',
    ),
    GatewayPreset(
      'Vercel AI Gateway',
      GatewayProtocol.chat,
      'https://ai-gateway.vercel.sh/v1',
      'https://vercel.com/docs/ai-gateway/sdks-and-apis/openai-chat-completions',
    ),
    GatewayPreset(
      'Vercel AI Gateway',
      GatewayProtocol.responses,
      'https://ai-gateway.vercel.sh/v1',
      'https://vercel.com/docs/ai-gateway/sdks-and-apis/responses',
    ),
    GatewayPreset(
      'Anthropic',
      GatewayProtocol.anthropic,
      'https://api.anthropic.com',
      'https://docs.anthropic.com/en/api/messages/create',
    ),
    GatewayPreset(
      'OpenRouter',
      GatewayProtocol.anthropic,
      'https://openrouter.ai/api/v1',
      'https://openrouter.ai/docs/api/reference/overview',
    ),
    GatewayPreset(
      'Vercel AI Gateway',
      GatewayProtocol.anthropic,
      'https://ai-gateway.vercel.sh/v1',
      'https://vercel.com/docs/ai-gateway/sdks-and-apis/anthropic-messages-api',
    ),
    GatewayPreset(
      'Google AI',
      GatewayProtocol.gemini,
      'https://generativelanguage.googleapis.com/v1beta',
      'https://ai.google.dev/api/generate-content',
    ),
  ];
}

enum ProviderPresetGroup { vendor, relay, local, remote }

/// Mobile catalog entries with directly compatible authentication and routes.
/// Defaults checked against yetone/magpie's MIT-licensed internal/provider/
/// presets.go at 95e6a4180866afde186e0f1a25369388c7fd7e7f. Values are roots,
/// while the gateway catalog keeps the operation URL for its route dispatcher.
class ProviderPreset {
  const ProviderPreset(
    this.id,
    this.name,
    this.group,
    this.protocol,
    this.baseUrl,
  );

  final String id;
  final String name;
  final ProviderPresetGroup group;
  final GatewayProtocol protocol;
  final String? baseUrl;

  bool get isLocal => group == ProviderPresetGroup.local;

  static const directory = <ProviderPreset>[
    ProviderPreset(
      'anthropic',
      'Anthropic',
      ProviderPresetGroup.vendor,
      GatewayProtocol.anthropic,
      'https://api.anthropic.com',
    ),
    ProviderPreset(
      'openai',
      'OpenAI',
      ProviderPresetGroup.vendor,
      GatewayProtocol.chat,
      'https://api.openai.com/v1',
    ),
    ProviderPreset(
      'google',
      'Google Gemini',
      ProviderPresetGroup.vendor,
      GatewayProtocol.gemini,
      'https://generativelanguage.googleapis.com/v1beta',
    ),
    ProviderPreset(
      'deepseek',
      'DeepSeek',
      ProviderPresetGroup.vendor,
      GatewayProtocol.chat,
      'https://api.deepseek.com/v1',
    ),
    ProviderPreset(
      'xai',
      'xAI',
      ProviderPresetGroup.vendor,
      GatewayProtocol.chat,
      'https://api.x.ai/v1',
    ),
    ProviderPreset(
      'moonshot',
      'Kimi',
      ProviderPresetGroup.vendor,
      GatewayProtocol.chat,
      'https://api.moonshot.ai/v1',
    ),
    ProviderPreset(
      'mistral',
      'Mistral',
      ProviderPresetGroup.vendor,
      GatewayProtocol.chat,
      'https://api.mistral.ai/v1',
    ),
    ProviderPreset(
      'qwen',
      'Qwen',
      ProviderPresetGroup.vendor,
      GatewayProtocol.chat,
      'https://dashscope-intl.aliyuncs.com/compatible-mode/v1',
    ),
    ProviderPreset(
      'groq',
      'Groq',
      ProviderPresetGroup.vendor,
      GatewayProtocol.chat,
      'https://api.groq.com/openai/v1',
    ),
    ProviderPreset(
      'openrouter',
      'OpenRouter',
      ProviderPresetGroup.relay,
      GatewayProtocol.chat,
      'https://openrouter.ai/api/v1',
    ),
    ProviderPreset(
      'vercel',
      'Vercel AI Gateway',
      ProviderPresetGroup.relay,
      GatewayProtocol.chat,
      'https://ai-gateway.vercel.sh/v1',
    ),
    ProviderPreset(
      'together',
      'Together AI',
      ProviderPresetGroup.relay,
      GatewayProtocol.chat,
      'https://api.together.xyz/v1',
    ),
    ProviderPreset(
      'fireworks',
      'Fireworks',
      ProviderPresetGroup.relay,
      GatewayProtocol.chat,
      'https://api.fireworks.ai/inference/v1',
    ),
    ProviderPreset(
      'siliconflow',
      'SiliconFlow',
      ProviderPresetGroup.relay,
      GatewayProtocol.chat,
      'https://api.siliconflow.cn/v1',
    ),
    ProviderPreset(
      'ollama',
      'Ollama',
      ProviderPresetGroup.local,
      GatewayProtocol.chat,
      'http://127.0.0.1:11434/v1',
    ),
    ProviderPreset(
      'lmstudio',
      'LM Studio',
      ProviderPresetGroup.local,
      GatewayProtocol.chat,
      'http://127.0.0.1:1234/v1',
    ),
    ProviderPreset(
      'remote',
      'Remote magpie',
      ProviderPresetGroup.remote,
      GatewayProtocol.chat,
      null,
    ),
  ];
}
