import 'package:geobase/geobase.dart';

class HikeLine {
  final LineString line;
  final Map<String, dynamic> info;

  HikeLine({required this.line, required this.info});
  @override
  String toString() {
    return 'HikeLine(info: $info, points: ${line.chain.positionCount})';
  }
}