import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:google_fonts/google_fonts.dart';

class CameraPhotoCapture extends StatefulWidget {
  // Updated callback to handle multiple photos
  final Function(List<File>) onPhotosTaken;
  final String title;
  final String description;
  final int maxPhotos;
  final List<File> initialImages; // Parameter for initial images

  const CameraPhotoCapture({
    Key? key,
    required this.onPhotosTaken,
    this.title = "Take Photo",
    this.description = "Capture a photo of the robot",
    this.maxPhotos = 10, // Default maximum number of photos
    this.initialImages = const [], // Default to empty list
  }) : super(key: key);

  @override
  _CameraPhotoCaptureState createState() => _CameraPhotoCaptureState();
}

class _CameraPhotoCaptureState extends State<CameraPhotoCapture>
    with WidgetsBindingObserver {
  late List<File> _images; // Now using a list to store multiple images
  final ImagePicker _picker = ImagePicker();
  bool _processingPhoto = false;

  @override
  void initState() {
    super.initState();
    // Initialize with provided images
    _images = List<File>.from(widget.initialImages);

    // Add observer to detect when app resumes
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    // Remove observer when widget is disposed
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Handle app lifecycle changes
    if (state == AppLifecycleState.resumed && _processingPhoto) {
      _processingPhoto = false;
      // Check if we need to retry loading an image
      // This helps in cases where the camera was opened but the app was paused
    }
  }

  // Use a dedicated method to launch the camera using system intent
  Future<void> _launchCamera() async {
    if (_images.length >= widget.maxPhotos) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Maximum of ${widget.maxPhotos} photos reached'),
            backgroundColor: Colors.orange,
          ),
        );
      }
      return;
    }

    try {
      setState(() {
        _processingPhoto = true;
      });

      // Use image_picker to launch the camera in a separate process
      final XFile? photo = await _picker.pickImage(
        source: ImageSource.camera,
        preferredCameraDevice: CameraDevice.rear,
        imageQuality: 85,
        maxWidth: 1024,
        maxHeight: 1024,
      );

      // Handle the result when the app is brought back to foreground
      if (!mounted) return;

      setState(() {
        _processingPhoto = false;
      });

      if (photo != null) {
        final File imageFile = File(photo.path);
        setState(() {
          _images.add(imageFile);
        });
        widget.onPhotosTaken(_images); // Pass the entire list
      }
    } catch (e) {
      setState(() {
        _processingPhoto = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  // Remove a specific image from the list
  void _removeImage(int index) {
    setState(() {
      _images.removeAt(index);
    });
    widget.onPhotosTaken(_images); // Update parent with new list
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.2),
            spreadRadius: 2,
            blurRadius: 5,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      margin: const EdgeInsets.all(8.0),
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.camera_alt, color: Colors.blue),
              const SizedBox(width: 8),
              Text(
                widget.title.toUpperCase(),
                style: GoogleFonts.museoModerno(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey,
                ),
              ),
              const Spacer(),
              if (_images.isNotEmpty)
                Text(
                  "${_images.length}/${widget.maxPhotos} photos",
                  style: GoogleFonts.museoModerno(
                    fontSize: 12,
                    color: Colors.grey.shade600,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            widget.description,
            style: GoogleFonts.museoModerno(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),

          // Display captured photos in a horizontal scrollable list
          if (_images.isNotEmpty)
            SizedBox(
              height: 120,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: _images.length,
                itemBuilder: (context, index) {
                  return Stack(
                    children: [
                      Container(
                        margin:
                            const EdgeInsets.only(right: 8, top: 8, left: 2),
                        width: 100,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.grey.shade300),
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Image.file(
                            _images[index],
                            fit: BoxFit.cover,
                            height: double.infinity,
                          ),
                        ),
                      ),
                      Positioned(
                        top: 0,
                        right: 0,
                        child: GestureDetector(
                          onTap: () => _removeImage(index),
                          child: Container(
                            decoration: BoxDecoration(
                              color: Colors.red.withOpacity(0.7),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.close,
                              color: Colors.white,
                              size: 18,
                            ),
                          ),
                        ),
                      ),
                    ],
                  );
                },
              ),
            )
          else
            // Placeholder when no images are captured
            Container(
              width: double.infinity,
              height: 120,
              decoration: BoxDecoration(
                color: Colors.grey[200],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey.shade300),
              ),
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.image,
                      size: 50,
                      color: Colors.grey[400],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      "No photos yet",
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
            ),

          const SizedBox(height: 16),

          // Camera Button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _processingPhoto ? null : _launchCamera,
              icon: _processingPhoto
                  ? SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2,
                      ))
                  : const Icon(Icons.camera_alt),
              label: Text(
                _images.isEmpty ? "Take Photo" : "Take Another Photo",
                style: GoogleFonts.museoModerno(
                  fontWeight: FontWeight.bold,
                ),
              ),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 12),
                backgroundColor: _images.length >= widget.maxPhotos
                    ? Colors.grey
                    : Colors.blue,
                foregroundColor: Colors.white,
                disabledBackgroundColor: Colors.blue.shade300,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// Optional function to easily use the widget with the same interface as before
// Now returns a list of Files instead of a single File
Widget buildCameraCapture(
  Function(List<File>) onPhotosTaken, {
  String title = "Take Photo",
  String description = "Capture a photo of the robot",
  int maxPhotos = 10,
  List<File> initialImages = const [],
}) {
  return CameraPhotoCapture(
    onPhotosTaken: onPhotosTaken,
    title: title,
    description: description,
    maxPhotos: maxPhotos,
    initialImages: initialImages,
  );
}

// For backward compatibility - wrapper that adapts the new interface to the old one
Widget buildSingleCameraCapture(
  Function(File) onPhotoTaken, {
  String title = "Take Photo",
  String description = "Capture a photo of the robot",
  File? initialImage,
}) {
  return CameraPhotoCapture(
    onPhotosTaken: (photos) {
      if (photos.isNotEmpty) {
        onPhotoTaken(photos.last); // Pass only the most recent photo
      }
    },
    title: title,
    description: description,
    maxPhotos: 1, // Limit to one photo for backward compatibility
    initialImages: initialImage != null ? [initialImage] : [],
  );
}
