import 'package:flutter/material.dart';

class CaptionEditorPage extends StatefulWidget {
  final String initialText;

  const CaptionEditorPage({super.key, this.initialText = ""});

  @override
  State<CaptionEditorPage> createState() => _CaptionEditorPageState();
}

class _CaptionEditorPageState extends State<CaptionEditorPage> {
  late TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialText);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 255, 255, 255), // Gelap Elegan (ala Screenshot)
      appBar: AppBar(
        backgroundColor: const Color.fromARGB(0, 255, 255, 255),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color.fromARGB(255, 0, 0, 0), size: 24),
          onPressed: () => Navigator.pop(context), // Batal
        ),
        centerTitle: true,
        title: const Text(
          "Caption",
          style: TextStyle(color: Color.fromARGB(255, 0, 0, 0), fontWeight: FontWeight.bold, fontSize: 18),
        ),
        actions: [
          TextButton(
            onPressed: () {
              // Kirim balik teks hasil ketikan ke halaman sebelumnya
              Navigator.pop(context, _controller.text);
            },
            child: const Text(
              "OK",
              style: TextStyle(color: Colors.blue, fontWeight: FontWeight.bold, fontSize: 18),
            ),
          ),
          const SizedBox(width: 10),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        child: TextField(
          controller: _controller,
          autofocus: true, // Keyboard langsung muncul!
          style: const TextStyle(color: Color.fromARGB(255, 0, 0, 0), fontSize: 16), // Font
          maxLines: null, // Unlimited lines
          cursorColor: Colors.blue,
          decoration: const InputDecoration(
            hintText: "Write a caption...",
            hintStyle: TextStyle(color: Colors.grey, fontSize: 16),
            border: InputBorder.none,
          ),
        ),
      ),
    );
  }
}
