//
//  WiFiList.swift
//  Workouts_Project
//
//  Created by Kesavan Panchabakesan on 05/06/25.
//


import SwiftUI
import CoreLocation
import SystemConfiguration.CaptiveNetwork

class LocationManager: NSObject, ObservableObject, CLLocationManagerDelegate {
    private let locationManager = CLLocationManager()
    @Published var ssid: String? = nil

    override init() {
        super.init()
        locationManager.delegate = self
    }

    func requestPermissionAndFetchSSID() {
        locationManager.requestWhenInUseAuthorization()
        if CLLocationManager.authorizationStatus() == .authorizedWhenInUse ||
            CLLocationManager.authorizationStatus() == .authorizedAlways {
            fetchSSID()
        }
    }

    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        if manager.authorizationStatus == .authorizedWhenInUse ||
            manager.authorizationStatus == .authorizedAlways {
            fetchSSID()
        }
    }

    private func fetchSSID() {
        guard let interfaces = CNCopySupportedInterfaces() as? [String] else { return }
        for interface in interfaces {
            if let info = CNCopyCurrentNetworkInfo(interface as CFString) as? [String: AnyObject],
               let ssid = info[kCNNetworkInfoKeySSID as String] as? String {
                DispatchQueue.main.async {
                    self.ssid = ssid
                }
                return
            }
        }
        DispatchQueue.main.async {
            self.ssid = "Not connected"
        }
    }

    func openWiFiSettings() {
        if let url = URL(string: "App-Prefs:root=WIFI"), UIApplication.shared.canOpenURL(url) {
            UIApplication.shared.open(url)
        }
    }
}

struct WiFiInfoView: View {
    @StateObject private var locationManager = LocationManager()

    var body: some View {
        VStack(spacing: 20) {
            Text("Connected Wi-Fi SSID:")
                .font(.headline)
            Text(locationManager.ssid ?? "Fetching...")
                .font(.title2)
                .foregroundColor(.blue)

            Button("Refresh SSID") {
                locationManager.requestPermissionAndFetchSSID()
            }

            Button("Open Wi-Fi Settings") {
                locationManager.openWiFiSettings()
            }
        }
        .padding()
        .onAppear {
            locationManager.requestPermissionAndFetchSSID()
        }
    }
}

