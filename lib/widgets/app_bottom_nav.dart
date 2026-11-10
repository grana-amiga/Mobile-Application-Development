import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// Barra de navegação inferior com ícone + texto em todos os itens.
///
/// Fica "flutuando" acima da borda da tela, com cantos bem arredondados,
/// seguindo o estilo do design de referência.
class AppBottomNav extends StatelessWidget {
  const AppBottomNav({
    super.key,
    required this.currentIndex,
    required this.onTap,
  });

  final int currentIndex;
  final ValueChanged<int> onTap;

  static const List<_NavData> _items = [
    _NavData('Início', Icons.home),
    _NavData('Dívidas', Icons.credit_card),
    _NavData('Energia', Icons.bolt),
    _NavData('Aprender', Icons.menu_book),
  ];

  @override
  Widget build(BuildContext context) {
    // SafeArea afasta a barra de áreas do sistema (notch, barra de gestos).
    return SafeArea(
      top: false,
      child: Container(
        margin: const EdgeInsets.fromLTRB(14, 6, 14, 10),
        padding: const EdgeInsets.all(6),
        decoration: AppDecor.card(radius: 28, outlined: true),
        child: Row(
          children: [
            for (var i = 0; i < _items.length; i++)
              Expanded(
                child: _NavButton(
                  data: _items[i],
                  selected: i == currentIndex,
                  onTap: () => onTap(i),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _NavData {
  const _NavData(this.label, this.icon);

  final String label;
  final IconData icon;
}

class _NavButton extends StatelessWidget {
  const _NavButton({
    required this.data,
    required this.selected,
    required this.onTap,
  });

  final _NavData data;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = selected ? Colors.white : AppColors.petrol;

    // Material + InkWell dão o efeito de "ondinha" ao tocar.
    return Semantics(
      button: true,
      selected: selected,
      label: data.label,
      child: Material(
        color: selected ? AppColors.petrol : Colors.transparent,
        borderRadius: BorderRadius.circular(22),
        child: InkWell(
          borderRadius: BorderRadius.circular(22),
          onTap: onTap,
          child: Container(
            constraints: const BoxConstraints(minHeight: 60),
            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 2),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(data.icon, color: color, size: 26),
                const SizedBox(height: 2),
                Text(
                  data.label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: color,
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
