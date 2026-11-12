import 'package:get/get_core/src/get_main.dart';
import 'package:get/get_instance/src/bindings_interface.dart';
import 'package:get/get_instance/src/extension_instance.dart';
import '../../feature/ads/controller/ads_controller.dart';
import '../../feature/banner/controller/banner_controller.dart';
import '../../feature/category/controller/category_controller.dart';
import '../../feature/donation/controller/donation_controller.dart';
import '../../feature/service/controller/service_controller.dart';

class AppBindings implements Bindings {
  @override
  void dependencies() {
    Get.put<BannerController>(BannerController(), permanent: true);
    Get.put<CategoryController>(CategoryController(), permanent: true);
    Get.put<ServiceController>(ServiceController(), permanent: true);
    Get.put<DonationController>(DonationController(), permanent: true); // 👈 Add
    Get.put<AdsController>(AdsController(), permanent: true); // 👈 Add

  }
}