import Foundation
import BinaryDataReader
import BinaryUtilities
public func parse(fileAtPath path: String) throws -> WASM.Module? {
    guard let source = StreamDataSource(path: path) else {
        return nil
    }
    let reader = WASMReader(dataSource: source)
    let binaryModule = try reader.readModule()
    let module = try WASM.Module(binaryModule: binaryModule)
    return module
}
public func parse(data: Data) throws -> WASM.Module {
    let source = StreamDataSource(data: data)
    let reader = WASMReader(dataSource: source)
    let binaryModule = try reader.readModule()
    let module = try WASM.Module(binaryModule: binaryModule)
    return module
}
