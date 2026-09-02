import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:google_fonts/google_fonts.dart';

class SmartImageWidget extends StatelessWidget {
  final String imageUrl;
  final BoxFit fit;
  final Widget? placeholder;
  final Widget? errorWidget;

  const SmartImageWidget({
    super.key,
    required this.imageUrl,
    this.fit = BoxFit.cover,
    this.placeholder,
    this.errorWidget,
  });

  @override
  Widget build(BuildContext context) {
    // Check if it's a base64 data URL
    if (imageUrl.startsWith('data:image/')) {
      return _buildBase64Image();
    }
    
    // Check if it's a regular HTTP URL
    if (imageUrl.startsWith('http')) {
      return _buildNetworkImage();
    }
    
    // Fallback to error widget
    return _buildErrorWidget();
  }

  Widget _buildBase64Image() {
    try {
      // Extract base64 data from data URL
      final base64String = imageUrl.split(',').last;
      final imageBytes = base64Decode(base64String);
      
      return Image.memory(
        imageBytes,
        fit: fit,
        errorBuilder: (context, error, stackTrace) {
          print('❌ Error loading base64 image: $error');
          return _buildErrorWidget();
        },
      );
    } catch (e) {
      print('❌ Error parsing base64 image: $e');
      return _buildErrorWidget();
    }
  }

  Widget _buildNetworkImage() {
    return CachedNetworkImage(
      imageUrl: imageUrl,
      fit: fit,
      placeholder: (context, url) => placeholder ?? _buildPlaceholder(),
      errorWidget: (context, url, error) {
        print('❌ Error loading network image: $error');
        return errorWidget ?? _buildErrorWidget();
      },
    );
  }

  Widget _buildPlaceholder() {
    return Container(
      color: Colors.grey[200],
      child: const Center(
        child: CircularProgressIndicator(),
      ),
    );
  }

  Widget _buildErrorWidget() {
    return Container(
      color: Colors.grey[200],
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.image_not_supported,
            size: 48,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 8),
          Text(
            'Image not available',
            style: GoogleFonts.nunito(
              fontSize: 14,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }
}
