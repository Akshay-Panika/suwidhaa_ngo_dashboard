class ApiUrls {
  // NGO Banner APIs
  static const String ngoBannerList = 'v1/ngo/banner/list/';
  static const String ngoBannerCreate = 'v1/ngo/banner/create/';
  static String ngoBannerDetail(int id) => 'v1/ngo/banner/$id/';

  // 👇 NGO Category APIs (New)
  static const String ngoCategoryList = 'v1/ngo/category/list/';
  static const String ngoCategoryCreate = 'v1/ngo/category/create/';
  static String ngoCategoryDetail(int id) => 'v1/ngo/category/$id/';

  static const String ngoServiceList = 'v1/ngo/service/list/';
  static const String ngoServiceCreate = 'v1/ngo/service/create/';
  static String ngoServiceDetail(int id) => 'v1/ngo/service/$id/';

  static const String ngoHistoryList = 'v1/ngo/history/list/';
  static String ngoHistoryDetail(int id) => 'v1/ngo/history/$id/';
  static String ngoHistoryByDonor(int donorId) => 'v1/ngo/history/donor/$donorId/';
  static String ngoHistoryByDonorDelete(int donorId) =>
      'v1/ngo/history/donor/$donorId/delete/';
  // Purana reset-amount hata do, ye lagao:
  static String ngoHistoryUpdateAmount(int pk) =>
      'v1/ngo/history/$pk/update-amount/';


  // NGO Ads APIs
  static const String ngoAdsList = 'v1/ngo/ads/list/';
  static const String ngoAdsCreate = 'v1/ngo/ads/create/';
  static String ngoAdsDetail(int id) => 'v1/ngo/ads/$id/';
}