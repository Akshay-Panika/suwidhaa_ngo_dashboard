import 'package:get/get.dart';
import '../controller/donation_controller.dart';

class DonationBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<DonationController>(() => DonationController());
  }
}