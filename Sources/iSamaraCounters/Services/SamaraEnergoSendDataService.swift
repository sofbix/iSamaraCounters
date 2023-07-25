//
//  SamaraEnergoSendDataService.swift
//  SamaraCounter
//
//  Created by Sergey Balalaev on 24.07.2023.
//

import Foundation
import PromiseKit
import Alamofire
import BxInputController

public struct SamaraEnergoSendDataService : SendDataService {

    public init() {}

    public let name: String = "SamaraEnergo"
    public let title: String = "СамамараЭнерго"
    public let days = Range<Int>(uncheckedBounds: (lower: 20, upper: 25))

#warning("Get from Location Accept-Language?")
    private let commonHeaders : HTTPHeaders = [
        "Host" : "lk.samaraenergo.ru",
        "X-REQUESTED-WITH": "XMLHttpRequest",
        "Accept": "application/json",
        "Accept-Language": "ru-RU"
    ]

    private let iso8601: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss"
        formatter.calendar = Calendar(identifier: .iso8601)
        formatter.timeZone = TimeZone(secondsFromGMT: 0)
        formatter.locale = Locale(identifier: "en_US_POSIX")
        return formatter
    }()
    
    public func addCheckers(for input: SendDataServiceInput){
        let electricAccountNumberChecker = BxInputBlockChecker(row: input.electricAccountNumberRow, subtitle: "Введите непустой номер из чисел", handler: { row in
            let value = input.electricAccountNumberRow.value ?? ""
            
            guard value.count > 0 else {
                return false
            }
            return value.isNumber
        })
        input.addChecker(electricAccountNumberChecker, for: input.electricAccountNumberRow)

        // You can get this value from setup request and check with SerialNumber from request.
        #warning("You can get this value from setup request and check with SerialNumber from request.")
        //input.addChecker(BxInputEmptyValueChecker(row: input.electricCounterNumberRow, placeholder: "Значение должно быть не пустым"), for: input.electricCounterNumberRow)
        
        let dayElectricCountChecker = BxInputBlockChecker(row: input.dayElectricCountRow, subtitle: "Укажите целочисленное значение счетчика", handler: { row in
            let value = input.dayElectricCountRow.value ?? ""
            
            guard value.count > 0 else {
                return false
            }
            return value.isNumber
        })
        input.addChecker(dayElectricCountChecker, for: input.dayElectricCountRow)
        
        let nightElectricCountChecker = BxInputBlockChecker(row: input.nightElectricCountRow, subtitle: "Оставте пустым или целочисленное значение", handler: { row in
            let value = input.nightElectricCountRow.value ?? ""
            
            if value.count == 0 {
                return true
            }
            return value.isNumber
        })
        input.addChecker(nightElectricCountChecker, for: input.nightElectricCountRow)
    }
    
    func requestParams(index: Int, value: String) -> String {
        return "&counters%5B87278_\(index)%5D%5Bvalue%5D=\(value)&counters%5B87278_\(index)%5D%5BrowId%5D=87278&counters%5B87278_\(index)%5D%5Btarif%5D=\(index)"
    }

    private func parse<T: Decodable>(data: Data) throws -> T {
        return try JSONDecoder().decode(T.self, from: data)
    }

    private func encode<T: Encodable>(value: T) throws -> Data {
        return try JSONEncoder().encode(value)
    }

    public func hasError(statusCode: Int, data: Data?) -> String? {
        guard statusCode >= 300 || statusCode < 200 else {
            return nil
        }
        if let data = data, let output: ErrorData = try? parse(data: data) {
            var message = "\(self.title): \(output.error.message.value)"
            if output.error.code == "ZISU_UMC_ODATA/034" || output.error.code == "ZISU_UMC_ODATA/033" {
                message += ". Проверте правильность ввода лицевого счета по электроэнергии."
            }
            return message
        }
        let localizedMessage = HTTPURLResponse.localizedString(forStatusCode: statusCode)
        let message = "\(self.title): \(localizedMessage) (\(statusCode))"
        return message
    }
    
    public func map(_ input: SendDataServiceInput) -> Promise<Data> {
        
        let account = input.electricAccountNumberRow.value ?? ""
        
        let getRequest = try! URLRequest(url: "https://lk.samaraenergo.ru/sap/opu/odata/SAP/ZERP_UTILITIES_UMC_PUBLIC_SRV_SRV/GetRegistersToRead?ContractAccountID='\(account)'&SerialNumber=''", method: .get, headers: commonHeaders)
        
        return service(getRequest, isNeedCheckOutput: false).then{ getData -> Promise<Data> in

            let email = input.emailRow.value ?? ""
            let date = iso8601.string(from: Date())

            #warning("Catch this and add self.title to error message")
            let registersData: GetRegistersData = try parse(data: getData)

            #warning("You can check registersData.SerialNumber with electricCounterNumberRow")


            let counterItems = registersData.d.results
            
            guard let firstCounter = counterItems.first else {
                return .init(error: NSError(domain: self.title, code: 404, userInfo: [NSLocalizedDescriptionKey: "\(self.title): Нет зарегистрированных счётчиков"]))
            }
            
            let dayValue = input.dayElectricCountRow.value ?? ""
            let nightValue = input.nightElectricCountRow.value ?? ""

            let body = InputData(DeviceID: firstCounter.DeviceID, ReadingResult: dayValue, RegisterID: firstCounter.RegisterID, ReadingDateTime: date, ContractAccountID: account, Email: email)

            if counterItems.count > 1 {
                let nextCounter = counterItems[1]
                let nextData = InputDataItem(DeviceID: nextCounter.DeviceID, ReadingResult: nightValue, RegisterID: nextCounter.RegisterID, ReadingDateTime: date, ContractAccountID: account, Email: email)
                body.DependentMeterReadingResults = [nextData]
            }
            
            guard let bodyData = try? encode(value: body) else {
                return .init(error: NSError(domain: self.title, code: 404, userInfo: [NSLocalizedDescriptionKey: "\(self.title): Неверный запрос на сервер"]))
            }

            if let stringData = String(data: bodyData, encoding: .utf8) {
                print(stringData)
            }
            
            var headers : HTTPHeaders = commonHeaders
            headers["Content-Type"] = "application/json"
            headers["Content-Length"] = "\(bodyData.count)"

            var request = try! URLRequest(url: "https://lk.samaraenergo.ru/sap/opu/odata/SAP/ZERP_UTILITIES_UMC_PUBLIC_SRV_SRV/MeterReadingResults", method: .post, headers: headers)
            request.httpBody = bodyData
            
            return service(request)
        }
    }
    
    public func checkOutputData(with data: Data) -> String? {

        if let stringData = String(data: data, encoding: .utf8) {
            print(stringData)
        }

        do {
            let output: OutputData = try parse(data: data)

            print("SamaraEnergo Output: \(output)")
        } catch let error {
            return "\(self.title): \(error.localizedDescription)"
        }
        
        return nil
    }
    
}
