import 'package:cloudinary_public/cloudinary_public.dart';
import 'package:image_picker/image_picker.dart';

class CloudinaryService {
  // Replace these with your actual Cloudinary Dashboard values
  final cloudinary = CloudinaryPublic(
'dpxfrt8zl', 'pumper_profile_pics',
    cache: false
  );

  Future<String?> uploadProfileImage(XFile imageFile) async {
    try {
      CloudinaryResponse response = await cloudinary.uploadFile(
        CloudinaryFile.fromFile(
          imageFile.path,
          resourceType: CloudinaryResourceType.Image,
          folder: 'pumper_profiles', // Optional: saves in a specific folder
        ),
      );
      return response.secureUrl;
    } catch (e) {
      print("Cloudinary Error: $e");
      return null;
    }
  }
}