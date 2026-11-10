import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:iheart/router.dart';
import 'package:iheart/nucleo/tema.dart';
import 'package:iheart/nucleo/proveedor_estado.dart';

class App extends StatelessWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (_) => ProveedorEstado()..inicializarApp(),
        ),
      ],
      child: MaterialApp.router(
        title: 'I HEAR(TH) U',
        theme: TemaApp.obtenerTema(),
        routerConfig: rutasApp,
        debugShowCheckedModeBanner: false,
      ),
    );
  }
}
