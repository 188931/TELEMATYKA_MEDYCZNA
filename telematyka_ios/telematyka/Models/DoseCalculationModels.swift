import Foundation

struct DoseCalculateRequest: Codable {
    let patientID: Int
    let visitID: Int?
    let drugName: String
    let dosePerKgMg: Double
    let weightKg: Double

    enum CodingKeys: String, CodingKey {
        case patientID = "patient_id"
        case visitID = "visit_id"
        case drugName = "drug_name"
        case dosePerKgMg = "dose_per_kg_mg"
        case weightKg = "weight_kg"
    }
}

struct DoseCalculateResponse: Decodable {
    let status: String
    let calculatedDoseMg: Double?
    let allergyWarning: String?
    let message: String?

    enum CodingKeys: String, CodingKey {
        case status
        case calculatedDoseMg = "calculated_dose_mg"
        case allergyWarning = "allergy_warning"
        case message
    }
}

struct DoseHistoryRecord: Decodable, Identifiable {
    let id: Int
    let drugName: String
    let dosePerKgMg: Double
    let weightKg: Double
    let calculatedDoseMg: Double
    let allergyWarning: String?
    let createdAt: String

    enum CodingKeys: String, CodingKey {
        case id
        case drugName = "drug_name"
        case dosePerKgMg = "dose_per_kg_mg"
        case weightKg = "weight_kg"
        case calculatedDoseMg = "calculated_dose_mg"
        case allergyWarning = "allergy_warning"
        case createdAt = "created_at"
    }
}

struct DoseCalculatorContext: Identifiable {
    let id = UUID()
    let patientID: Int
    let patientName: String
    let visitID: Int?
    let defaultWeightKg: Double?
    let allergies: String?
}

enum DoseCalculatorLogic {
    static func calculatedDose(dosePerKgMg: Double, weightKg: Double) -> Double {
        (dosePerKgMg * weightKg * 100).rounded() / 100
    }

    static func allergyWarning(drugName: String, allergies: String?) -> String? {
        guard let allergies, !allergies.isEmpty else { return nil }
        let normalized = allergies.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        if normalized == "brak" || normalized == "-" { return nil }
        let drugLower = drugName.lowercased()
        for part in allergies.replacingOccurrences(of: ",", with: ";").split(separator: ";") {
            let allergen = part.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
            if !allergen.isEmpty, drugLower.contains(allergen) {
                return "Uwaga: lek może zawierać alergen (\(part.trimmingCharacters(in: .whitespacesAndNewlines)))"
            }
        }
        return nil
    }
}
