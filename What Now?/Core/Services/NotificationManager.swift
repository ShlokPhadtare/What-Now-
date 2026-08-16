//
//  NotificationManager.swift
//  What Now?
//

import Foundation
import UserNotifications

/// Handles local notifications for the app.
final class NotificationManager {
    static let shared = NotificationManager()
    
    private init() {}
    
    func requestAuthorization() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { granted, error in
            if let error = error {
                print("Notification permission error: \(error)")
            }
        }
    }
    
    func scheduleFocusCompletion(taskTitle: String, in seconds: TimeInterval) {
        let content = UNMutableNotificationContent()
        content.title = "Focus Session Complete"
        content.body = "You finished your session for '\(taskTitle)'."
        content.sound = .default
        
        // Use a minimum of 1 second for the trigger
        let timeInterval = max(1, seconds)
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: timeInterval, repeats: false)
        let request = UNNotificationRequest(identifier: "focus_complete", content: content, trigger: trigger)
        
        UNUserNotificationCenter.current().add(request)
    }
    
    func cancelFocusCompletion() {
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: ["focus_complete"])
    }
    
    func scheduleReminder(for task: WNTask, at date: Date) {
        let content = UNMutableNotificationContent()
        content.title = "Task Reminder"
        content.body = "It's time to start '\(task.title)'."
        content.sound = .default
        
        let components = Calendar.current.dateComponents([.year, .month, .day, .hour, .minute], from: date)
        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: false)
        
        let request = UNNotificationRequest(identifier: "task_\(task.id.uuidString)", content: content, trigger: trigger)
        UNUserNotificationCenter.current().add(request)
    }
}
