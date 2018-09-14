import Vapor
import Leaf

struct IndexContext: Encodable {
    let title: String
    let acronyms: [Acronym]?
}

struct AcronymsContext: Encodable {
    let title: String
    let acronym: Acronym
    let user: User
    
}

struct WebsiteController: RouteCollection {
    func boot(router: Router) throws {
        router.get(use: indexHandler)
        router.get(Acronym.parameter, use: acronymHandler)
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
                        let acronymContext = AcronymsContext(title: acronym.short, acronym: acronym, user: user)
                        return try req.view().render("acronym", acronymContext)
                    }
            }
    }
}
