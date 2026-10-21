import 'package:latlong2/latlong.dart';
import 'crime_report.dart';


class CrimeMarkerModel {

  final String id;
  final String crimeType;
  final String status;
  final LatLng location;
  final DateTime reportedAt;


  const CrimeMarkerModel({

    required this.id,
    required this.crimeType,
    required this.status,
    required this.location,
    required this.reportedAt,

  });



  factory CrimeMarkerModel.fromCrimeReport(
      CrimeReport crime) {

    return CrimeMarkerModel(

      id: crime.id,

      crimeType: crime.categoryName,

      status: crime.statusName,

      location: LatLng(
        crime.latitude,
        crime.longitude,
      ),

      reportedAt:
          crime.incidentDatetime,

    );

  }

}