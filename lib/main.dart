import 'dart:typed_data';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:event_management/firebase_options.dart';
import 'package:event_management/qr_scanner.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart';
import 'package:image_picker/image_picker.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    // name: "connect2k24",
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Event Management App',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const MyHomePage(title: 'Event Management App'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  int _year = 0;
  TextEditingController _section = TextEditingController();
  Uint8List? image = null;
  TextEditingController _nameController = TextEditingController();
  TextEditingController _regNoController = TextEditingController();
  TextEditingController _emailController = TextEditingController();

  void _setYear(year, setState) {
    setState(() {
      _year = year;
    });
  }

  void _setSection(section, setState) {
    setState(() {
      _section = section;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: Text(widget.title),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            FilledButton(
              onPressed: () {
                Navigator.of(context).push(MaterialPageRoute(
                    builder: (context) => const QRScannerPage()));
              },
              child: const Text("Scan QR"),
            ),
            OutlinedButton(
              onPressed: () {
                resetState();
                showModalBottomSheet(
                    isScrollControlled: true,
                    useRootNavigator: true,
                    context: context,
                    builder: (context) {
                      return StatefulBuilder(builder: (context, setSheetState) {
                        return Padding(
                          padding: const EdgeInsets.all(24.0).copyWith(
                              bottom: MediaQuery.of(context).viewInsets.bottom +
                                  24),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text("Onspot Registration",
                                  style:
                                      Theme.of(context).textTheme.titleLarge),
                              const SizedBox(
                                height: 24,
                              ),
                              InkWell(
                                onTap: () {
                                  final ImagePicker picker = ImagePicker();
                                  picker
                                      .pickImage(source: ImageSource.camera)
                                      .then((image) async {
                                    if (image != null) {
                                      var imageBytes =
                                          await image.readAsBytes();
                                      setSheetState(() async {
                                        this.image = imageBytes;
                                      });
                                    }
                                  });
                                },
                                child: CircleAvatar(
                                  radius: 48,
                                  child: image == null
                                      ? Icon(Icons.person)
                                      : ClipOval(
                                          child: Image.memory(
                                            image!,
                                            width: 96,
                                            height: 96,
                                            fit: BoxFit.cover,
                                          ),
                                        ),
                                ),
                              ),
                              TextField(
                                decoration: const InputDecoration(
                                  labelText: "Name",
                                ),
                                controller: _nameController,
                              ),
                              const SizedBox(
                                height: 12,
                              ),
                              Row(
                                children: [
                                  Expanded(
                                    child: DropdownButton<int>(
                                        value: _year == 0 ? null : _year,
                                        hint: const Text("Select Year"),
                                        items: List.generate(
                                          4,
                                          (index) => DropdownMenuItem(
                                            child: Text("${index + 1} year"),
                                            value: index + 1,
                                          ),
                                        ),
                                        onChanged: (year) {
                                          _setYear(year, setSheetState);
                                        }),
                                  ),
                                  const SizedBox(
                                    width: 12,
                                  ),
                                  Expanded(
                                    child: TextField(
                                      decoration: const InputDecoration(
                                        labelText: "Section",
                                      ),
                                      controller: _section,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(
                                height: 12,
                              ),
                              TextField(
                                decoration: const InputDecoration(
                                  labelText: "Registration Number",
                                ),
                                controller: _regNoController,
                              ),
                              const SizedBox(
                                height: 12,
                              ),
                              TextField(
                                decoration: const InputDecoration(
                                  labelText: "Email",
                                ),
                                controller: _emailController,
                              ),
                              const SizedBox(
                                height: 24,
                              ),
                              FilledButton(
                                onPressed: () {
                                  if (_nameController.text.isEmpty ||
                                      _regNoController.text.isEmpty ||
                                      _year == 0 ||
                                      _section.text.isEmpty ||
                                      _emailController.text.isEmpty) {
                                    Navigator.of(context).pop();
                                    ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(
                                            content: Text(
                                                "Please fill all the fields")));
                                    return;
                                  }
                                  try {
                                    FirebaseFirestore.instance
                                        .collection("onspot")
                                        .doc(_regNoController.text)
                                        .set({
                                      "name": _nameController.text,
                                      "year": _year,
                                      "section": _section.text,
                                      "reg": _regNoController.text,
                                      "dj": false,
                                      "entry": false,
                                      "lunch": false,
                                      "email": _emailController.text,
                                    }).then((value) {
                                      get(Uri.parse("")).then((value) {
                                        if (value.statusCode != 200) {
                                          ScaffoldMessenger.of(context)
                                              .showSnackBar(SnackBar(
                                                  content: Text(
                                                      "Couldn't send email")));
                                        }
                                        resetState();
                                        Navigator.of(context).pop();
                                      });
                                    });
                                  } catch (error) {
                                    print(error);
                                  }
                                },
                                child: const Text("Submit"),
                              ),
                            ],
                          ),
                        );
                      });
                    });
              },
              child: const Text("Onspot Registration"),
            ),
          ],
        ),
      ),
    );
  }

  void resetState() {
    _nameController.clear();
    _regNoController.clear();
    _setYear(0, setState);
    _section.clear();
    image = null;
    _emailController.clear();
    setState(() {});
  }
}
