import 'dart:math';

Map<String, int> convertGRID_GPS(double lat, double lon) {
  const double RE = 6371.00877, GRID = 5.0,
      SLAT1 = 30.0, SLAT2 = 60.0, OLON = 126.0, OLAT = 38.0,
      XO = 43, YO = 136;
  double DEGRAD = pi / 180.0;
  double re = RE / GRID;
  double slat1 = SLAT1 * DEGRAD;
  double slat2 = SLAT2 * DEGRAD;
  double olon = OLON * DEGRAD;
  double olat = OLAT * DEGRAD;
  double sn = log(cos(slat1) / cos(slat2)) /
      log(tan(pi * 0.25 + slat2 * 0.5) / tan(pi * 0.25 + slat1 * 0.5));
  double sf = pow(tan(pi * 0.25 + slat1 * 0.5), sn) * cos(slat1) / sn;
  double ro = re * sf / pow(tan(pi * 0.25 + olat * 0.5), sn);
  double ra = re * sf / pow(tan(pi * 0.25 + lat * DEGRAD * 0.5), sn);
  double theta = lon * DEGRAD - olon;
  if (theta > pi) theta -= 2.0 * pi;
  if (theta < -pi) theta += 2.0 * pi;
  theta *= sn;
  int x = (ra * sin(theta) + XO + 0.5).floor();
  int y = (ro - ra * cos(theta) + YO + 0.5).floor();
  return {'x': x, 'y': y};
}
