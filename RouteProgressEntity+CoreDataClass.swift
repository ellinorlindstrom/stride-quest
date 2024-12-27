//
//  RouteProgressEntity+CoreDataClass.swift
//  StrideQuest
//
//  Created by Ellinor Lindström on 2024-12-05.
//
//

import Foundation
import CoreData

public class RouteProgressEntity: NSManagedObject {
    // For completed milestones
    func setCompletedMilestones(_ milestones: Set<UUID>) {
        do {
            self.completedMilestones = try JSONEncoder().encode(milestones)
        } catch {
            print("Error encoding milestones: \(error)")
        }
    }
    
    func getCompletedMilestones() -> Set<UUID> {
        guard let data = completedMilestones else { return [] }
        do {
            return try JSONDecoder().decode(Set<UUID>.self, from: data)
        } catch {
            print("Error decoding milestones: \(error)")
            return []
        }
    }
    
    func setDailyProgress(_ progress: [String: Double]) {
        do {
            self.dailyProgressData = try JSONEncoder().encode(progress)
        } catch {
            print("Error encoding daily progress: \(error)")
        }
    }
    
    func getDailyProgress() -> [String: Double] {
        guard let data = dailyProgressData else { return [:] }
        do {
            return try JSONDecoder().decode([String: Double].self, from: data)
        } catch {
            print("Error decoding daily progress: \(error)")
            return [:]
        }
    }
    
    // Helper method to convert old format to new if needed
    func getDailyProgressArray() -> [RouteProgress.DailyProgress] {
        let progressDict = getDailyProgress()
        
        return progressDict.compactMap { dateString, distance in
            guard let date = Self.dateFormatter.date(from: dateString) else { return nil }
            return RouteProgress.DailyProgress(date: date, distance: distance)
        }.sorted { $0.date < $1.date }
    }
    
    static private let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter
    }()
}
