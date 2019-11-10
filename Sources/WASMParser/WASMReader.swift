//
//  WASMReader.swift
//  BinaryDataReader
//
//  Created by Lukas Möller on 11.11.19.
//

import Foundation
import BinaryDataReader
import BinaryUtilities

class WASMReader: BinaryDataReader {
    enum WASMReaderError: Error {
        case invalidMagicByteSequence
        case invalidVersion
        case invalidSectionId(Byte)
        case invalidValueType
        case invalidImportDescriptionType
        case invalidTableElementType
        case invalidLimitType
        case invalidExportDescriptionType
    }
    func readSectionId() throws -> WASMBinaryFormat.SectionId {
        let byte = try read()
        if let sectionId = WASMBinaryFormat.SectionId(rawValue: byte) {
            return sectionId
        }
        throw WASMReaderError.invalidSectionId(byte)
    }
    public func readModule() throws -> WASMBinaryFormat.Module {
        let str = try readFixedLengthString(numberOfBytes: 4)
        if str != "\0asm" {
            throw WASMReaderError.invalidMagicByteSequence
        }
        let version = try readUInt32()
        if version != 1 {
            throw WASMReaderError.invalidVersion
        }
        var sections: [WASMBinaryFormat.Section] = []
        while source.hasData {
            let sectionId = try readSectionId()
            switch sectionId {
            case .customSection:
                sections.append(try readCustomSection())
            case .typeSection:
                sections.append(try readTypeSection())
            case .importSection:
                sections.append(try readImportSection())
            case .functionSection:
                sections.append(try readFunctionSection())
            case .tableSection:
                sections.append(try readTableSection())
            case .memorySection:
                sections.append(try readMemorySection())
            case .globalSection:
                sections.append(try readGlobalSection())
            case .exportSection:
                sections.append(try readExportSection())
            case .startSection:
                sections.append(try readStartSection())
            case .elementSection:
                sections.append(try readElementSection())
            case .codeSection:
                sections.append(try readCodeSection())
            case .dataSection:
                sections.append(try readDataSection())
            }
        }
        return WASMBinaryFormat.Module(version: Int(version), sections: sections)
    }
    func readSectionHeader() throws -> WASMBinaryFormat.SectionHeader {
        let size = Int(try readULEB128())
        let start = source.offset
        let end = start + size
        return WASMBinaryFormat.SectionHeader(sectionStart: start, sectionEnd: end, sectionSize: size)
    }
    func readCustomSection() throws -> WASMBinaryFormat.Section {
        let header = try readSectionHeader()
        let bytes = try readArray(numberOfBytes: header.sectionSize)
        return .customSection(header: header, bytes)
    }
    func readTypeSection() throws -> WASMBinaryFormat.Section {
        let header = try readSectionHeader()
        let vectorLength = try readULEB128()
        var types = [WASMBinaryFormat.FunctionType]()
        types.reserveCapacity(Int(vectorLength))
        for _ in 0..<vectorLength {
            let type = try readType()
            types.append(type)
        }
        return .typeSection(header: header, types)
    }
    func readType() throws -> WASMBinaryFormat.FunctionType {
        _ = try read()
        let argVectorLength = try readULEB128()
        var argTypes = [WASMBinaryFormat.ValueType]()
        argTypes.reserveCapacity(Int(argVectorLength))
        for _ in 0..<argVectorLength {
            let argValueType = try readValueType()
            argTypes.append(argValueType)
        }
        let resultVectorLength = try readULEB128()
        var resultTypes = [WASMBinaryFormat.ValueType]()
        resultTypes.reserveCapacity(Int(resultVectorLength))
        for _ in 0..<resultVectorLength {
            let resultValueType = try readValueType()
            resultTypes.append(resultValueType)
        }
        let type = WASMBinaryFormat.FunctionType(argTypes: argTypes, resultTypes: resultTypes)
        return type
    }
    func readValueType() throws -> WASMBinaryFormat.ValueType {
        let byte = try read()
        if let valueType = WASMBinaryFormat.ValueType(rawValue: byte) {
            return valueType
        }
        throw WASMReaderError.invalidValueType
    }
    func readImportSection() throws -> WASMBinaryFormat.Section {
        let header = try readSectionHeader()
        let vectorLength = try readULEB128()
        var imports = [WASMBinaryFormat.Import]()
        imports.reserveCapacity(Int(vectorLength))
        for _ in 0..<vectorLength {
            let i = try readImport()
            imports.append(i)
        }
        return .importSection(header: header, imports)
    }
    func readImport() throws -> WASMBinaryFormat.Import {
        let mod = try readName()
        let nm = try readName()
        let importDescription = try readImportDescription()
        return WASMBinaryFormat.Import(mod: mod, name: nm, description: importDescription)
    }
    func readImportDescription() throws -> WASMBinaryFormat.ImportDescription {
        let type = try read()
        guard let importType = WASMBinaryFormat.ImportDescriptionType(rawValue: type) else {
            throw WASMReaderError.invalidImportDescriptionType
        }
        switch importType {
        case .function:
            let index = try readULEB128()
            return .function(UInt(index))
        case .table:
            let elementTypeByte = try read()
            let limits = try readLimits()
            guard let elementType = WASMBinaryFormat.TableElementType(rawValue: elementTypeByte) else {
                throw WASMReaderError.invalidTableElementType
            }
            return .table(WASMBinaryFormat.TableType(elementType: elementType, limit: limits))
        case .memory:
            let limits = try readLimits()
            return .memory(limits)
        case .global:
            let global = try readGlobal()
            return .global(global)
        }
    }
    func readGlobal() throws -> WASMBinaryFormat.GlobalType {
        let valueType = try readValueType()
        let mutable = try read() > 0
        return WASMBinaryFormat.GlobalType(type: valueType, mutable: mutable)
    }
    func readLimits() throws -> WASMBinaryFormat.Limit {
        let limitTypeByte = try read()
        guard let limitType = WASMBinaryFormat.LimitType(rawValue: limitTypeByte) else {
            throw WASMReaderError.invalidLimitType
        }
        switch limitType {
        case .unbounded:
            let min = try readULEB128()
            return .unbounded(min: UInt(min))
        case .bounded:
            let min = try readULEB128()
            let max = try readULEB128()
            return .bounded(min: UInt(min), max: UInt(max))
        }
    }
    func readFunctionSection() throws -> WASMBinaryFormat.Section {
        let header = try readSectionHeader()
        let vectorLength = try readULEB128()
        var functionTypes = [Int]()
        functionTypes.reserveCapacity(Int(vectorLength))
        for _ in 0..<vectorLength {
            let index = try readULEB128()
            functionTypes.append(Int(index))
        }
        return .functionSection(header: header, functionTypes)
    }
    func readTableSection() throws -> WASMBinaryFormat.Section {
        let header = try readSectionHeader()
        let vectorLength = try readULEB128()
        var tables = [WASMBinaryFormat.TableType]()
        tables.reserveCapacity(Int(vectorLength))
        for _ in 0..<vectorLength {
            let elementTypeByte = try read()
            let limits = try readLimits()
            guard let elementType = WASMBinaryFormat.TableElementType(rawValue: elementTypeByte) else {
                throw WASMReaderError.invalidTableElementType
            }
            let table = WASMBinaryFormat.TableType(elementType: elementType, limit: limits)
            tables.append(table)
        }
        return .tableSection(header: header, tables)
    }
    func readMemorySection() throws -> WASMBinaryFormat.Section {
        let header = try readSectionHeader()
        let vectorLength = try readULEB128()
        var memories = [WASMBinaryFormat.Memory]()
        memories.reserveCapacity(Int(vectorLength))
        for _ in 0..<vectorLength {
            let memory = try readLimits()
            memories.append(memory)
        }
        return .memorySection(header: header, memories)
    }
    func readGlobalSection() throws -> WASMBinaryFormat.Section {
        let header = try readSectionHeader()
        let vectorLength = try readULEB128()
        var globals = [WASMBinaryFormat.Global]()
        globals.reserveCapacity(Int(vectorLength))
        for _ in 0..<vectorLength {
            let global = try readGlobal()
            let expression = try readExpression()
            globals.append(WASMBinaryFormat.Global(type: global, code: expression))
        }
        return .globalSection(header: header, globals)
    }
    func readExpression() throws -> WASMBinaryFormat.Expression {
        var bytes = [Byte]()
        while true {
            let byte = try read()
            if byte != 0x0B {
                bytes.append(byte)
            } else {
                break
            }
        }
        return WASMBinaryFormat.Expression(bytes: bytes)
    }
    func readExportSection() throws -> WASMBinaryFormat.Section {
        let header = try readSectionHeader()
        let vectorLength = try readULEB128()
        var exports = [WASMBinaryFormat.Export]()
        exports.reserveCapacity(Int(vectorLength))
        for _ in 0..<vectorLength {
            let export = try readExport()
            exports.append(export)
        }
        return .exportSection(header: header, exports)
    }
    func readExport() throws -> WASMBinaryFormat.Export {
        let name = try readName()
        let exportDescriptionTypeByte = try read()
        guard let exportDescriptionType = WASMBinaryFormat.ExportDescriptionType(rawValue: exportDescriptionTypeByte) else {
            throw WASMReaderError.invalidExportDescriptionType
        }
        switch exportDescriptionType {
        case .function:
            let index = try readULEB128()
            return WASMBinaryFormat.Export(name: name, description: .function(Int(index)))
        case .table:
            let index = try readULEB128()
            return WASMBinaryFormat.Export(name: name, description: .table(Int(index)))
        case .memory:
            let index = try readULEB128()
            return WASMBinaryFormat.Export(name: name, description: .memory(Int(index)))
        case .global:
            let index = try readULEB128()
            return WASMBinaryFormat.Export(name: name, description: .global(Int(index)))
        }
    }
    func readStartSection() throws -> WASMBinaryFormat.Section {
        let header = try readSectionHeader()
        let functionIndex = try readULEB128()
        return .startSection(header: header, Int(functionIndex))
    }
    func readElementSection() throws -> WASMBinaryFormat.Section {
        let header = try readSectionHeader()
        let vectorLength = try readULEB128()
        var elements = [WASMBinaryFormat.Element]()
        elements.reserveCapacity(Int(vectorLength))
        for _ in 0..<vectorLength {
            let element = try readElement()
            elements.append(element)
        }
        return .elementSection(header: header, elements)
    }
    func readElement() throws -> WASMBinaryFormat.Element {
        let tableIndex = try readULEB128()
        let offset = try readExpression()
        let vectorLength = try readULEB128()
        var indices = [Int]()
        indices.reserveCapacity(Int(vectorLength))
        for _ in 0..<vectorLength {
            let index = try readULEB128()
            indices.append(Int(index))
        }
        return WASMBinaryFormat.Element(tableIndex: Int(tableIndex), offset: offset, functionIndices: indices)
    }
    func readCodeSection() throws -> WASMBinaryFormat.Section {
        let header = try readSectionHeader()
        let vectorLength = try readULEB128()
        var entries = [WASMBinaryFormat.CodeEntry]()
        entries.reserveCapacity(Int(vectorLength))
        for _ in 0..<vectorLength {
            let size = try readULEB128()
            let bytes = try readArray(numberOfBytes: Int(size))
            let entry = WASMBinaryFormat.CodeEntry(data: bytes)
            entries.append(entry)
        }
        return .codeSection(header: header, entries)
    }
    func readDataSection() throws -> WASMBinaryFormat.Section {
        let header = try readSectionHeader()
        let vectorLength = try readULEB128()
        var entries = [WASMBinaryFormat.DataSegment]()
        entries.reserveCapacity(Int(vectorLength))
        for _ in 0..<vectorLength {
            let memoryIndex = try readULEB128()
            let expression = try readExpression()
            let byteArrayLength = try readULEB128()
            let bytes = try readArray(numberOfBytes: Int(byteArrayLength))
            let segment = WASMBinaryFormat.DataSegment(memoryIndex: Int(memoryIndex), offset: expression, data: bytes)
            entries.append(segment)
        }
        return .dataSection(header: header, entries)
    }
}
