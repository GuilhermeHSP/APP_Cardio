import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';

main() => runApp(const CardioApp());

void teste() {
  // ignore: avoid_print
  print('TESTE');
}

void carregarArquivo() async {
  FilePickerResult? result = await FilePicker.platform.pickFiles();

  if (result != null) {
    File file = File(result.files.single.path!);
    //FALTA TRATAMENTO PRA VERIFICAR .CSVV

  } else {
    // User canceled the picker
  }
  return;
}

class CardioApp extends StatefulWidget {
  const CardioApp({super.key});

  @override
  State<CardioApp> createState() => _CardioAppState();
}

class _CardioAppState extends State<CardioApp> {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(
            backgroundColor: const Color.fromARGB(255, 126, 0, 0),
            title: const Center(
                child: Text('Previsão de Insuficiência Cardíaca'))),
        body: Center(
          child: Column(
            // ignore: prefer_const_literals_to_create_immutables
            children: [
              const Text(''),
              const Card(
                child: ListTile(
                  title: Text('Carregar arquivo:'),
                  subtitle: Text('Formato deve ser .CSV'),
                  trailing: IconButton(
                      onPressed: carregarArquivo, icon: Icon(Icons.add)),
                  iconColor: Color.fromARGB(255, 126, 0, 0),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
