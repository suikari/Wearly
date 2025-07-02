import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';

class LocationHelper {
  // 위치 권한 요청 + 위도/경도 반환
  static Future<Position?> getCurrentPosition() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      throw Exception('위치 서비스가 꺼져 있습니다.');
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        throw Exception('위치 권한이 거부되었습니다.');
      }
    }

    if (permission == LocationPermission.deniedForever) {
      throw Exception('위치 권한이 영구적으로 거부되었습니다.');
    }

    return await Geolocator.getCurrentPosition(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
      ),
    );
  }

  // 주소 문자열 가져오기
  static Future<String> getAddressFromLatLng(Position position) async {
    List<Placemark> placemarks = await placemarkFromCoordinates(
      position.latitude,
      position.longitude,
    );

    if (placemarks.isNotEmpty) {
      final placemark = placemarks.first;
      // print('Placemark: ${placemark.toJson()}');
      var street = placemark.street ?? '';
      street = street.replaceAll('대한민국', '').trim();

      final reg = RegExp(r'(?:(\S+(?:도|광역시)))?\s?(\S+시)?\s?(\S+구)?\s?(\S+동)?');
      final match = reg.firstMatch(street);

      String road = '';
      final regRoad = RegExp(r'(\S+(?:대로|길|로|가))');
      final roadMatch = regRoad.firstMatch(street);
      if (roadMatch != null) {
        road = roadMatch.group(1) ?? '';
      }

      if (match != null) {
        final doOrMetro = match.group(1) ?? '';
        final city = match.group(2) ?? '';
        final gu = match.group(3) ?? '';
        final dong = match.group(4) ?? '';

        // print('doOrMetro: $doOrMetro');
        // print('city: $city');
        // print('gu: $gu');
        // print('dong: $dong');
        // print('road: $road');

        final parts = <String>[
          city.isNotEmpty ? city.replaceAll('시', '') : doOrMetro.replaceAll(RegExp(r'(도|광역시)'), ''),
          dong.isNotEmpty ? dong : road,
        ].where((e) => e.isNotEmpty).toList();

        return parts.join(', ');
      } else {
        return placemark.administrativeArea ?? '위치 정보 없음';
      }
    }
    return '주소를 찾을 수 없습니다.';
  }

}
