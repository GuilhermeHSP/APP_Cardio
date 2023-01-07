import 'dart:io';
import 'dart:typed_data';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'dart:convert';
//import 'package:flutter/widgets.dart';

main() => runApp(const CardioApp());

Uint8List base64Decode(String source) => base64.decode(source);

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
  ImageProvider? imagemFinal;

  // ignore: prefer_typing_uninitialized_variables
  String? id;

  @override
  Widget build(BuildContext context) {
    void apiTrain() async {
      var dio = Dio();
      final files = FormData.fromMap({
        'file': await MultipartFile.fromFile(file!.path,
            filename: file!.uri.pathSegments.last)
      });

      final response = await dio.post(
          'http://192.168.0.107:5000/api/v1/classification/train',
          queryParameters: {
            'target': 'DEATH_EVENT',
          },
          data: files);
      id = response.toString();
      // ignore: avoid_print
      print(id);
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
      var dio = Dio();
      final files2 = FormData.fromMap({
        'file': await MultipartFile.fromFile(file!.path,
            filename: file!.uri.pathSegments.last)
      });

      final response = await dio.post(
          'http://192.168.0.107:5000/api/v1/classification/$id/predict',
          queryParameters: {
            'target': 'DEATH_EVENT',
          },
          data: files2);

      var result = jsonDecode(response.toString());

      setState(() {
        imagemFinal = Image.memory(base64Decode(result['plot'])).image;
      });
    }

    void carregarArquivoPredicao() async {
      FilePickerResult? result = await FilePicker.platform.pickFiles();

      if (result != null) {
        setState(() {
          file = File(result.files.single.path!);
          apiPredicao();
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
        body: ListView(
          children: [
            Center(
              child: Column(
                // ignore: prefer_const_literals_to_create_immutables
                children: [
                  const Text('\nTreinamento'),
                  Card(
                    child: ListTile(
                      title: const Text('Carregar arquivo:'),
                      subtitle: const Text(
                          'Formato deve ser .CSV para treino de modelo'),
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
                          onPressed: carregarArquivoPredicao,
                          icon: const Icon(Icons.add)),
                      iconColor: const Color.fromARGB(255, 126, 0, 0),
                    ),
                  ),
                  const Text('\nResultado\n'),
                  imagemFinal != null ? Image(image: imagemFinal!) : Container()
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
