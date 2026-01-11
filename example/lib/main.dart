import 'package:flutter/material.dart';
import 'package:draggable_image/draggable_image.dart';

void main() => runApp(const MyApp());

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'draggable_image example',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const HomePage(),
    );
  }
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  bool _enableZoom = true;

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), duration: const Duration(seconds: 1)),
    );
  }

  void _showOptionsMenu() {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.save_alt),
              title: const Text('Save Image'),
              onTap: () {
                Navigator.pop(context);
                _showSnackBar('Save image tapped!');
              },
            ),
            ListTile(
              leading: const Icon(Icons.share),
              title: const Text('Share Image'),
              onTap: () {
                Navigator.pop(context);
                _showSnackBar('Share image tapped!');
              },
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('draggable_image v0.1.6'),
        actions: [
          IconButton(
            icon: Icon(_enableZoom ? Icons.zoom_in : Icons.zoom_out_map),
            tooltip: _enableZoom ? 'Zoom Enabled' : 'Zoom Disabled',
            onPressed: () => setState(() => _enableZoom = !_enableZoom),
          ),
        ],
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            DraggableImageWidget(
              imageWidth: 300,
              imageHeight: 300,
              imagePath: 'https://picsum.photos/600',
              isNetworkImage: true,
              isDebug: true,
              borderRadius: BorderRadius.circular(16),
              fit: BoxFit.cover,
              fitDoubleTap: BoxFit.contain,
              enableZoom: _enableZoom,

              // New features! 🎉
              onTap: () => _showSnackBar('Image tapped! 👆'),
              onLongPress: _showOptionsMenu,
              overlayColor: Colors.deepPurple,
              overlayOpacity: 0.7,
            ),
            const SizedBox(height: 24),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 32),
              child: Text(
                '• Tap = Snackbar\n• Long press = Menu\n• Double tap = Toggle fit\n• Pinch = Zoom (2 fingers)',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 14, color: Colors.grey),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
