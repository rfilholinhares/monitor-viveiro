// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:monitor_viveiro/services/hive_service.dart';
import 'screens/home_screen.dart';
import 'package:intl/date_symbol_data_local.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('pt_BR', null);
  await HiveService.instance.init();
  runApp(const MonitorViveirosApp());
}

class MonitorViveirosApp extends StatelessWidget {
  const MonitorViveirosApp({super.key});

  @override
  Widget build(BuildContext context) {
    // --- NOVAS CORES ---
    const Color corPrimaria = Color(
      0xFF1565C0,
    ); // Azul Royal (Colors.blue[800])
    const Color corFundo = Color(
      0xFFF4F6F8,
    ); // Um cinza bem claro (quase branco)
    const Color corCard = Colors.white;
    const Color corVermelha = Colors.redAccent; // Para botões de perigo/limpar
    // --- FIM DAS NOVAS CORES ---

    return MaterialApp(
      title: 'Monitor de Viveiros',
      debugShowCheckedModeBanner: false,

      locale: const Locale('pt', 'BR'),
      supportedLocales: const [Locale('pt', 'BR')],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],

      theme: ThemeData(
        // Esquema de cores principal
        primaryColor: corPrimaria,
        scaffoldBackgroundColor: corFundo,

        // Define o novo "colorScheme" para que widgets modernos
        // (como o DatePicker) usem a cor primária
        colorScheme: ColorScheme.fromSeed(
          seedColor: corPrimaria,
          primary: corPrimaria,
          background: corFundo,
        ),

        // Estilo dos botões
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: corPrimaria, // Usa a cor primária
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            textStyle: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        outlinedButtonTheme: OutlinedButtonThemeData(
          style: OutlinedButton.styleFrom(
            side: const BorderSide(
              color: corPrimaria,
              width: 1.5,
            ), // Usa a cor primária
            foregroundColor: corPrimaria, // Usa a cor primária
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            textStyle: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),

        // Tema para os Inputs (Campos de Texto)
        inputDecorationTheme: InputDecorationTheme(
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(
              color: Colors.grey.shade400,
            ), // Borda cinza clara
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(
              color: corPrimaria,
              width: 2.0,
            ), // Foco na cor primária
          ),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 12,
          ),
        ),

        // Tema para os Cards
        cardTheme: CardThemeData(
          elevation: 1,
          color: corCard, // Fundo branco
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),

        // Tema do AppBar
        appBarTheme: const AppBarTheme(
          backgroundColor: corPrimaria, // Usa a cor primária
          foregroundColor: Colors.white,
          elevation: 2,
        ),

        // Tema para o ícone de limpar (vermelho)
        iconTheme: const IconThemeData(
          color: corPrimaria, // Ícones padrão usam a cor primária
        ),
        iconButtonTheme: IconButtonThemeData(
          style: ButtonStyle(
            // Estilo específico para ícones vermelhos (usado no filtro)
            iconColor: WidgetStateProperty.resolveWith<Color?>((
              Set<WidgetState> states,
            ) {
              // Se o ícone tiver a cor vermelha (como no _buildFilterBar),
              // ela será mantida.
              if (states.contains(WidgetState.error)) {
                return corVermelha;
              }
              // Senão, usa a cor primária
              return corPrimaria;
            }),
          ),
        ),
      ),
      home: const HomeScreen(),
    );
  }
}
