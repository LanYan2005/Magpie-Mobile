import 'gateway_upstream.dart';

/// Official public API endpoints, not inferred from compatibility labels.
/// Presets are opt-in per route and never carry credentials.
class GatewayPreset {
  const GatewayPreset(this.provider, this.protocol, this.endpoint, this.source);

  final String provider;
  final GatewayProtocol protocol;
  final String endpoint;
  final String source;

  static const official = <GatewayPreset>[
    GatewayPreset(
      'OpenAI',
      GatewayProtocol.chat,
      'https://api.openai.com/v1/chat/completions',
      'https://platform.openai.com/docs/api-reference/chat/create',
    ),
    GatewayPreset(
      'OpenAI',
      GatewayProtocol.responses,
      'https://api.openai.com/v1/responses',
      'https://platform.openai.com/docs/api-reference/responses/create',
    ),
    GatewayPreset(
      'OpenRouter',
      GatewayProtocol.chat,
      'https://openrouter.ai/api/v1/chat/completions',
      'https://openrouter.ai/docs/api/reference/overview',
    ),
    GatewayPreset(
      'OpenRouter',
      GatewayProtocol.responses,
      'https://openrouter.ai/api/v1/responses',
      'https://openrouter.ai/docs/api/reference/overview',
    ),
    GatewayPreset(
      'Vercel AI Gateway',
      GatewayProtocol.chat,
      'https://ai-gateway.vercel.sh/v1/chat/completions',
      'https://vercel.com/docs/ai-gateway/sdks-and-apis/openai-chat-completions',
    ),
    GatewayPreset(
      'Vercel AI Gateway',
      GatewayProtocol.responses,
      'https://ai-gateway.vercel.sh/v1/responses',
      'https://vercel.com/docs/ai-gateway/sdks-and-apis/responses',
    ),
    GatewayPreset(
      'Anthropic',
      GatewayProtocol.anthropic,
      'https://api.anthropic.com/v1/messages',
      'https://docs.anthropic.com/en/api/messages/create',
    ),
    GatewayPreset(
      'OpenRouter',
      GatewayProtocol.anthropic,
      'https://openrouter.ai/api/v1/messages',
      'https://openrouter.ai/docs/api/reference/overview',
    ),
    GatewayPreset(
      'Vercel AI Gateway',
      GatewayProtocol.anthropic,
      'https://ai-gateway.vercel.sh/v1/messages',
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
