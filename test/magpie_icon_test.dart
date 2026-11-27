import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:magpie_mobile/gateway/gateway_presets.dart';
import 'package:magpie_mobile/widgets/magpie_icon.dart';
import 'package:magpie_mobile/widgets/provider_icon.dart';

void main() {
  testWidgets('every upstream UI glyph is bundled and decodes', (tester) async {
    await tester.runAsync(() async {
      for (final glyph in MagpieGlyph.values) {
        final picture = await vg.loadPicture(SvgAssetLoader(glyph.asset), null);
        expect(picture.size.isEmpty, isFalse, reason: glyph.asset);
        picture.picture.dispose();
      }
    });
  });

  testWidgets('all directory presets use a bundled upstream logo', (
    tester,
  ) async {
    for (final preset in ProviderPreset.directory) {
      await tester.pumpWidget(
        Directionality(
          textDirection: TextDirection.ltr,
          child: ProviderIcon(presetId: preset.id),
        ),
      );
      final svg = tester.widget<SvgPicture>(find.byType(SvgPicture));
      final loader = svg.bytesLoader as SvgAssetLoader;
      expect(loader.assetName, 'assets/upstream/vendors/${preset.id}.svg');
      await tester.runAsync(() async {
        final picture = await vg.loadPicture(loader, null);
        expect(picture.size.isEmpty, isFalse, reason: loader.assetName);
        picture.picture.dispose();
      });
    }
  });

  testWidgets('provider branding requires an exact, unambiguous host', (
    tester,
  ) async {
    for (final (hosts, filename, isColor) in [
      (['API.OPENAI.COM'], 'vendors/openai.svg', false),
      (['generativelanguage.googleapis.com'], 'vendors/google.svg', true),
      (['api.openai.com.example.org'], 'ui/provider-generic.svg', false),
      (['api.openai.com', 'openrouter.ai'], 'ui/provider-generic.svg', false),
      (['api.openai.com', 'example.org'], 'ui/provider-generic.svg', false),
      (['127.0.0.1'], 'ui/provider-generic.svg', false),
      (<String>[], 'ui/provider-generic.svg', false),
    ]) {
      await tester.pumpWidget(
        Directionality(
          textDirection: TextDirection.ltr,
          child: IconTheme(
            data: const IconThemeData(color: Colors.white),
            child: ProviderIcon(hosts: hosts),
          ),
        ),
      );
      final svg = tester.widget<SvgPicture>(find.byType(SvgPicture));
      expect(
        (svg.bytesLoader as SvgAssetLoader).assetName,
        'assets/upstream/$filename',
      );
      if (filename.startsWith('vendors/')) {
        expect(svg.colorFilter, isColor ? isNull : isNotNull);
      }
    }
  });

  testWidgets('monochrome glyphs follow the active icon theme', (tester) async {
    for (final color in [Colors.black, Colors.white]) {
      await tester.pumpWidget(
        Directionality(
          textDirection: TextDirection.ltr,
          child: IconTheme(
            data: IconThemeData(color: color, size: 18, opacity: .5),
            child: const MagpieIcon(MagpieGlyph.settings),
          ),
        ),
      );
      final svg = tester.widget<SvgPicture>(find.byType(SvgPicture));
      final loader = svg.bytesLoader as SvgAssetLoader;
      expect(loader.theme?.currentColor, color.withValues(alpha: .5));
      expect(svg.width, 18);
      expect(svg.excludeFromSemantics, isTrue);
    }
  });
}
