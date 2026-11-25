import 'package:flutter/widgets.dart';

import '../data/demo_data.dart';
import '../models/magpie_models.dart';

class MagpieStore extends ChangeNotifier {
  MagpieStore() {
    _loadDemoData();
  }

  final List<ProviderConfig> _providers = [];
  final List<AgentConfig> _agents = [];
  final List<SkillResource> _skills = [];
  final List<McpServerConfig> _mcpServers = [];
  int _nextId = 1;

  List<ProviderConfig> get providers => List.unmodifiable(_providers);
  List<AgentConfig> get agents => List.unmodifiable(_agents);
  List<SkillResource> get skills => List.unmodifiable(_skills);
  List<McpServerConfig> get mcpServers => List.unmodifiable(_mcpServers);

  int get onlineProviderCount => _providers
      .where((provider) => provider.health == ProviderHealth.online)
      .length;
  int get providersNeedingSetup => _providers
      .where((provider) => provider.health != ProviderHealth.online)
      .length;
  int get onlineAgentCount =>
      _agents.where((agent) => agent.status == AgentStatus.online).length;
  int get enabledSkillCount => _skills.where((skill) => skill.enabled).length;
  int get connectedMcpCount =>
      _mcpServers.where((server) => server.enabled).length;
  int get remoteMcpCount =>
      _mcpServers.where((server) => server.transport.isRemote).length;
  List<McpServerConfig> get remoteMcpServers => List.unmodifiable(
    _mcpServers.where((server) => server.transport.isRemote),
  );

  String newId(String prefix) {
    final id = '$prefix-demo-${DateTime.now().microsecondsSinceEpoch}-$_nextId';
    _nextId += 1;
    return id;
  }

  void addProvider(ProviderConfig provider) {
    upsertProvider(provider);
  }

  void upsertProvider(ProviderConfig provider) {
    if (provider.isDefaultRoute) {
      _clearDefaultRoute();
    }
    final index = _providers.indexWhere((item) => item.id == provider.id);
    if (index == -1) {
      _providers.insert(0, provider);
    } else {
      _providers[index] = provider;
    }
    notifyListeners();
  }

  void setDefaultProvider(String id, bool isDefault) {
    final index = _providers.indexWhere((provider) => provider.id == id);
    if (index == -1) {
      return;
    }
    if (isDefault) {
      _clearDefaultRoute();
    }
    _providers[index] = _providers[index].copyWith(isDefaultRoute: isDefault);
    notifyListeners();
  }

  void _clearDefaultRoute() {
    for (var i = 0; i < _providers.length; i++) {
      if (_providers[i].isDefaultRoute) {
        _providers[i] = _providers[i].copyWith(isDefaultRoute: false);
      }
    }
  }

  void removeProvider(String id) {
    _providers.removeWhere((provider) => provider.id == id);
    notifyListeners();
  }

  void addAgent(AgentConfig agent) {
    _agents.insert(0, agent);
    notifyListeners();
  }

  void upsertAgent(AgentConfig agent) {
    final index = _agents.indexWhere((item) => item.id == agent.id);
    if (index == -1) {
      _agents.insert(0, agent);
    } else {
      _agents[index] = agent;
    }
    notifyListeners();
  }

  void toggleSkill(String id, bool enabled) {
    final index = _skills.indexWhere((skill) => skill.id == id);
    if (index == -1) {
      return;
    }
    _skills[index] = _skills[index].copyWith(enabled: enabled);
    notifyListeners();
  }

  void upsertSkill(SkillResource skill) {
    final index = _skills.indexWhere((item) => item.id == skill.id);
    if (index == -1) {
      _skills.insert(0, skill);
    } else {
      _skills[index] = skill;
    }
    notifyListeners();
  }

  void addMcpServer(McpServerConfig server) {
    upsertMcpServer(server);
  }

  void upsertMcpServer(McpServerConfig server) {
    final index = _mcpServers.indexWhere((item) => item.id == server.id);
    if (index == -1) {
      _mcpServers.insert(0, server);
    } else {
      _mcpServers[index] = server;
    }
    notifyListeners();
  }

  void toggleMcp(String id, bool enabled) {
    final index = _mcpServers.indexWhere((server) => server.id == id);
    if (index == -1) {
      return;
    }
    _mcpServers[index] = _mcpServers[index].copyWith(enabled: enabled);
    notifyListeners();
  }

  void resetDemoData() {
    _loadDemoData();
    notifyListeners();
  }

  void _loadDemoData() {
    _providers
      ..clear()
      ..addAll(DemoData.providers);
    _agents
      ..clear()
      ..addAll(DemoData.agents);
    _skills
      ..clear()
      ..addAll(DemoData.skills);
    _mcpServers
      ..clear()
      ..addAll(DemoData.mcpServers);
  }
}

class MagpieScope extends InheritedNotifier<MagpieStore> {
  const MagpieScope({
    required MagpieStore store,
    required super.child,
    super.key,
  }) : super(notifier: store);

  static MagpieStore of(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<MagpieScope>();
    assert(scope != null, 'MagpieScope was not found in the widget tree.');
    return scope!.notifier!;
  }
}
