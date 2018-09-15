import Vapor
import Leaf
import Fluent

struct IndexContext: Encodable {
    let title: String
    let acronyms: [Acronym]?
}

struct AcronymsContext: Encodable {
    let title: String
    let acronym: Acronym
    let user: User
    let categories: Future<[Category]>
    
}

struct UserContext: Encodable {
    let title: String
    let user: User
    let acronyms: [Acronym]
}

struct AllUsersContext: Encodable {
    let title: String
    let users: [User]
}

struct AllCategoriesContext: Encodable {
    // 1
    let title = "All Categories"
    // 2
    let categories: Future<[Category]>
}

struct EditAcronymContext: Encodable {
    // 1
    let title = "Edit Acronym"
    // 2
    let acronym: Acronym
    // 3
    let users: Future<[User]>
    // 4
    let editing = true
    
    let categories: Future<[Category]>
}

struct CategoryContext: Encodable {
    // 1
    let title: String
    // 2
    let category: Category
    // 3
    let acronyms: Future<[Acronym]>
}

struct CreateAcronymContext: Encodable {
    let title = "Create An Acronym"
    let users: Future<[User]>
}

struct CreateAcronymData: Content {
    let userID: User.ID
    let short: String
    let long: String
    let categories: [String]?
}

struct WebsiteController: RouteCollection {
    func boot(router: Router) throws {
        router.get(use: indexHandler)
        router.get("acronyms", Acronym.parameter, use: acronymHandler)
        router.get("users", User.parameter, use: userHandler)
        router.get("users", use: allUsersHandler)
        router.get("categories", use: allCategoriesHandler)
        router.get("categories", Category.parameter,use: categoryHandler)
        router.get("acronyms", "create", use: createAcronymHandler)
        router.post(CreateAcronymData.self, at: "acronyms", "create",use: createAcronymPostHandler)
        router.get("acronyms", Acronym.parameter, "edit",use: editAcronymHandler)
        router.post("acronyms", Acronym.parameter, "edit",use: editAcronymPostHandler)
        router.post("acronyms", Acronym.parameter, "delete", use: deleteAcronymHandler)
    }
    
    func indexHandler(_ req: Request) throws -> Future<View> {
        return Acronym.query(on: req)
        .all()
            .flatMap(to: View.self) { acronyms in
                let acronymsData = acronyms.isEmpty ? nil : acronyms
                let indexContext = IndexContext(title: "Homepage", acronyms: acronymsData)
                return try req.view().render("index", indexContext)
                
            }
    }
    
    func acronymHandler(_ req: Request) throws -> Future<View> {
        return try req.parameters.next(Acronym.self)
            .flatMap(to: View.self) { acronym in
                return acronym.user.get(on: req)
                    .flatMap(to: View.self) { user in
                        let categories = try acronym.categories.query(on: req).all()
                        let acronymContext = AcronymsContext(title: acronym.short, acronym: acronym, user: user, categories: categories)
                        return try req.view().render("acronym", acronymContext)
                    }
            }
    }
    
    func userHandler(_ req: Request) throws -> Future<View> {
        return try req.parameters.next(User.self)
            .flatMap(to: View.self) { user in
                return try user.acronyms
                    .query(on: req)
                    .all()
                    .flatMap(to: View.self) { acronyms in
                        let context = UserContext(title: user.name,
                                                  user: user,
                                                  acronyms: acronyms)
                        return try req.view().render("user", context)
                }
        }
    }

    func allUsersHandler(_ req: Request) throws -> Future<View> {
        // 2
        return User.query(on: req)
            .all()
            .flatMap(to: View.self) { users in
                // 3
                let context = AllUsersContext(
                    title: "All Users",
                    users: users)
                return try req.view().render("allUsers", context)
        }
    }
    
    func allCategoriesHandler(_ req: Request) throws
        -> Future<View> {
            // 1
            let categories = Category.query(on: req).all()
            let context = AllCategoriesContext(categories: categories)
            // 2
            return try req.view().render("allCategories", context)
    }
    
    func categoryHandler(_ req: Request) throws -> Future<View> {
        // 1
        return try req.parameters.next(Category.self)
            .flatMap(to: View.self) { category in
                // 2
                let acronyms = try category.acronyms.query(on: req).all()
                // 3
                let context = CategoryContext(
                    title: category.name,
                    category: category,
                    acronyms: acronyms)
                // 4
                return try req.view().render("category", context)
        }
    }
    
    func createAcronymHandler(_ req: Request) throws
        -> Future<View> {
            // 1
            let context = CreateAcronymContext(
                users: User.query(on: req).all())
            // 2
            return try req.view().render("createAcronym", context)
    }
    
    // 1
    func createAcronymPostHandler(
        _ req: Request,
        data: CreateAcronymData
        ) throws -> Future<Response> {
        // 2
        let acronym = Acronym(
            short: data.short,
            long: data.long,
            userID: data.userID)
        // 3
        return acronym.save(on: req)
            .flatMap(to: Response.self) { acronym in
                guard let id = acronym.id else {
                    throw Abort(.internalServerError)
                }
                
                // 4
                var categorySaves: [Future<Void>] = []
                // 5
                for category in data.categories ?? [] {
                    try categorySaves.append(
                        Category.addCategory(category, to: acronym, on: req))
                }
                // 6
                let redirect = req.redirect(to: "/acronyms/\(id)")
                return categorySaves.flatten(on: req)
                    .transform(to: redirect)
        }
    }

    func editAcronymHandler(_ req: Request) throws -> Future<View> {
        // 1
        return try req.parameters.next(Acronym.self)
            .flatMap(to: View.self) { acronym in
                // 2
                let context = EditAcronymContext(
                    acronym: acronym,
                    users: User.query(on: req).all(), categories: try acronym.categories.query(on: req).all())
                // 3
                return try req.view().render("createAcronym", context)
        }
    }
    
    func editAcronymPostHandler(_ req: Request) throws
        -> Future<Response> {
            return try flatMap(
                to: Response.self,
                req.parameters.next(Acronym.self),
                req.content
                    .decode(CreateAcronymData.self)) { acronym, data in
                        acronym.short = data.short
                        acronym.long = data.long
                        acronym.userID = data.userID
                        
                        // 2
                        return acronym.save(on: req)
                            .flatMap(to: Response.self) { savedAcronym in
                                guard let id = savedAcronym.id else {
                                    throw Abort(.internalServerError)
                                }
                                
                                // 3
                                return try acronym.categories.query(on: req).all()
                                    .flatMap(to: Response.self) { existingCategories in
                                        // 4
                                        let existingStringArray =
                                            existingCategories.map { $0.name }
                                        
                                        // 5
                                        let existingSet = Set<String>(existingStringArray)
                                        let newSet = Set<String>(data.categories ?? [])
                                        
                                        // 6
                                        let categoriesToAdd = newSet.subtracting(existingSet)
                                        let categoriesToRemove =
                                            existingSet.subtracting(newSet)
                                        
                                        // 7
                                        var categoryResults: [Future<Void>] = []
                                        // 8
                                        for newCategory in categoriesToAdd {
                                            categoryResults.append(
                                                try Category.addCategory(
                                                    newCategory,
                                                    to: acronym,
                                                    on: req))
                                        }
                                        
                                        // 9
                                        for categoryNameToRemove in categoriesToRemove {
                                            // 10
                                            let categoryToRemove = existingCategories.first {
                                                $0.name == categoryNameToRemove
                                            }
                                            // 11
                                            if let category = categoryToRemove {
                                                categoryResults.append(
                                                    acronym.categories.detach(category, on: req))
                                            }
                                        }
                                        // 12
                                        return categoryResults
                                            .flatten(on: req)
                                            .transform(to: req.redirect(to: "/acronyms/\(id)"))
                                }
                        }
            }
    }
    
    func deleteAcronymHandler(_ req: Request) throws
        -> Future<Response> {
            return try req.parameters.next(Acronym.self).delete(on: req)
                .transform(to: req.redirect(to: "/"))
    }
}
