import 'package:connectivity_plus/connectivity_plus.dart';

enum ConnectivityState {
  offline,
  online
}

class CheckNetworkService {
    final Connectivity? connectivity;

    CheckNetworkService({this.connectivity});

    Future<ConnectivityState> checkConnection() async  {
      final conn = connectivity ?? Connectivity();
      final connectivityResults = await conn.checkConnectivity();

      if (connectivityResults.contains(ConnectivityResult.mobile) ||
          connectivityResults.contains(ConnectivityResult.wifi)) {
        return ConnectivityState.online;
      } else {
        return ConnectivityState.offline;
      }
    }

}