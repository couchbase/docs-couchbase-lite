//
//  CodableCombine.swift
//  CouchbaseLite
//
//  Copyright © 2025 couchbase. All rights reserved.
//

import Foundation
import CouchbaseLiteSwift
import Combine

// tag::codable-data-model[]
class Task: Codable {
    @DocumentID var id: String?
    var title: String
    var completed: Bool?
}
// end::codable-data-model[]

class CodableCombine {
    var database: Database!
    var collection: Collection!
    var replicator: Replicator!
    var query: Query!
    var task: Task!
    var tasks: [Task] = []
    var cancellables = Set<AnyCancellable>()
    
    func codable() throws {
        // tag::get-codable-doc[]
        let document = try collection.document(id: task.id!, as: Task.self)
        // end::get-codable-doc[]
        print(document!)
        
        // tag::save-codable-doc[]
        try collection.save(from: task)
        // end::save-codable-doc[]
        
        // tag::delete-codable-doc[]
        try collection.delete(for: task)
        // end::delete-codable-doc[]
        
        // tag::purge-codable-doc[]
        try collection.purge(for: task)
        // end::purge-codable-doc[]
        
        let query = try database.createQuery("SELECT meta().id AS id, title FROM _default.tasks")
        // tag::get-codable-result[]
        let results = try query.execute().allResults()
        for result in results {
            task = try result.data(as: Task.self)
        }
        // end::get-codable-result[]
        
        // tag::get-codable-result-all[]
        tasks = try query.execute().data(as: Task.self)
        // end::get-codable-result-all[]
    }
    
    func saveConflictCodable() throws {
        // tag::conflict-save-codable-doc[]
        let resolved = try collection.save(from: task) { newTask, existingTask in
            newTask.title = "New Task"
            newTask.completed = false
            return true
        }
        // end::conflict-save-codable-doc[]
        print(resolved)
    }
    
    func saveConcurrencyCodable() throws {
        // tag::concurrency-save-codable-doc[]
        let resolved = try collection.save(from: task, concurrencyControl: .failOnConflict)
        // end::concurrency-save-codable-doc[]
        print(resolved)
    }
    
    func deleteConcurrencyCodable() throws {
        // tag::concurrency-delete-codable-doc[]
        let resolved = try collection.delete(for: task, concurrencyControl: .failOnConflict)
        // end::concurrency-delete-codable-doc[]
        print(resolved)
    }
    
    func combine() throws {
        // tag::publish-result-changes[]
        query.changePublisher()
            .map { try! $0.results?.data(as: Task.self) ?? [] }
            .sink { [weak self] tasks in
                self?.tasks = tasks
            }
            .store(in: &cancellables)
        // end::publish-result-changes[]
        
        // tag::publish-collection-changes[]
        collection.changePublisher()
            .sink { change in print("Collection \(change.collection.name) changed.") }
            .store(in: &cancellables)
        // end:publish-collection-changes[]
        
        // tag::publish-doc-changes[]
        collection.documentChangePublisher(for: task.id!)
            .sink { change in
                print("Task \(change.documentID) in collection \(change.collection.name) changed.")
            }
            .store(in: &cancellables)
        // end::publish-doc-changes[]
        
        // tag::publish-replicator-changes[]
        replicator.changePublisher()
            .sink { change in print("Replicator status changed: \(change)") }
            .store(in: &cancellables)
        // end::publish-replicator-changes[]
        
        // tag::publish-replication-changes[]
        replicator.documentReplicationPublisher()
            .sink { change in
                change.documents.forEach { task in
                    print("Task \(task.id) replicated.")
                }
            }
            .store(in: &cancellables)
        // end::publish-replication-changes[]
    }
}
