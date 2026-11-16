import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import '../ui/primary_button.dart';
import '../ui/reading_card.dart';
import '../ui/success_dialog.dart';

/// Pantalla de prueba del design system: muestra juntos los componentes base
/// (`PrimaryButton`, `ReadingCard`, `SuccessDialog`). Ruta: `/playground`.
class UiPlaygroundScreen extends StatefulWidget {
  const UiPlaygroundScreen({super.key});

  static const routeName = '/playground';

  @override
  State<UiPlaygroundScreen> createState() => _UiPlaygroundScreenState();
}

class _UiPlaygroundScreenState extends State<UiPlaygroundScreen> {
  int _selected = 0;
  bool _loading = false;

  Future<void> _fakeLoad() async {
    setState(() => _loading = true);
    await Future<void>.delayed(const Duration(seconds: 2));
    if (mounted) setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;

    Widget section(String title, Widget child) => Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: text.titleLarge),
        const SizedBox(height: 12),
        child,
      ],
    );

    final cards = [
      const ReadingCard(
        word: 'mamá',
        syllables: ['ma', 'má'],
        caption: 'Sílabas',
      ),
      const ReadingCard(
        word: 'sapo',
        syllables: ['sa', 'po'],
        caption: 'Sílabas',
      ),
      const ReadingCard(word: 'Leo', caption: 'Palabra'),
    ];

    final readingSection = section(
      'ReadingCard',
      LayoutBuilder(
        builder: (context, c) {
          const gap = 16.0;
          // Ancho mínimo por tarjeta ~360 dp: la palabra a 72 dp cabe sin reducirse.
          final cols = c.maxWidth >= 1140 ? 3 : (c.maxWidth >= 560 ? 2 : 1);
          final w = (c.maxWidth - gap * (cols - 1)) / cols;
          return Wrap(
            spacing: gap,
            runSpacing: gap,
            children: [
              for (var i = 0; i < cards.length; i++)
                SizedBox(
                  width: w,
                  child: ReadingCard(
                    word: cards[i].word,
                    syllables: cards[i].syllables,
                    caption: cards[i].caption,
                    selected: _selected == i,
                    onTap: () => setState(() => _selected = i),
                    onListen: () {},
                  ),
                ),
            ],
          );
        },
      ),
    );

    final buttonSection = section(
      'PrimaryButton',
      Wrap(
        spacing: 16,
        runSpacing: 16,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          PrimaryButton(
            label: '¡Empezar!',
            icon: Icons.play_arrow_rounded,
            size: PrimaryButtonSize.large,
            onPressed: () {},
          ),
          PrimaryButton(label: 'Continuar', onPressed: () {}),
          PrimaryButton(
            label: _loading ? 'Guardando…' : 'Guardar',
            isLoading: _loading,
            icon: Icons.save_rounded,
            onPressed: _fakeLoad,
          ),
          const PrimaryButton(
            label: 'Bloqueado',
            icon: Icons.lock_rounded,
            onPressed: null,
          ),
        ],
      ),
    );

    final dialogSection = section(
      'SuccessDialog',
      Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          DecoratedBox(
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(32),
              border: Border.all(color: AppColors.outlineVariant, width: 2),
            ),
            child: Center(
              child: SuccessDialog(
                title: '¡Muy bien, Sofía!',
                message: 'Leíste 3 palabras sin ayuda.',
                stars: 2,
                onContinue: () {},
              ),
            ),
          ),
          const SizedBox(height: 12),
          Center(
            child: TextButton.icon(
              key: const Key('open_success_dialog'),
              onPressed: () => SuccessDialog.show(
                context,
                title: '¡Lo lograste!',
                message: 'Encontraste el sonido /m/.',
              ),
              icon: const Icon(Icons.open_in_new_rounded),
              label: const Text('Abrir como modal'),
            ),
          ),
        ],
      ),
    );

    return Scaffold(
      appBar: AppBar(title: const Text('UI Playground · Design System')),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, c) {
            final wide = c.maxWidth >= 1000;
            return SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
              child: wide
                  ? Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              readingSection,
                              const SizedBox(height: 28),
                              buttonSection,
                            ],
                          ),
                        ),
                        const SizedBox(width: 28),
                        SizedBox(width: 420, child: dialogSection),
                      ],
                    )
                  : Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        readingSection,
                        const SizedBox(height: 28),
                        buttonSection,
                        const SizedBox(height: 28),
                        dialogSection,
                      ],
                    ),
            );
          },
        ),
      ),
    );
  }
}
