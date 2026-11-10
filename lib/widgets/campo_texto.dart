import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:iheart/nucleo/tema.dart';

class CampoTexto extends StatelessWidget {
  final TextEditingController controlador;
  final String etiqueta;
  final String? pista;
  final IconData? iconoPrefijo;
  final Widget? iconoSufijo;
  final bool ocultarTexto;
  final TextInputType tipoTeclado;
  final String? Function(String?)? validador;
  final bool habilitado;
  final List<TextInputFormatter>? formateadores;
  final ValueChanged<String>? alCambiar;
  final AutovalidateMode? modoValidacion;

  const CampoTexto({
    super.key,
    required this.controlador,
    required this.etiqueta,
    this.pista,
    this.iconoPrefijo,
    this.iconoSufijo,
    this.ocultarTexto = false,
    this.tipoTeclado = TextInputType.text,
    this.validador,
    this.habilitado = true,
    this.formateadores,
    this.alCambiar,
    this.modoValidacion,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controlador,
      obscureText: ocultarTexto,
      keyboardType: tipoTeclado,
      validator: validador,
      enabled: habilitado,
      inputFormatters: formateadores,
      onChanged: alCambiar,
      autovalidateMode: modoValidacion,
      style: const TextStyle(
        fontSize: 16,
        color: TemaApp.textoOscuro,
      ),
      decoration: InputDecoration(
        labelText: etiqueta,
        hintText: pista,
        errorMaxLines: 3,
        prefixIcon: iconoPrefijo != null ? Icon(iconoPrefijo, color: TemaApp.textoSecundario) : null,
        suffixIcon: iconoSufijo,
        filled: true,
        fillColor: TemaApp.grisSuperficie,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: TemaApp.grisBorde),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: TemaApp.grisBorde),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: TemaApp.rojoPrimario, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: TemaApp.rojoError),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: TemaApp.rojoError, width: 1.5),
        ),
      ),
    );
  }
}
