//
//  SamaraEnergoData.swift
//  
//
//  Created by Sergey Balalaev on 25.07.2023.
//

import Foundation

extension SamaraEnergoSendDataService {

    struct GetRegistersData: Codable {

        let d: D
        
        struct Item: Codable {
            let DeviceID: String
            let RegisterID: String
            let RegisterTypeID: String
            let ReadingUnit: String
            let IntegerPlaces: String
            let DecimalPlaces: String
            let NoMeterReadingOrderFlag:Bool
            let PreviousMeterReadingResult: String
            let PreviousMeterReadingDate: String
            let PreviousMeterReadingReasonID: String
            let PreviousMeterReadingCategoryID: String
            let SerialNumber: String
        }

        struct D: Codable {
            let results: [Item]
        }
    }

    class InputDataItem: Encodable {
        var DeviceID: String
        var MeterReadingNoteID: String
        var ReadingResult: String
        var RegisterID: String
        var ReadingDateTime: String
        var ContractAccountID: String
        var Email: String

        init(DeviceID: String,
             MeterReadingNoteID: String = "",
             ReadingResult: String,
             RegisterID: String,
             ReadingDateTime: String,
             ContractAccountID: String,
             Email: String = ""
        ) {
            self.DeviceID = DeviceID
            self.MeterReadingNoteID = MeterReadingNoteID
            self.ReadingResult = ReadingResult
            self.RegisterID = RegisterID
            self.ReadingDateTime = ReadingDateTime
            self.ContractAccountID = ContractAccountID
            self.Email = Email
        }
    }

    final class InputData: InputDataItem {
        var DependentMeterReadingResults: [InputDataItem] = []

        private enum CodingKeys: String, CodingKey {
            case DependentMeterReadingResults
        }

        override func encode(to encoder: Encoder) throws {
            var container = encoder.container(keyedBy: CodingKeys.self)
            try super.encode(to: encoder)
            try container.encode(DependentMeterReadingResults, forKey: .DependentMeterReadingResults)
        }
    }

    class OutputDataItem: Decodable {
        var MeterReadingResultID: String
        var Consumption: String
        var MeterReadingReasonID: String
        var MeterReadingCategoryID: String
        var MeterReadingStatusID: String
        var MultipleMeterReadingReasonsFlag: Bool
    }

    final class OutputData: Decodable {
        final class Results: Decodable {
            var result: [OutputDataItem]
        }
        final class D: OutputDataItem {

            var DependentMeterReadingResults: Results?

            private enum CodingKeys: String, CodingKey {
                case DependentMeterReadingResults
            }

            required init(from decoder: Decoder) throws {
                let container = try decoder.container(keyedBy: CodingKeys.self)
                DependentMeterReadingResults = try container.decodeIfPresent(Results.self, forKey: .DependentMeterReadingResults)
                try super.init(from: decoder)
            }
        }
        var d: D
    }

    struct ErrorData: Codable {

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
