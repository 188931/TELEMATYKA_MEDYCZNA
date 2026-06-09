import MapKit
import SwiftUI

struct RouteMapView: View {
    @ObservedObject var viewModel: AppViewModel
    @State private var stops: [RouteStop] = []
    @State private var cameraPosition: MapCameraPosition = .automatic
    @State private var routePolyline: MKPolyline?
    @State private var isLoading = false
    @State private var resolvedCoordinates: [Int: CLLocationCoordinate2D] = [:]

    private let geocoder = GeocodingService()

    private var routeSummary: String {
        guard !stops.isEmpty else { return "Brak wizyt na dziś" }
        let names = stops.enumerated().map { "\($0.offset + 1). \($0.element.fullName)" }
        return "Trasa z \(stops.count) przystankami: \(names.joined(separator: ", "))"
    }

    var body: some View {
        VStack(spacing: 0) {
            if stops.isEmpty && !isLoading {
                ContentUnavailableView("Brak wizyt na dziś", systemImage: "map")
                    .accessibilityLabel("Brak wizyt na dziś do wyświetlenia na mapie")
            } else {
                Map(position: $cameraPosition) {
                    UserAnnotation()
                    ForEach(stops) { stop in
                        if let coordinate = resolvedCoordinates[stop.visitID] {
                            Marker(stop.fullName, coordinate: coordinate)
                        }
                    }
                    if let routePolyline {
                        MapPolyline(routePolyline)
                            .stroke(.blue, lineWidth: 4)
                    }
                }
                .frame(height: 280)
                .accessibilityElement(children: .ignore)
                .accessibilityLabel(routeSummary)
                .accessibilityHint("Mapa pokazuje kolejność wizyt. Szczegóły w liście poniżej.")
                .accessibilityAddTraits(.isImage)

                List {
                    ForEach(Array(stops.enumerated()), id: \.element.id) { index, stop in
                        HStack {
                            Text("\(index + 1).")
                                .font(.headline)
                                .foregroundStyle(.secondary)
                                .accessibilityHidden(true)
                            VStack(alignment: .leading, spacing: 4) {
                                Text(stop.fullName).font(.headline)
                                Text(stop.address ?? "Brak adresu")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                                Text(stop.visitDate).font(.caption2)
                            }
                            Spacer()
                            if resolvedCoordinates[stop.visitID] != nil {
                                Button("Nawiguj") {
                                    openMaps(to: stop, at: index)
                                }
                                .buttonStyle(.bordered)
                                .controlSize(.small)
                                .minimumTapTarget()
                                .accessibilityLabel("Nawiguj do \(stop.fullName)")
                                .accessibilityHint("Otwiera Mapy Apple z trasą dojazdu")
                            }
                        }
                        .accessibilityElement(children: .combine)
                        .accessibilityLabel(stopRowLabel(index: index, stop: stop))
                        .accessibilityAction(named: "Nawiguj") {
                            guard resolvedCoordinates[stop.visitID] != nil else { return }
                            openMaps(to: stop, at: index)
                        }
                    }
                }
                .listStyle(.insetGrouped)
                .accessibilityLabel("Lista przystanków trasy")
            }
        }
        .accessibleLoading(isLoading, label: "Ładowanie trasy")
        .task { await loadRoute() }
        .refreshable { await loadRoute() }
    }

    private func stopRowLabel(index: Int, stop: RouteStop) -> String {
        "Przystanek \(index + 1). \(stop.fullName). Adres \(stop.address ?? "brak"). Godzina \(stop.visitDate)"
    }

    private func loadRoute() async {
        isLoading = true
        defer { isLoading = false }
        do {
            stops = try await viewModel.fetchTodayRoute()
            await resolveCoordinates()
            await buildRoute()
        } catch {
            viewModel.showError(error.localizedDescription)
        }
    }

    private func resolveCoordinates() async {
        var coords: [Int: CLLocationCoordinate2D] = [:]
        for stop in stops {
            if let lat = stop.latitude, let lng = stop.longitude {
                coords[stop.visitID] = CLLocationCoordinate2D(latitude: lat, longitude: lng)
                continue
            }
            guard let address = stop.address, !address.isEmpty else { continue }
            do {
                let coordinate = try await geocoder.coordinates(for: address)
                coords[stop.visitID] = coordinate
                try? await viewModel.updatePatientCoordinates(
                    patientID: stop.patientID,
                    latitude: coordinate.latitude,
                    longitude: coordinate.longitude
                )
            } catch {
                continue
            }
        }
        resolvedCoordinates = coords
        if let first = coords.values.first {
            cameraPosition = .region(MKCoordinateRegion(
                center: first,
                span: MKCoordinateSpan(latitudeDelta: 0.12, longitudeDelta: 0.12)
            ))
        }
    }

    private func orderedCoordinates() -> [CLLocationCoordinate2D] {
        stops.compactMap { resolvedCoordinates[$0.visitID] }
    }

    private func buildRoute() async {
        let ordered = orderedCoordinates()
        guard !ordered.isEmpty else {
            routePolyline = nil
            return
        }

        var combinedPoints: [CLLocationCoordinate2D] = []
        for index in 0..<ordered.count {
            let request = MKDirections.Request()
            if index == 0 {
                request.source = MKMapItem.forCurrentLocation()
            } else {
                request.source = MKMapItem(placemark: MKPlacemark(coordinate: ordered[index - 1]))
            }
            request.destination = MKMapItem(placemark: MKPlacemark(coordinate: ordered[index]))
            request.transportType = .automobile

            if let response = try? await MKDirections(request: request).calculate(),
               let route = response.routes.first {
                combinedPoints.append(contentsOf: route.polyline.coordinates)
            }
        }

        guard !combinedPoints.isEmpty else { return }
        routePolyline = MKPolyline(coordinates: combinedPoints, count: combinedPoints.count)
    }

    private func openMaps(to stop: RouteStop, at index: Int) {
        guard let coordinate = resolvedCoordinates[stop.visitID] else { return }
        let destination = MKMapItem(placemark: MKPlacemark(coordinate: coordinate))
        destination.name = stop.fullName

        if index == 0 {
            destination.openInMaps(launchOptions: [MKLaunchOptionsDirectionsModeKey: MKLaunchOptionsDirectionsModeDriving])
            return
        }

        let previousCoordinate = orderedCoordinates()[index - 1]
        let source = MKMapItem(placemark: MKPlacemark(coordinate: previousCoordinate))
        source.name = stops[index - 1].fullName
        MKMapItem.openMaps(
            with: [source, destination],
            launchOptions: [MKLaunchOptionsDirectionsModeKey: MKLaunchOptionsDirectionsModeDriving]
        )
    }
}

private extension MKPolyline {
    var coordinates: [CLLocationCoordinate2D] {
        var coords = Array(repeating: CLLocationCoordinate2D(), count: pointCount)
        getCoordinates(&coords, range: NSRange(location: 0, length: pointCount))
        return coords
    }
}
