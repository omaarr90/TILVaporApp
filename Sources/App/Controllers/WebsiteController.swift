import Vapor
import Leaf

struct IndexContext: Encodable {
    let title: String
}

struct WebsiteController: RouteCollection {
    func boot(router: Router) throws {
        router.get(use: indexHandler)
    }
    
    func indexHandler(_ req: Request) throws -> Future<View> {
        let context = IndexContext(title: "Homepage")
        
        return try req.view().render("index", context)
    }
}
