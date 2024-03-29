//
//  SamaraEnergoData.swift
//  
//
//  Created by Sergey Balalaev on 31.07.2023.
//

import Foundation

public struct SamaraEnergoData {

    public let domain: String
    public let getRegistersMethod: String
    public let postMeterReadingMethod: String

    public init(domain: String = "https://lk.samaraenergo.ru",
                  getRegistersMethod: String = "/sap/opu/odata/SAP/ZERP_UTILITIES_UMC_PUBLIC_SRV_SRV/GetRegistersToRead",
                  postMeterReadingMethod: String = "/sap/opu/odata/SAP/ZERP_UTILITIES_UMC_PUBLIC_SRV_SRV/MeterReadingResults")
    {
        self.domain = domain
        self.getRegistersMethod = getRegistersMethod
        self.postMeterReadingMethod = postMeterReadingMethod
    }

    public struct GetRegistersData: Codable {

        public let d: D

        public struct Item: Codable {

            public let deviceID: String
            public let registerID: String
            public let registerTypeID: String
            public let readingUnit: String
            public let integerPlaces: String
            public let decimalPlaces: String
            public let noMeterReadingOrderFlag:Bool
            public let previousMeterReadingResult: String
            public let previousMeterReadingDate: String
            public let previousMeterReadingReasonID: String
            public let previousMeterReadingCategoryID: String
            public let serialNumber: String

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

            public init(deviceID: String, registerID: String, registerTypeID: String, readingUnit: String, integerPlaces: String, decimalPlaces: String, noMeterReadingOrderFlag: Bool, previousMeterReadingResult: String, previousMeterReadingDate: String, previousMeterReadingReasonID: String, previousMeterReadingCategoryID: String, serialNumber: String) {
                self.deviceID = deviceID
                self.registerID = registerID
                self.registerTypeID = registerTypeID
                self.readingUnit = readingUnit
                self.integerPlaces = integerPlaces
                self.decimalPlaces = decimalPlaces
                self.noMeterReadingOrderFlag = noMeterReadingOrderFlag
                self.previousMeterReadingResult = previousMeterReadingResult
                self.previousMeterReadingDate = previousMeterReadingDate
                self.previousMeterReadingReasonID = previousMeterReadingReasonID
                self.previousMeterReadingCategoryID = previousMeterReadingCategoryID
                self.serialNumber = serialNumber
            }

        }

        public struct D: Codable {
            public let results: [Item]
        }

        public init(results: [Item]) {
            d = D(results: results)
        }
    }

    public class InputDataItem: Codable {
        public var deviceID: String
        public var meterReadingNoteID: String
        public var readingResult: String
        public var registerID: String
        public var readingDateTime: String
        public var contractAccountID: String
        public var email: String

        private enum CodingKeys: String, CodingKey {
            case deviceID = "DeviceID"
            case meterReadingNoteID = "MeterReadingNoteID"
            case readingResult = "ReadingResult"
            case registerID = "RegisterID"
            case readingDateTime = "ReadingDateTime"
            case contractAccountID = "ContractAccountID"
            case email = "Email"
        }

        public init(deviceID: String,
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

        public var dependentMeterReadingResults: [InputDataItem]

        private enum CodingKeys: String, CodingKey {
            case dependentMeterReadingResults = "DependentMeterReadingResults"
        }

        public required init(from decoder: Decoder) throws {
            let container = try decoder.container(keyedBy: CodingKeys.self)
            dependentMeterReadingResults = try container.decode([InputDataItem].self, forKey: .dependentMeterReadingResults)
            try super.init(from: decoder)
        }

        public override func encode(to encoder: Encoder) throws {
            var container = encoder.container(keyedBy: CodingKeys.self)
            try super.encode(to: encoder)
            try container.encode(dependentMeterReadingResults, forKey: .dependentMeterReadingResults)
        }

        public init(dependentMeterReadingResults: [SamaraEnergoData.InputDataItem] = [],
                      deviceID: String,
                      meterReadingNoteID: String = "",
                      readingResult: String,
                      registerID: String,
                      readingDateTime: String,
                      contractAccountID: String,
                      email: String = "")
        {
            self.dependentMeterReadingResults = dependentMeterReadingResults
            super.init(deviceID: deviceID, readingResult: readingResult, registerID: registerID, readingDateTime: readingDateTime, contractAccountID: contractAccountID, email: email)
        }
    }

    public class OutputDataItem: Codable {
        public var deviceID: String
        public var meterReadingNoteID: String
        public var readingResult: String
        public var registerID: String
        public var readingDateTime: String
        public var contractAccountID: String
        public var email: String

        public var meterReadingResultID: String
        public var consumption: String
        public var meterReadingReasonID: String
        public var meterReadingCategoryID: String
        public var meterReadingStatusID: String
        public var multipleMeterReadingReasonsFlag: Bool

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

        public init(deviceID: String, meterReadingNoteID: String, readingResult: String, registerID: String, readingDateTime: String, contractAccountID: String, email: String, meterReadingResultID: String, consumption: String, meterReadingReasonID: String, meterReadingCategoryID: String, meterReadingStatusID: String, multipleMeterReadingReasonsFlag: Bool) {
            self.deviceID = deviceID
            self.meterReadingNoteID = meterReadingNoteID
            self.readingResult = readingResult
            self.registerID = registerID
            self.readingDateTime = readingDateTime
            self.contractAccountID = contractAccountID
            self.email = email
            self.meterReadingResultID = meterReadingResultID
            self.consumption = consumption
            self.meterReadingReasonID = meterReadingReasonID
            self.meterReadingCategoryID = meterReadingCategoryID
            self.meterReadingStatusID = meterReadingStatusID
            self.multipleMeterReadingReasonsFlag = multipleMeterReadingReasonsFlag
        }
    }

    public final class OutputData: Codable {

        public final class D: OutputDataItem {

            public final class Results: Codable {
                var results: [OutputDataItem]

                public init(results: [SamaraEnergoData.OutputDataItem]) {
                    self.results = results
                }
            }

            public var dependentMeterReadingResults: Results?

            private enum CodingKeys: String, CodingKey {
                case dependentMeterReadingResults = "DependentMeterReadingResults"
            }

            public required init(from decoder: Decoder) throws {
                let container = try decoder.container(keyedBy: CodingKeys.self)
                dependentMeterReadingResults = try container.decodeIfPresent(Results.self, forKey: .dependentMeterReadingResults)
                try super.init(from: decoder)
            }

            public override func encode(to encoder: Encoder) throws {
                var container = encoder.container(keyedBy: CodingKeys.self)
                try super.encode(to: encoder)
                try container.encodeIfPresent(dependentMeterReadingResults, forKey: .dependentMeterReadingResults)
            }

            public init(deviceID: String, meterReadingNoteID: String, readingResult: String, registerID: String, readingDateTime: String, contractAccountID: String, email: String, meterReadingResultID: String, consumption: String, meterReadingReasonID: String, meterReadingCategoryID: String, meterReadingStatusID: String, multipleMeterReadingReasonsFlag: Bool, dependentMeterReadingResults: Results? = nil) {
                self.dependentMeterReadingResults = dependentMeterReadingResults
                super.init(
                    deviceID: deviceID,
                    meterReadingNoteID: meterReadingNoteID,
                    readingResult: readingResult,
                    registerID: registerID,
                    readingDateTime: readingDateTime,
                    contractAccountID: contractAccountID,
                    email: email,
                    meterReadingResultID: meterReadingResultID,
                    consumption: consumption,
                    meterReadingReasonID: meterReadingReasonID,
                    meterReadingCategoryID: meterReadingCategoryID,
                    meterReadingStatusID: meterReadingStatusID,
                    multipleMeterReadingReasonsFlag: multipleMeterReadingReasonsFlag
                )
            }
        }
        public var d: D

        public init(d: D) {
            self.d = d
        }
    }

    public struct ErrorData: Codable {

        public let error: Error

        public struct Error: Codable {
            public let code: String
            public let message: Message
        }

        public struct Message: Codable {
            public let lang: String
            public let value: String
        }

        public init(code: String, lang: String, value: String) {
            error = Error(code: code, message: Message(lang: lang, value: value))
        }
    }

}
