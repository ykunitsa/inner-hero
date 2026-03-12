import Foundation
import SwiftData
import UserNotifications

@Observable
final class NotificationManager {
    private let notificationCenter = UNUserNotificationCenter.current()

    init() {}
    
    // MARK: - Permission Management
    
    func requestAuthorization() async -> Bool {
        do {
            let granted = try await notificationCenter.requestAuthorization(options: [.alert, .sound, .badge])
            return granted
        } catch {
            print("Error requesting notification permissions: \(error)")
            return false
        }
    }
    
    func checkAuthorizationStatus() async -> UNAuthorizationStatus {
        let settings = await notificationCenter.notificationSettings()
        return settings.authorizationStatus
    }
    
    // MARK: - Notification Management
    
    func scheduleNotification(for assignment: ExerciseAssignment) async throws {
        // Remove existing notification if any
        if let notificationId = assignment.notificationId {
            await removeNotification(identifier: notificationId)
        }
        
        guard assignment.isActive else {
            return
        }
        
        // Create notification identifier
        let notificationId = "exercise_\(assignment.id.uuidString)"
        assignment.notificationId = notificationId
        
        // Get exercise name
        let exerciseName = assignment.displayTitle(exposures: [], activityLists: [])
        
        // Create notification content
        let content = UNMutableNotificationContent()
        content.title = String(localized: "Time for exercise")
        content.body = String(format: NSLocalizedString("Reminder: %@", comment: ""), exerciseName)
        content.sound = .default
        content.categoryIdentifier = "EXERCISE_REMINDER"
        
        // Create date components from time
        let calendar = Calendar.current
        let timeComponents = calendar.dateComponents([.hour, .minute], from: assignment.time)
        
        // Create triggers for each selected day
        var triggers: [UNNotificationRequest] = []
        
        for day in assignment.daysOfWeek {
            var dateComponents = DateComponents()
            dateComponents.weekday = day // 1 = Sunday, 2 = Monday, etc.
            dateComponents.hour = timeComponents.hour
            dateComponents.minute = timeComponents.minute
            
            let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: true)
            let request = UNNotificationRequest(
                identifier: "\(notificationId)_\(day)",
                content: content,
                trigger: trigger
            )
            
            triggers.append(request)
        }
        
        // Schedule all notifications
        for request in triggers {
            try await notificationCenter.add(request)
        }
    }
    
    func removeNotification(identifier: String) async {
        // Remove all related notifications (for all days)
        var identifiers: [String] = [identifier]
        
        // Add day-specific identifiers
        for day in 1...7 {
            identifiers.append("\(identifier)_\(day)")
        }
        
        notificationCenter.removePendingNotificationRequests(withIdentifiers: identifiers)
        notificationCenter.removeDeliveredNotifications(withIdentifiers: identifiers)
    }
    
    func updateNotification(for assignment: ExerciseAssignment) async throws {
        try await scheduleNotification(for: assignment)
    }
    
    func cancelNotification(for assignment: ExerciseAssignment) async {
        guard let notificationId = assignment.notificationId else { return }
        await removeNotification(identifier: notificationId)
        assignment.notificationId = nil
    }
    
    // MARK: - Cleanup
    
    func removeAllNotifications() async {
        notificationCenter.removeAllPendingNotificationRequests()
        notificationCenter.removeAllDeliveredNotifications()
    }
}

