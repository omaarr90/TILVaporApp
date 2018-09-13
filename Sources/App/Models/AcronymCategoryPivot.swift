import FluentPostgreSQL
import Foundation

final class AcronymCategoryPivot: PostgreSQLUUIDPivot, ModifiablePivot {
    var id: UUID?
    
    var acronymID: Acronym.ID
    var categoryID: Category.ID
    
    typealias Left = Acronym
    typealias Right = Category
    
    static let leftIDKey: LeftIDKey = \.acronymID
    static let rightIDKey: RightIDKey = \.categoryID
    
    init(_ acronym: Acronym, _ category: Category) throws {
        self.acronymID = try acronym.requireID()
        self.categoryID = try category.requireID()
    }
}

extension AcronymCategoryPivot: Migration {
    // 2
    static func prepare(
        on connection: PostgreSQLConnection
        ) -> Future<Void> {
        // 3
        return Database.create(self, on: connection) { builder in
            // 4
            try addProperties(to: builder)
            // 5
            builder.reference(
                from: \.acronymID,
                to: \Acronym.id,
                onDelete: .cascade)
            // 6
            builder.reference(
                from: \.categoryID,
                to: \Category.id,
                onDelete: .cascade)
        }
    }
}
