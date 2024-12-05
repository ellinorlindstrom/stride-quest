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
    // Add these convenience methods
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
    
    func setDailyProgress(_ progress: [RouteProgress.DailyProgress]) {
        do {
            self.dailyProgressData = try JSONEncoder().encode(progress)
        } catch {
            print("Error encoding daily progress: \(error)")
        }
    }
    
    func getDailyProgress() -> [RouteProgress.DailyProgress] {
        guard let data = dailyProgressData else { return [] }
        do {
            return try JSONDecoder().decode([RouteProgress.DailyProgress].self, from: data)
        } catch {
            print("Error decoding daily progress: \(error)")
            return []
        }
    }
}
