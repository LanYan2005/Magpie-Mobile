import 'package:flutter_test/flutter_test.dart';
import 'package:magpie_mobile/models/magpie_models.dart';
import 'package:magpie_mobile/state/magpie_store.dart';

void main() {
  group('MagpieStore', () {
    test('演示数据包含一个默认路由，切换时保持唯一', () {
      final store = MagpieStore();
      addTearDown(store.dispose);

      expect(
        store.providers.where((provider) => provider.isDefaultRoute),
        hasLength(1),
      );

      store.setDefaultProvider('provider-openai-gateway', true);

      final defaults = store.providers
          .where((provider) => provider.isDefaultRoute)
          .toList();
      expect(defaults, hasLength(1));
      expect(defaults.single.id, 'provider-openai-gateway');
    });

    test('可以取消默认路由', () {
      final store = MagpieStore();
      addTearDown(store.dispose);

      store.setDefaultProvider('provider-anthropic', false);

      expect(
        store.providers.where((provider) => provider.isDefaultRoute),
        isEmpty,
      );
    });

    test('新增默认供应商会替换旧默认项', () {
      final store = MagpieStore();
      addTearDown(store.dispose);

      store.upsertProvider(
        ProviderConfig(
          id: 'provider-demo-new',
          name: '演示新路由',
          kind: ProviderKind.openAiCompatible,
          endpoint: 'https://new.example.com/v1',
          health: ProviderHealth.needsSetup,
          models: const ['demo-model'],
          keyReference: '未设置',
          note: '测试数据',
          isDefaultRoute: true,
        ),
      );

      final defaults = store.providers
          .where((provider) => provider.isDefaultRoute)
          .toList();
      expect(defaults, hasLength(1));
      expect(defaults.single.id, 'provider-demo-new');
      expect(store.providers.first.id, 'provider-demo-new');
    });

    test('新增与编辑 Skill 只影响内存中的演示数据', () {
      final store = MagpieStore();
      addTearDown(store.dispose);

      final originalSkills = store.skills.length;
      store.upsertSkill(
        const SkillResource(
          id: 'skill-demo-new',
          name: 'demo-skill',
          description: '演示配置',
          origin: ResourceOrigin.local,
          version: 'v0.1',
          permissions: ['读取工作区'],
          enabled: true,
          toolCount: 1,
          instructions: '演示内容',
        ),
      );

      expect(store.skills.length, originalSkills + 1);
      expect(store.skills.first.name, 'demo-skill');

      store.upsertSkill(
        store.skills.first.copyWith(
          name: 'edited-skill',
          instructions: '更新后的演示内容',
        ),
      );

      expect(store.skills.length, originalSkills + 1);
      expect(store.skills.first.name, 'edited-skill');
      expect(store.skills.first.instructions, '更新后的演示内容');

      store.resetDemoData();

      expect(store.skills.length, originalSkills);
      expect(
        store.skills.any((skill) => skill.name == 'edited-skill'),
        isFalse,
      );
    });

    test('只有远程 HTTP(S) MCP 进入导出列表', () {
      final store = MagpieStore();
      addTearDown(store.dispose);

      expect(
        store.remoteMcpServers.every((server) => server.transport.isRemote),
        isTrue,
      );
      expect(
        store.remoteMcpServers.any((server) => server.name == 'github'),
        isTrue,
      );
      expect(
        store.remoteMcpServers.any((server) => server.name == 'filesystem'),
        isFalse,
      );
    });
  });
}
