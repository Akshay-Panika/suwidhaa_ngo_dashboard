import 'package:get/get.dart';
import '../controller/ads_controller.dart';

class AdsBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<AdsController>(() => AdsController());
  }
}