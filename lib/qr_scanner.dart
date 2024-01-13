import 'dart:convert';
import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dart_jsonwebtoken/dart_jsonwebtoken.dart';
import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

class QRScannerPage extends StatefulWidget {
  const QRScannerPage({super.key});

  @override
  State<QRScannerPage> createState() => _QRScannerPageState();
}

class _QRScannerPageState extends State<QRScannerPage> {
  var _controller = MobileScannerController();
  var _checkboxStateOne = false;
  var _checkboxStateTwo = false;
  var _checkboxStateThree = false;
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: MobileScanner(
        controller: _controller,
        overlay: Center(
          child: Container(
              width: 200,
              height: 200,
              decoration:
                  BoxDecoration(border: Border.all(style: BorderStyle.solid))),
        ),
        // fit: BoxFit.contain,
        onDetect: (capture) async {
          final barcodes = capture.barcodes;

          for (final barcode in barcodes) {
            debugPrint('Barcode found! ${barcode.rawValue}');
            var _data = JWT.decode(barcode.rawValue ?? "");
            await _controller.stop();
            final firebaseData = await FirebaseFirestore.instance
                .collection("onspot")
                .doc(_data.payload["reg"].toString())
                .get();
            var data = firebaseData.data();
            if (data == null) {
              data = {
                "dj": false,
                "entry": false,
                "lunch": false,
              };
            }
            _checkboxStateOne = data["dj"];
            _checkboxStateTwo = data["entry"];
            _checkboxStateThree = data["lunch"];
            // ignore: use_build_context_synchronously
            showModalBottomSheet(
                context: context,
                builder: (context) {
                  return StatefulBuilder(builder: (context, setSheetState) {
                    return Padding(
                      padding: const EdgeInsets.all(24.0),
                      child: SizedBox(
                        width: double.infinity,
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text("Attendee Data",
                                style: Theme.of(context).textTheme.titleLarge),
                            const SizedBox(
                              height: 24,
                            ),
                            const InkWell(
                              child: CircleAvatar(
                                  radius: 48, child: Icon(Icons.person)
                                  //       : ClipOval(
                                  //           child: Image.memory(
                                  //             imageBytes,
                                  //             width: 96,
                                  //             height: 96,
                                  //             fit: BoxFit.cover,
                                  //           ),
                                  //         ),
                                  ),
                            ),
                            const SizedBox(
                              height: 12,
                            ),
                            Text(_data.payload["name"].toString()),
                            const SizedBox(
                              height: 6,
                            ),
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(_data.payload["year"].toString()),
                                const SizedBox(
                                  width: 12,
                                ),
                                Text(_data.payload["section"].toString()),
                              ],
                            ),
                            const SizedBox(
                              height: 6,
                            ),
                            Text(_data.payload["reg"].toString()),
                            const SizedBox(
                              height: 12,
                            ),
                            Row(
                              children: [
                                Checkbox(
                                    value: _checkboxStateOne,
                                    onChanged: (_) {
                                      setSheetState(() {
                                        _checkboxStateOne = !_checkboxStateOne;
                                      });
                                    }),
                                const Text("DJ Night"),
                                Checkbox(
                                    value: _checkboxStateTwo,
                                    onChanged: (_) {
                                      setSheetState(() {
                                        _checkboxStateTwo = !_checkboxStateTwo;
                                      });
                                    }),
                                const Text("Entry"),
                                Checkbox(
                                    value: _checkboxStateThree,
                                    onChanged: (_) {
                                      setSheetState(() {
                                        _checkboxStateThree =
                                            !_checkboxStateThree;
                                      });
                                    }),
                                const Text("Lunch"),
                              ],
                            ),
                            const SizedBox(
                              height: 24,
                            ),
                            FilledButton(
                              onPressed: () {
                                try {
                                  FirebaseFirestore.instance
                                      .collection("onspot")
                                      .doc(_data.payload["reg"].toString())
                                      .update({
                                    "dj": _checkboxStateOne,
                                    "entry": _checkboxStateTwo,
                                    "lunch": _checkboxStateThree,
                                  }).then((value) {
                                    Navigator.of(context).pop();
                                    ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(content: Text("Updated")));
                                  });
                                } catch (_) {
                                  print("Error");
                                }
                              },
                              child: const Text("Update"),
                            ),
                          ],
                        ),
                      ),
                    );
                  });
                }).then((value) {
              if (!_controller.isStarting) {
                _controller.start();
              }
            });
          }
        },
      ),
    );
  }
}
