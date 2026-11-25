import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:magpie_mobile/app.dart';

void main() {
  Future<void> pumpApp(WidgetTester tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(const MagpieApp());
    await tester.pumpAndSettle();
  }

  Future<void> openResources(WidgetTester tester) async {
    await tester.tap(find.byKey(const ValueKey('nav-resources')));
    await tester.pumpAndSettle();
  }

  Future<void> openMcpTab(WidgetTester tester) async {
    await tester.tap(find.byKey(const ValueKey('resource-tab-mcp')));
    await tester.pumpAndSettle();
  }

  testWidgets('Skills 页只提供 Magpie 内管理与演示导出', (tester) async {
    await pumpApp(tester);
    await openResources(tester);

    expect(find.text('只做管理与导出'), findsOneWidget);
    expect(find.text('新增 Skill'), findsOneWidget);
    expect(find.text('导出清单'), findsOneWidget);
    expect(find.text('导入 Skill'), findsNothing);
    expect(find.text('Skills 只保存在本机演示会话'), findsOneWidget);
    expect(find.textContaining('不读取或写入其他 App 的私有目录'), findsWidgets);
  });

  testWidgets('新增 stdio MCP 只保存配置，不启动进程', (tester) async {
    await pumpApp(tester);
    await openResources(tester);
    await openMcpTab(tester);

    await tester.tap(find.byKey(const ValueKey('add-mcp-button')));
    await tester.pumpAndSettle();
    expect(find.text('新增 MCP 配置'), findsWidgets);

    await tester.enterText(
      find.byKey(const ValueKey('mcp-name-field')),
      'stdio-demo',
    );
    await tester.tap(find.byKey(const ValueKey('mcp-transport-stdio')));
    await tester.pumpAndSettle();
    expect(find.text('stdio 在 Android/iOS 上只管理配置'), findsOneWidget);
    expect(find.textContaining('不会启动本地进程'), findsOneWidget);

    await tester.enterText(
      find.byKey(const ValueKey('mcp-endpoint-field')),
      'npx -y demo-server',
    );
    await tester.ensureVisible(find.byKey(const ValueKey('save-mcp-button')));
    await tester.tap(find.byKey(const ValueKey('save-mcp-button')));
    await tester.pumpAndSettle();

    expect(find.text('stdio-demo'), findsOneWidget);
    expect(find.text('本地 · 仅配置'), findsWidgets);
    expect(find.text('不在 Android/iOS 启动'), findsWidgets);
    expect(find.text('未启动'), findsWidgets);
    expect(find.textContaining('不会运行进程'), findsOneWidget);
  });

  testWidgets('远程 MCP 地址必须是 HTTP(S)，并只导出远程配置', (tester) async {
    await pumpApp(tester);
    await openResources(tester);
    await openMcpTab(tester);

    await tester.tap(find.byKey(const ValueKey('add-mcp-button')));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const ValueKey('mcp-name-field')),
      'remote-demo',
    );
    await tester.enterText(
      find.byKey(const ValueKey('mcp-endpoint-field')),
      'ftp://example.com',
    );
    await tester.ensureVisible(find.byKey(const ValueKey('save-mcp-button')));
    await tester.tap(find.byKey(const ValueKey('save-mcp-button')));
    await tester.pumpAndSettle();

    expect(find.text('远程配置需要 http:// 或 https:// 地址'), findsOneWidget);
    expect(find.text('remote-demo'), findsOneWidget);

    await tester.enterText(
      find.byKey(const ValueKey('mcp-endpoint-field')),
      'https://remote.example.com/mcp',
    );
    await tester.tap(find.byKey(const ValueKey('save-mcp-button')));
    await tester.pumpAndSettle();
    expect(find.text('远程'), findsWidgets);

    await tester.ensureVisible(find.byKey(const ValueKey('export-mcp-button')));
    await tester.tap(find.byKey(const ValueKey('export-mcp-button')));
    await tester.pumpAndSettle();

    final manifest = tester
        .widget<SelectableText>(find.byType(SelectableText))
        .data;
    expect(manifest, contains('https://remote.example.com/mcp'));
    expect(manifest, contains('https://mcp.example.com/github'));
    expect(manifest, isNot(contains('stdio://')));
    expect(find.text('仅导出远程配置，且仍为演示'), findsOneWidget);
  });
}
