import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class EventDescriptionPage extends StatefulWidget {
  final String initialText;
  const EventDescriptionPage({super.key, required this.initialText});

  @override
  State<EventDescriptionPage> createState() => _EventDescriptionPageState();
}

class _EventDescriptionPageState extends State<EventDescriptionPage> {
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

  void _save() {
    Navigator.pop(context, _controller.text);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leadingWidth: 150.w,
        // TOMBOL BACK (MERAH) SESUAI GAMBAR
        leading: TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(
            "Back",
            style: TextStyle(
              color: Colors.red, // Sesuai desain image_9539af.png
              fontSize: 34.sp,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        title: Text(
          "Description",
          style: TextStyle(color: Colors.black, fontSize: 40.sp, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        actions: [
          // TOMBOL SAVE (BIRU) SESUAI GAMBAR
          TextButton(
            onPressed: _save,
            child: Text(
              "Save",
              style: TextStyle(
                color: Colors.blue, // Sesuai desain image_9539af.png
                fontSize: 34.sp,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          SizedBox(width: 20.w),
        ],
      ),
      body: Padding(
        padding: EdgeInsets.all(40.w),
        child: Column(
          children: [
            Expanded(
              child: TextField(
                controller: _controller,
                maxLines: null, // Unlimited lines
                keyboardType: TextInputType.multiline,
                autofocus: true,
                style: TextStyle(fontSize: 40.sp, color: Colors.black, height: 1.5),
                decoration: InputDecoration(
                  hintText: "Type Description Here...",
                  hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 40.sp),
                  border: InputBorder.none,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
