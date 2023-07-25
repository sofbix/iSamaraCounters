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

    class InputMetterReadingData: Codable {
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

    final class InputData: InputMetterReadingData {
        var DependentMeterReadingResults: [InputMetterReadingData] = []
    }

    class OutputMetterReadingData: InputMetterReadingData {
        var MeterReadingResultID: String = ""
        var Consumption: String = "1.00000000000000"
        var MeterReadingReasonID: String = "09"
        var MeterReadingCategoryID: String = "02"
        var MeterReadingStatusID: String = ""
        var MultipleMeterReadingReasonsFlag: Bool = false
    }

    final class OutputData: Codable {
        final class Results: Codable {
            var result: [OutputMetterReadingData] = []
        }
        final class D: OutputMetterReadingData {
            var DependentMeterReadingResults: Results = Results()
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
