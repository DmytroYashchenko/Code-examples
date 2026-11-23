// Excerpt: relevant production registrations; this is a partial assembly.
import Depin

class AppAssembly: Assembly {

    func assemble(container: Container) {

        container.register(CoreDataStack.self) {
            CoreDataStack()
        }
        .inObjectScope(.container)

        container.register(DatabaseManager.self) {
            DatabaseManager()
        }
        .inObjectScope(.container)

        container.register(DeviceService.self) {
            DeviceService()
        }
        .inObjectScope(.container)

        container.register(GalleryService.self) {
            GalleryService()
        }
        .inObjectScope(.container)

        container.register(GalleryDeletionService.self) {
            GalleryDeletionService()
        }
        .inObjectScope(.container)

        container.register(VideoCompressionService.self) {
            VideoCompressionService()
        }
        .inObjectScope(.container)

        container.register(SwipePhotosService.self) {
            SwipePhotosService()
        }
        .inObjectScope(.container)
    }
}
