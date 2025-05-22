import Foundation
import WatchConnectivity
import HealthKit

// Модель данных для обмена между iPhone и Apple Watch
struct WatchWorkoutData: Codable {
    let timestamp: TimeInterval
    let heartRate: Double
    let activeEnergy: Double
    let workoutDuration: Double
    let steps: Int
    let distance: Double // в метрах
    let rounds: Int
    let isInProgress: Bool
    
    // Дополнительные данные о тренировке
    let avgHeartRate: Double
    let maxHeartRate: Double
    let restingHeartRate: Double?
    
    // Идентификатор тренировки для синхронизации
    let workoutId: String
}

// Модель для передачи настроек таймера с iPhone на Apple Watch
struct TimerSettings: Codable, Equatable {
    let roundDuration: Int // в секундах
    let restDuration: Int // в секундах
    let numberOfRounds: Int
    let exercises: [ExerciseData]?
    
    static let `default` = TimerSettings(
        roundDuration: 180,
        restDuration: 60,
        numberOfRounds: 6,
        exercises: []
    )
}

// Упрощенная модель упражнения для передачи на Apple Watch
struct ExerciseData: Codable, Identifiable, Equatable {
    let id: String
    let name: String
    let rounds: Int
}

// Команды для обмена между устройствами
enum WatchCommand: String, Codable {
    case startWorkout
    case pauseWorkout
    case resumeWorkout
    case stopWorkout
    case updateSettings
    case requestData
    case syncExercises
}

// Структура для отправки команд
struct WatchMessage: Codable {
    let command: WatchCommand
    let data: Data?
    
    init(command: WatchCommand, data: Data? = nil) {
        self.command = command
        self.data = data
    }
}

// Класс для обработки WatchConnectivity на стороне Apple Watch
class WatchConnectivityHandler: NSObject, ObservableObject {
    static let shared = WatchConnectivityHandler()
    
    // Настройки таймера, полученные с iPhone
    @Published var timerSettings = TimerSettings.default
    
    // Состояние тренировки
    @Published var isWorkoutActive = false
    @Published var isWorkoutPaused = false
    
    // Текущие данные тренировки
    @Published var heartRate: Double = 70
    @Published var activeEnergy: Double = 0
    @Published var steps: Int = 0
    @Published var distance: Double = 0
    @Published var workoutDuration: TimeInterval = 0
    @Published var rounds: Int = 0
    
    // Статистика тренировки
    @Published var avgHeartRate: Double = 0
    @Published var maxHeartRate: Double = 0
    @Published var restingHeartRate: Double? = nil
    
    // Идентификатор текущей тренировки
    private var currentWorkoutId: String?
    
    // Таймер для отправки данных на iPhone
    private var sendDataTimer: Timer?
    
    // Здоровье
    private let healthStore = HKHealthStore()
    private var workoutSession: HKWorkoutSession?
    private var heartRateQuery: HKQuery?
    
    private override init() {
        super.init()
        activateSession()
    }
    
    // Активация сессии WatchConnectivity
    private func activateSession() {
        guard WCSession.isSupported() else { return }
        WCSession.default.delegate = self
        WCSession.default.activate()
    }
    
    // Запрос разрешений на доступ к данным здоровья
    func requestHealthAuthorization() {
        guard HKHealthStore.isHealthDataAvailable() else { return }
        
        let typesToRead: Set<HKObjectType> = [
            HKObjectType.quantityType(forIdentifier: .heartRate)!,
            HKObjectType.quantityType(forIdentifier: .activeEnergyBurned)!,
            HKObjectType.quantityType(forIdentifier: .distanceWalkingRunning)!,
            HKObjectType.quantityType(forIdentifier: .stepCount)!,
            HKObjectType.quantityType(forIdentifier: .restingHeartRate)!
        ]
        
        healthStore.requestAuthorization(toShare: nil, read: typesToRead) { success, error in
            if !success {
                print("Ошибка запроса доступа к HealthKit: \(error?.localizedDescription ?? "Неизвестная ошибка")")
            }
        }
    }
    
    // Начало тренировки
    func startWorkout() {
        isWorkoutActive = true
        isWorkoutPaused = false
        currentWorkoutId = UUID().uuidString
        rounds = 1
        
        // Сброс статистики
        activeEnergy = 0
        steps = 0
        distance = 0
        workoutDuration = 0
        maxHeartRate = 0
        avgHeartRate = 0
        
        // Начало отслеживания данных здоровья
        startHeartRateMonitoring()
        
        // Запуск таймера для отправки данных на iPhone
        startSendingDataToPhone()
    }
    
    // Пауза тренировки
    func pauseWorkout() {
        isWorkoutPaused = true
    }
    
    // Возобновление тренировки
    func resumeWorkout() {
        isWorkoutPaused = false
    }
    
    // Завершение тренировки
    func stopWorkout() {
        isWorkoutActive = false
        isWorkoutPaused = false
        
        // Остановка отслеживания данных здоровья
        stopHeartRateMonitoring()
        
        // Остановка таймера отправки данных
        sendDataTimer?.invalidate()
        sendDataTimer = nil
        
        // Отправка финальных данных на iPhone
        sendWorkoutDataToPhone()
    }
    
    // Начало мониторинга пульса
    private func startHeartRateMonitoring() {
        guard HKHealthStore.isHealthDataAvailable() else { return }
        
        // Симуляция изменения пульса для демонстрации
        Timer.scheduledTimer(withTimeInterval: 3, repeats: true) { [weak self] _ in
            guard let self = self, self.isWorkoutActive, !self.isWorkoutPaused else { return }
            
            // Симуляция пульса
            let baseHeartRate: Double = 120
            let variation = Double.random(in: -15...25)
            self.heartRate = max(60, min(200, baseHeartRate + variation))
            
            // Обновление максимального и среднего пульса
            if self.heartRate > self.maxHeartRate {
                self.maxHeartRate = self.heartRate
            }
            
            // Обновление среднего пульса (простая симуляция)
            self.avgHeartRate = (self.avgHeartRate * 0.8) + (self.heartRate * 0.2)
            
            // Увеличение калорий
            self.activeEnergy += Double.random(in: 1...3)
            
            // Увеличение шагов
            self.steps += Int.random(in: 5...20)
            
            // Увеличение дистанции (в метрах)
            self.distance += Double.random(in: 3...15)
            
            // Увеличение длительности тренировки
            self.workoutDuration += 3
        }
    }
    
    // Остановка мониторинга пульса
    private func stopHeartRateMonitoring() {
        // В реальном приложении здесь будет остановка запросов к HealthKit
    }
    
    // Запуск таймера для отправки данных на iPhone
    private func startSendingDataToPhone() {
        sendDataTimer = Timer.scheduledTimer(withTimeInterval: 5, repeats: true) { [weak self] _ in
            self?.sendWorkoutDataToPhone()
        }
    }
    
    // Отправка данных тренировки на iPhone
    private func sendWorkoutDataToPhone() {
        guard WCSession.default.isReachable, let workoutId = currentWorkoutId else { return }
        
        let workoutData = WatchWorkoutData(
            timestamp: Date().timeIntervalSince1970,
            heartRate: heartRate,
            activeEnergy: activeEnergy,
            workoutDuration: workoutDuration,
            steps: steps,
            distance: distance,
            rounds: rounds,
            isInProgress: isWorkoutActive,
            avgHeartRate: avgHeartRate,
            maxHeartRate: maxHeartRate,
            restingHeartRate: restingHeartRate,
            workoutId: workoutId
        )
        
        do {
            // Сначала кодируем данные тренировки
            let workoutDataEncoded = try JSONEncoder().encode(workoutData)
            // Создаем сообщение с уже закодированными данными
            let message = WatchMessage(command: .requestData, data: workoutDataEncoded)
            let messageData = try JSONEncoder().encode(message)
            let messageDict = ["message": messageData]
            
            WCSession.default.sendMessage(messageDict, replyHandler: { reply in
                print("Данные тренировки отправлены успешно: \(reply)")
            }, errorHandler: { error in
                print("Ошибка отправки данных тренировки: \(error.localizedDescription)")
            })
        } catch {
            print("Ошибка кодирования данных тренировки: \(error.localizedDescription)")
        }
    }
    
    // Увеличение количества раундов
    func incrementRound() {
        rounds += 1
        sendWorkoutDataToPhone()
    }
    
    // Применение настроек таймера, полученных с iPhone
    func applyTimerSettings(_ settings: TimerSettings) {
        DispatchQueue.main.async {
            self.timerSettings = settings
        }
    }
}

// MARK: - WCSessionDelegate
extension WatchConnectivityHandler: WCSessionDelegate {
    func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?) {
        if let error = error {
            print("Ошибка активации WCSession: \(error.localizedDescription)")
        } else {
            print("WCSession активирована успешно")
        }
    }
    
    func session(_ session: WCSession, didReceiveMessage message: [String : Any]) {
        handleReceivedMessage(message)
    }
    
    func session(_ session: WCSession, didReceiveMessage message: [String : Any], replyHandler: @escaping ([String : Any]) -> Void) {
        handleReceivedMessage(message)
        replyHandler(["status": "received"])
    }
    
    private func handleReceivedMessage(_ message: [String: Any]) {
        guard let messageData = message["message"] as? Data else {
            print("Неверный формат сообщения")
            return
        }
        
        do {
            let watchMessage = try JSONDecoder().decode(WatchMessage.self, from: messageData)
            
            switch watchMessage.command {
            case .startWorkout:
                DispatchQueue.main.async {
                    self.startWorkout()
                }
                
            case .pauseWorkout:
                DispatchQueue.main.async {
                    self.pauseWorkout()
                }
                
            case .resumeWorkout:
                DispatchQueue.main.async {
                    self.resumeWorkout()
                }
                
            case .stopWorkout:
                DispatchQueue.main.async {
                    self.stopWorkout()
                }
                
            case .updateSettings:
                if let data = watchMessage.data,
                   let settings = try? JSONDecoder().decode(TimerSettings.self, from: data) {
                    DispatchQueue.main.async {
                        self.applyTimerSettings(settings)
                    }
                }
                
            case .requestData:
                // Отправляем текущие данные в ответ на запрос
                sendWorkoutDataToPhone()
                
            case .syncExercises:
                if let data = watchMessage.data,
                   let exercises = try? JSONDecoder().decode([ExerciseData].self, from: data) {
                    print("Получены упражнения: \(exercises.count)")
                }
            }
        } catch {
            print("Ошибка декодирования сообщения: \(error.localizedDescription)")
        }
    }
}
