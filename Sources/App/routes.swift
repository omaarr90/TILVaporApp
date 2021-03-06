import Vapor
import Fluent

/// Register your application's routes here.
public func routes(_ router: Router) throws {
    // Basic "Hello, world!" example
    router.get("hello") { req in
        return "Hello, world!"
    }
    
    let acronymController = AcronymController()
    try router.register(collection: acronymController)
    
    let userController = UserController()
    try router.register(collection: userController)
    
    let categoriesController = CategoryController()
    try router.register(collection: categoriesController)
    
    let websiteController = WebsiteController()
    try router.register(collection: websiteController)
}
