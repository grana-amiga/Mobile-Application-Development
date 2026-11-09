import 'package:flutter/material.dart';

/// Paleta "Bolso" do Grana Amiga.
///
/// Todas as cores ficam em um único lugar para que o visual seja trocado
/// sem mexer nas telas. Os contrastes de texto foram conferidos (mínimo 4,5:1).
class AppColors {
  AppColors._(); // Construtor privado: a classe só guarda constantes.

  // Cores principais da marca.
  static const Color petrol = Color(0xFF0F4C5C); // textos, títulos, botões fortes
  static const Color petrolDark = Color(0xFF083844);
  static const Color peach = Color(0xFFFF9F68); // botões de destaque (CTA)
  static const Color cream = Color(0xFFFFF6EA); // fundo das telas
  static const Color mint = Color(0xFF7FD1AE); // sucesso e progresso

  // Cores do Termômetro do Dinheiro (sempre usadas junto com ícone e texto).
  static const Color green = Color(0xFF2A7F50);
  static const Color yellow = Color(0xFFF2B134);
  static const Color brick = Color(0xFFBD4D35); // vermelho-tijolo, menos agressivo

  // Tons de apoio.
  static const Color card = Color(0xFFFFFCF8);
  static const Color textSoft = Color(0xFF2F5C69); // texto secundário (7:1 no creme)
  static const Color peachSoft = Color(0xFFFFE3D2);
  static const Color mintSoft = Color(0xFFD9F1E7);
  static const Color yellowSoft = Color(0xFFFBE7B8);
  static const Color brickSoft = Color(0xFFF4D6CE);
  static const Color brickDark = Color(0xFF8F3624); // texto sobre brickSoft
  static const Color border = Color(0x290F4C5C); // petróleo com 16% de opacidade
  static const Color shadow = Color(0x1A0F4C5C); // petróleo com 10% de opacidade
}

/// Estilos de texto reaproveitados nas telas.
///
/// Não definimos `fontFamily` aqui: ele vem do tema (Nunito), porque o
/// [Text] mistura o estilo recebido com o estilo padrão do tema.
class AppText {
  AppText._();

  static const TextStyle h1 = TextStyle(
    fontSize: 28,
    fontWeight: FontWeight.w900,
    height: 1.1,
    letterSpacing: -0.5,
    color: AppColors.petrol,
  );

  static const TextStyle h2 = TextStyle(
    fontSize: 20,
    fontWeight: FontWeight.w900,
    height: 1.2,
    color: AppColors.petrol,
  );

  static const TextStyle h3 = TextStyle(
    fontSize: 17,
    fontWeight: FontWeight.w800,
    height: 1.2,
    color: AppColors.petrol,
  );

  static const TextStyle body = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w600,
    height: 1.35,
    color: AppColors.petrol,
  );

  static const TextStyle small = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w600,
    height: 1.3,
    color: AppColors.textSoft,
  );

  static const TextStyle eyebrow = TextStyle(
    fontSize: 13,
    fontWeight: FontWeight.w800,
    letterSpacing: 1,
    color: AppColors.textSoft,
  );

  static const TextStyle button = TextStyle(
    fontSize: 17,
    fontWeight: FontWeight.w800,
  );
}

/// Decorações (fundo, borda, sombra) usadas em cartões e caixas.
class AppDecor {
  AppDecor._();

  /// Cartão arredondado com sombra suave, usado em quase todas as telas.
  static BoxDecoration card({
    Color color = AppColors.card,
    double radius = 24,
    bool outlined = false,
  }) {
    return BoxDecoration(
      color: color,
      borderRadius: BorderRadius.circular(radius),
      border: outlined ? Border.all(color: AppColors.border) : null,
      boxShadow: const [
        BoxShadow(
          color: AppColors.shadow,
          blurRadius: 22,
          offset: Offset(0, 8),
        ),
      ],
    );
  }
}

/// Visual padrão dos campos de formulário (TextFormField).
///
/// Mensagens de erro usam a cor tijolo e peso forte para ficarem legíveis.
InputDecoration appInputDecoration({
  required String label,
  String? hint,
  IconData? icon,
  Widget? suffix,
}) {
  const radius = BorderRadius.all(Radius.circular(18));
  return InputDecoration(
    labelText: label,
    hintText: hint,
    prefixIcon: icon == null ? null : Icon(icon, color: AppColors.petrol),
    suffixIcon: suffix,
    filled: true,
    fillColor: AppColors.card,
    labelStyle: const TextStyle(
      color: AppColors.textSoft,
      fontWeight: FontWeight.w700,
    ),
    errorStyle: const TextStyle(
      color: AppColors.brickDark,
      fontWeight: FontWeight.w800,
      fontSize: 14,
    ),
    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
    border: const OutlineInputBorder(
      borderRadius: radius,
      borderSide: BorderSide(color: AppColors.border, width: 1.5),
    ),
    enabledBorder: const OutlineInputBorder(
      borderRadius: radius,
      borderSide: BorderSide(color: AppColors.border, width: 1.5),
    ),
    focusedBorder: const OutlineInputBorder(
      borderRadius: radius,
      borderSide: BorderSide(color: AppColors.petrol, width: 2.5),
    ),
    errorBorder: const OutlineInputBorder(
      borderRadius: radius,
      borderSide: BorderSide(color: AppColors.brick, width: 2),
    ),
    focusedErrorBorder: const OutlineInputBorder(
      borderRadius: radius,
      borderSide: BorderSide(color: AppColors.brick, width: 2.5),
    ),
  );
}

/// Tema global (ThemeData) do aplicativo.
class AppTheme {
  AppTheme._();

  static ThemeData light() {
    // ColorScheme: conjunto de cores semânticas que os widgets Material usam
    // por padrão (botões, switches, sliders...). Partimos de uma semente e
    // trocamos só o que importa para a marca.
    final scheme = ColorScheme.fromSeed(
      seedColor: AppColors.petrol,
      brightness: Brightness.light,
    ).copyWith(
      primary: AppColors.petrol,
      onPrimary: Colors.white,
      secondary: AppColors.peach,
      onSecondary: AppColors.petrolDark,
      error: AppColors.brick,
      onError: Colors.white,
      surface: AppColors.cream,
      onSurface: AppColors.petrol,
    );

    final base = ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      fontFamily: 'Nunito',
      scaffoldBackgroundColor: AppColors.cream,
    );

    return base.copyWith(
      textTheme: base.textTheme.apply(
        bodyColor: AppColors.petrol,
        displayColor: AppColors.petrol,
      ),
    );
  }
}
