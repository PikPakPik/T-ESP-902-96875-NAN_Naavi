import '../models/HikeModel.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LocalStorageHikeDataSource {
  static const String hikeKey = "hike_data";

  Future<void> saveHike(HikeModel hike) async {
    final prefs = await SharedPreferences.getInstance();
    prefs.setString(hikeKey, hike.toJson());
  }

  Future<HikeModel?> getHike() async {
    final prefs = await SharedPreferences.getInstance();
    final hikeJson = prefs.getString(hikeKey);
    if (hikeJson != null) {
      return HikeModel.fromJson(hikeJson);
    }
    return null;
  }

  Future<void> clearHike() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(hikeKey);
  }
}