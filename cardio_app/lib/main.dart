import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:dio/dio.dart';
import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/widgets.dart';
import 'dart:io' as Io;

main() => runApp(const CardioApp());

void teste() {
  // ignore: avoid_print
  print('TESTE');
}

class CardioApp extends StatefulWidget {
  const CardioApp({super.key});

  @override
  State<CardioApp> createState() => _CardioAppState();
}

class _CardioAppState extends State<CardioApp> {
  File? file;
  var id;
  @override
  Widget build(BuildContext context) {
    void apiTrain() async {
      Response response;
      var dio = Dio();
      response = await dio.post(
          'http://192.168.0.107:5000/api/v1/classification/train',
          queryParameters: {
            'files': await file!.readAsString(),
            'target': 'DEATH_EVENT',
          });
      id = response.toString();
    }

    void carregarArquivoTreinamento() async {
      FilePickerResult? result = await FilePicker.platform.pickFiles();

      if (result != null) {
        setState(() {
          file = File(result.files.single.path!);
          apiTrain();
        });
        //FALTA TRATAMENTO PRA VERIFICAR .CSVV

      } else {
        // User canceled the picker
      }
    }

    void apiPredicao() async {
      Response response;
      var dio = Dio();
      response = await dio.post(
          'http://192.168.0.107:5000/api/v1/classification/{$id}/predict',
          queryParameters: {
            'files': await file!.readAsString(),
            'paraments': 'DEATH_EVENT',
          });
      var imgBase64 = response.toString();

      final splitted = imgBase64.substring(47, 25628);
      final decodedBytes = base64Decode(splitted);
      var file = Io.File("decodedBezkoder.png");
      file.writeAsBytesSync(decodedBytes);
    }

    void carregarArquivoPredicao() async {
      FilePickerResult? result = await FilePicker.platform.pickFiles();

      if (result != null) {
        setState(() {
          file = File(result.files.single.path!);
        });
        //FALTA TRATAMENTO PRA VERIFICAR .CSVV

      } else {
        // User canceled the picker
      }
    }

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
              const Text('\nTreinamento'),
              Card(
                child: ListTile(
                  title: const Text('Carregar arquivo:'),
                  subtitle:
                      const Text('Formato deve ser .CSV para treino de modelo'),
                  trailing: IconButton(
                      onPressed: carregarArquivoTreinamento,
                      icon: const Icon(Icons.add)),
                  iconColor: const Color.fromARGB(255, 126, 0, 0),
                ),
              ),
              const Text('\nPredição'),
              Card(
                child: ListTile(
                  title: const Text('Carregar arquivo:'),
                  subtitle: const Text(
                      'Formato deve ser .CSV para predição de valores'),
                  trailing: IconButton(
                      onPressed: apiPredicao, icon: const Icon(Icons.add)),
                  iconColor: const Color.fromARGB(255, 126, 0, 0),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
