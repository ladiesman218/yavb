import Vapor
import Fluent

struct LoadSiteSettings: LifecycleHandler {
    func didBootAsync(_ application: Application) async throws {
        async let count = try? User.query(on: application.db).filter(\.$role == .webmaster).count()
        async let settings = try? Settings.query(on: application.db).first()
        
        webmasterExists =  await (count == 1) ? true : false
        
        if let settings = await settings {
            allowRegistration = settings.allowRegistration
            allowComment = settings.allowComment
        }
    }
}
