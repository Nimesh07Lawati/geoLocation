import 'package:flutter/material.dart';
import 'package:location_app/api/new_view_model.dart';

import 'package:provider/provider.dart';

class LocationView extends StatelessWidget {
  const LocationView({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => LocationViewModel(),
      child: Scaffold(
        appBar: AppBar(title: const Text("Location & WiFi IP")),
        body: SafeArea(
          child: Consumer<LocationViewModel>(
            builder: (context, vm, child) {
              return Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.start,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text("Latitude: ${vm.latitude ?? 'Loading...'}"),
                    Text("Longitude: ${vm.longitude ?? 'Loading...'}"),
                    Text("WiFi IP: ${vm.wifiIpAddress ?? 'Loading...'}"),
                    const SizedBox(height: 20),
                    Text("API Status: ${vm.apiStatus}"),
                    if (vm.errorMessage != null) ...[
                      const SizedBox(height: 10),
                      Text(
                        "Error: ${vm.errorMessage}",
                        style: const TextStyle(color: Colors.red),
                      ),
                    ],
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}
