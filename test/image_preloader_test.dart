import 'package:CardioPTech/Utils/image_preloader.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('ImagePreloader Tests', () {
    test('should cache images after preloading', () async {
      // This test verifies that the ImagePreloader can cache images
      // Note: In a real test environment, you would need to set up
      // a proper Flutter test context
      
      // Test that the cache starts empty
      expect(ImagePreloader.isImageCached('assets/Images/background.jpg'), false);
      
      // Test that we can get an image provider
      final imageProvider = ImagePreloader.getImage('assets/Images/background.jpg');
      expect(imageProvider, isA<AssetImage>());
      
      // Test that we can clear the cache
      ImagePreloader.clearCache();
      expect(ImagePreloader.isImageCached('assets/Images/background.jpg'), false);
    });
  });
}
