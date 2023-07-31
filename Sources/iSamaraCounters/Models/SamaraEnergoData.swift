//
//  SamaraEnergoData.swift
//  
//
//  Created by Sergey Balalaev on 31.07.2023.
//

import Foundation

public struct SamaraEnergoData {

    var domain = ""

    public struct GetRegistersData: Codable {

        let d: D

        struct Item: Codable {
            let deviceID: String
            let registerID: String
            let registerTypeID: String
            let readingUnit: String
            let integerPlaces: String
            let decimalPlaces: String
            let noMeterReadingOrderFlag:Bool
            let previousMeterReadingResult: String
            let previousMeterReadingDate: String
            let previousMeterReadingReasonID: String
            let previousMeterReadingCategoryID: String
            let serialNumber: String

            private enum CodingKeys: String, CodingKey {
                case deviceID = "DeviceID"
                case registerID = "RegisterID"
                case registerTypeID = "RegisterTypeID"
                case readingUnit = "ReadingUnit"
                case integerPlaces = "IntegerPlaces"
                case decimalPlaces = "DecimalPlaces"
                case noMeterReadingOrderFlag = "NoMeterReadingOrderFlag"
                case previousMeterReadingResult = "PreviousMeterReadingResult"
                case previousMeterReadingDate = "PreviousMeterReadingDate"
                case previousMeterReadingReasonID = "PreviousMeterReadingReasonID"
                case previousMeterReadingCategoryID = "PreviousMeterReadingCategoryID"
                case serialNumber = "SerialNumber"
            }
        }

        struct D: Codable {
            let results: [Item]
        }
    }

    public class InputDataItem: Encodable {
        var deviceID: String
        var meterReadingNoteID: String
        var readingResult: String
        var registerID: String
        var readingDateTime: String
        var contractAccountID: String
        var email: String

        private enum CodingKeys: String, CodingKey {
            case deviceID = "DeviceID"
            case meterReadingNoteID = "MeterReadingNoteID"
            case readingResult = "ReadingResult"
            case registerID = "RegisterID"
            case readingDateTime = "ReadingDateTime"
            case contractAccountID = "ContractAccountID"
            case email = "Email"
        }

        init(deviceID: String,
             meterReadingNoteID: String = "",
             readingResult: String,
             registerID: String,
             readingDateTime: String,
             contractAccountID: String,
             email: String = ""
        ) {
            self.deviceID = deviceID
            self.meterReadingNoteID = meterReadingNoteID
            self.readingResult = readingResult
            self.registerID = registerID
            self.readingDateTime = readingDateTime
            self.contractAccountID = contractAccountID
            self.email = email
        }
    }

    public final class InputData: InputDataItem {
        var dependentMeterReadingResults: [InputDataItem] = []

        private enum CodingKeys: String, CodingKey {
            case dependentMeterReadingResults = "DependentMeterReadingResults"
        }

        public override func encode(to encoder: Encoder) throws {
            var container = encoder.container(keyedBy: CodingKeys.self)
            try super.encode(to: encoder)
            try container.encode(dependentMeterReadingResults, forKey: .dependentMeterReadingResults)
        }
    }

    public class OutputDataItem: Decodable {
        var deviceID: String
        var meterReadingNoteID: String
        var readingResult: String
        var registerID: String
        var readingDateTime: String
        var contractAccountID: String
        var email: String

        var meterReadingResultID: String
        var consumption: String
        var meterReadingReasonID: String
        var meterReadingCategoryID: String
        var meterReadingStatusID: String
        var multipleMeterReadingReasonsFlag: Bool

        private enum CodingKeys: String, CodingKey {
            case deviceID = "DeviceID"
            case meterReadingNoteID = "MeterReadingNoteID"
            case readingResult = "ReadingResult"
            case registerID = "RegisterID"
            case readingDateTime = "ReadingDateTime"
            case contractAccountID = "ContractAccountID"
            case email = "Email"

            case meterReadingResultID = "MeterReadingResultID"
            case consumption = "Consumption"
            case meterReadingReasonID = "MeterReadingReasonID"
            case meterReadingCategoryID = "MeterReadingCategoryID"
            case meterReadingStatusID = "MeterReadingStatusID"
            case multipleMeterReadingReasonsFlag = "MultipleMeterReadingReasonsFlag"
        }
    }

    public final class OutputData: Decodable {
        final class Results: Decodable {
            var results: [OutputDataItem]
        }
        final class D: OutputDataItem {

            var dependentMeterReadingResults: Results?

            private enum CodingKeys: String, CodingKey {
                case dependentMeterReadingResults = "DependentMeterReadingResults"
            }

            required init(from decoder: Decoder) throws {
                let container = try decoder.container(keyedBy: CodingKeys.self)
                dependentMeterReadingResults = try container.decodeIfPresent(Results.self, forKey: .dependentMeterReadingResults)
                try super.init(from: decoder)
            }
        }
        var d: D
    }

    public struct ErrorData: Codable {

        let error: Error

        struct Error: Codable {
            let code: String
            let message: Message
        }

        struct Message: Codable {
            let lang: String
            let value: String
        }
    }

}
