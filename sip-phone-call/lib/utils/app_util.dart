class AppUtil {
  static String getShortName(String? fullName) {
    if (fullName == null) return '';
    fullName = fullName.trim();
    if (fullName.isEmpty) return '';
    var segments = fullName.split(' ');
    if (segments.length > 1) {
      return ('${segments[0][0]}${segments[segments.length - 1][0]}').toUpperCase();
    } else {
      return segments.first;
    }
  }

  static List<Map<String, String>> castToListMapStrStr(List<dynamic> arr) {
    List<Map<String, String>> result = [];
    for (var element in arr) {
      Map<dynamic, dynamic> mapItemDynamic = element as Map;
      Map<String, String> mapItemStrStr = {};
      mapItemDynamic.forEach((key, value) {
        mapItemStrStr.addAll({key.toString(): value.toString()});
      });
      result.add(mapItemStrStr);
    }
    return result;
  }
}
