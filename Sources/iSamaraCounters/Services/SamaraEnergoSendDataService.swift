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
import UIKit

public struct SamaraEnergoSendDataService : SendDataService {

    public init() {}

    public let name: String = "SamaraEnergo"
    public let title: String = "СамамараЭнерго"
    public let days = Range<Int>(uncheckedBounds: (lower: 20, upper: 25))

    private let commonHeaders : HTTPHeaders = [
        "Host" : "lk.samaraenergo.ru",
        "X-REQUESTED-WITH": "XMLHttpRequest",
        "Accept": "application/json",
        "Accept-Language": languageId
    ]

    private static var languageId: String {
        if #available(iOS 16.0, *) {
            return NSLocale.current.identifier(.bcp47)
        } else {
            return NSLocale.current.identifier.replacingOccurrences(of: "_", with: "-")
        }
    }

    private let iso8601: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss"
        formatter.calendar = Calendar(identifier: .iso8601)
        formatter.timeZone = TimeZone(secondsFromGMT: 0)
        formatter.locale = Locale(identifier: "en_US_POSIX")
        return formatter
    }()



    private final class AnswerWaiting {
        private let semaphore = DispatchSemaphore(value: 0)
        private var isContinue = false

        func addAnswer(_ isContinue: Bool) {
            self.isContinue = isContinue
            semaphore.signal()
        }

        func isContinueWait() -> Bool {
            semaphore.wait()
            return self.isContinue
        }
    }
    
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
        input.addChecker(BxInputEmptyValueChecker(row: input.electricCounterNumberRow, placeholder: "Значение должно быть не пустым"), for: input.electricCounterNumberRow)
        
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
        if let data = data, let output: SamaraEnergoData.ErrorData = try? parse(data: data) {
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
        let currentSN = input.electricCounterNumberRow.value ?? ""
        
        let getRequest = try! URLRequest(url: "https://lk.samaraenergo.ru/sap/opu/odata/SAP/ZERP_UTILITIES_UMC_PUBLIC_SRV_SRV/GetRegistersToRead?ContractAccountID='\(account)'&SerialNumber=''", method: .get, headers: commonHeaders)
        
        return service(getRequest, isNeedCheckOutput: false).then{ getData -> Promise<Data> in

            var registersData: SamaraEnergoData.GetRegistersData?
            do {
                registersData = try parse(data: getData)
            } catch let error {
                return .init(error: NSError(domain: self.title, code: 404, userInfo: [NSLocalizedDescriptionKey: "\(self.title): Невозможно определить тип устройства: \(error.localizedDescription)"]))
            }

            guard let counterItems = registersData?.d.results
            else {
                return .init(error: NSError(domain: self.title, code: 404, userInfo: [NSLocalizedDescriptionKey: "\(self.title): Нет данных о счётчиках"]))
            }

            
            var firstSerialNumber: String? = nil
            for item in counterItems {
                if let firstSerialNumber = firstSerialNumber {
                    if firstSerialNumber != currentSN && firstSerialNumber != "№\(currentSN)" {
                        return tryToAnswerUser(input, counterItems: counterItems, message: "Есть рассхождение введенного вами сирийного номера для счётчика (\(currentSN)) и зарегистрированного в СамараЭнерго (\(firstSerialNumber))")
                    }
                    if item.serialNumber != firstSerialNumber {
                        return tryToAnswerUser(input, counterItems: counterItems, message: "В СамараЭнерго имеется регистрация нескольких серийных номеров одного счётчика: \(firstSerialNumber), \(item.serialNumber)")
                    }

                } else {
                    firstSerialNumber = item.serialNumber
                }

            }
            
            return finishSending(input, counterItems: counterItems)
        }
    }

    private func finishSending(_ input: SendDataServiceInput, counterItems: [SamaraEnergoData.GetRegistersData.Item]) -> Promise<Data> {
        let account = input.electricAccountNumberRow.value ?? ""
        let email = input.emailRow.value ?? ""
        let date = iso8601.string(from: Date())

        let dayValue = input.dayElectricCountRow.value ?? ""
        let nightValue = input.nightElectricCountRow.value ?? ""

        guard let firstCounter = counterItems.first
        else {
            return .init(error: NSError(domain: self.title, code: 404, userInfo: [NSLocalizedDescriptionKey: "\(self.title): Нет зарегистрированных счётчиков"]))
        }

        let body = SamaraEnergoData.InputData(deviceID: firstCounter.deviceID, readingResult: dayValue, registerID: firstCounter.registerID, readingDateTime: date, contractAccountID: account, email: email)

        if counterItems.count > 1 {
            let nextCounter = counterItems[1]
            let nextData = SamaraEnergoData.InputDataItem(deviceID: nextCounter.deviceID, readingResult: nightValue, registerID: nextCounter.registerID, readingDateTime: date, contractAccountID: account, email: email)
            body.dependentMeterReadingResults = [nextData]
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

    private func tryToAnswerUser(_ input: SendDataServiceInput, counterItems: [SamaraEnergoData.GetRegistersData.Item], message: String) -> Promise<Data> {
        return Promise<AnswerWaiting> { seal in
            guard let controller = input as? UIViewController else {
                seal.reject(NSError(domain: self.title, code: 404, userInfo: [NSLocalizedDescriptionKey: "\(self.title): Что то пошло не так с интерфейсом"]))
                return
            }

            var answerWaiting = AnswerWaiting()

            let okAction = UIAlertAction(title: "Продолжить", style: .default) { _ in
                answerWaiting.addAnswer(true)
            }

            let cancelAction = UIAlertAction(title: "Отменить", style: .cancel) { _ in
                answerWaiting.addAnswer(false)
            }

            let alertController = UIAlertController(title: "Предупреждение", message: "\(title): \(message)", preferredStyle: .alert)
            alertController.addAction(cancelAction)
            alertController.addAction(okAction)
            controller.present(alertController, animated: true, completion: nil)
            seal.fulfill(answerWaiting)
        }.then(on: DispatchQueue.global(qos: .background)){ answerWaiting in
            if answerWaiting.isContinueWait() {
                return finishSending(input, counterItems: counterItems)
            } else {
                return .init(error: NSError(domain: self.title, code: 404, userInfo: [NSLocalizedDescriptionKey: "\(self.title): Отменено пользователем."]))
            }
        }
    }
    
    public func checkOutputData(with data: Data) -> String? {

        if let stringData = String(data: data, encoding: .utf8) {
            print(stringData)
        }

        do {
            let output: SamaraEnergoData.OutputData = try parse(data: data)

            print("SamaraEnergo Output: \(output)")
        } catch let error {
            return "\(self.title): \(error.localizedDescription)"
        }
        
        return nil
    }
    
}
