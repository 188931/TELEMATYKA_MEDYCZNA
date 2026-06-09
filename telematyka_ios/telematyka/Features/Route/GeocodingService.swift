import CoreLocation
import Foundation

@MainActor
final class GeocodingService {
    private let geocoder = CLGeocoder()

    func coordinates(for address: String) async throws -> CLLocationCoordinate2D {
        let placemarks = try await geocoder.geocodeAddressString(address)
        guard let location = placemarks.first?.location else {
            throw APIError.message("Nie udało się znaleźć adresu.")
        }
        return location.coordinate
    }
}
