//
//  WASM.swift
//  BinaryDataReader
//
//  Created by Lukas Möller on 11.11.19.
//

import Foundation

import BinaryUtilities

public struct WASM {
    static func binaryValueTypeToValueType(_ binaryValueType: WASMBinaryFormat.ValueType) -> ValueType {
        switch binaryValueType {
        case .i32:
            return .i32
        case .i64:
            return .i64
        case .f32:
            return .f32
        case .f64:
            return .f64
        }
    }
    static func binaryLimitToLimit(_ binaryLimit: WASMBinaryFormat.Limit) -> Limit {
        switch binaryLimit {
        case .unbounded(let min):
            return Limit(min: Int(min), max: nil)
        case .bounded(let min, let max):
            return Limit(min: Int(min), max: Int(max))
        }
    }
    public struct Module {
        let types: [FunctionType]
        let functions: [Function]
        let tables: [Table]
        let memories: [Memory]
        let globals: [Global]
        let elements: [Element]
        let data: [Data]
        let start: Start?
        let imports: [Import]
        let exports: [Export]
        public init(binaryModule: WASMBinaryFormat.Module) throws {
            var types: [FunctionType] = []
            var functions: [Function] = []
            var tables: [Table] = []
            var memories: [Memory] = []
            var globals: [Global] = []
            var elements: [Element] = []
            var data: [Data] = []
            var start: Start? = nil
            var imports: [Import] = []
            var exports: [Export] = []
    
            var functionTypeMap: [Int] = []
            for section in binaryModule.sections {
                switch section {
                case .customSection(_, _):
                    continue
                case .typeSection(_, let sectionTypes):
                    for t in sectionTypes {
                        let functionType = FunctionType(parameters: t.argTypes.map(binaryValueTypeToValueType), results: t.resultTypes.map(binaryValueTypeToValueType))
                        types.append(functionType)
                    }
                case .importSection(_, let sectionImports):
                    for i in sectionImports {
                        let module = i.mod
                        let name = i.name
                        switch i.description {
                        case .function(let fnIndex):
                            let description = ImportDescription.function(Int(fnIndex))
                            imports.append(Import(module: module, name: name, description: description))
                        case .table(let table):
                            let description = ImportDescription.table(Table(limit: binaryLimitToLimit(table.limit), elementType: .functionReference))
                            imports.append(Import(module: module, name: name, description: description))
                        case .memory(let memory):
                            let description = ImportDescription.memory(Memory(limit: binaryLimitToLimit(memory)))
                            imports.append(Import(module: module, name: name, description: description))
                        case .global(let global):
                            let description = ImportDescription.global(type: binaryValueTypeToValueType(global.type), mutable: global.mutable)
                            imports.append(Import(module: module, name: name, description: description))
                        }
                    }
                case .functionSection(_, let functions):
                    for functionTypeIndex in functions {
                        functionTypeMap.append(functionTypeIndex)
                    }
                case .tableSection(_, let bTables):
                    for bTable in bTables {
                        let table = Table(limit: binaryLimitToLimit(bTable.limit), elementType: .functionReference)
                        tables.append(table)
                    }
                case .memorySection(_, let bMemories):
                    for bMemory in bMemories {
                        let memory = Memory(limit: binaryLimitToLimit(bMemory))
                        memories.append(memory)
                    }
                case .globalSection(_, let bGlobals):
                    for bGlobal in bGlobals {
                        let type = binaryValueTypeToValueType(bGlobal.type.type)
                        let mutable = bGlobal.type.mutable
                        let source = ArrayDataSource(buffer: bGlobal.code.bytes)
                        let disassembler = WASMDisassembler(dataSource: source)
                        let instructions = try disassembler.disassembleExpression()
                        let initialValue = Expression(instructions: instructions)
                        let global = Global(type: type, mutable: mutable, initialValue: initialValue)
                        globals.append(global)
                    }
                case .exportSection(_, let bExports):
                    for bExport in bExports {
                        switch bExport.description {
                        case .function(let functionIndex):
                            let description = ExportDescription.function(functionIndex)
                            let export = Export(name: bExport.name, description: description)
                            exports.append(export)
                        case .table(let tableIndex):
                            let description = ExportDescription.table(tableIndex)
                            let export = Export(name: bExport.name, description: description)
                            exports.append(export)
                        case .memory(let memoryIndex):
                            let description = ExportDescription.memory(memoryIndex)
                            let export = Export(name: bExport.name, description: description)
                            exports.append(export)
                        case .global(let globalIndex):
                            let description = ExportDescription.global(globalIndex)
                            let export = Export(name: bExport.name, description: description)
                            exports.append(export)
                        }
                    }
                case .startSection(_, let startFunctionIndex):
                    start = Start(functionIndex: startFunctionIndex)
                case .elementSection(_, let bElements):
                    for bElement in bElements {
                        let tableIndex = bElement.tableIndex
                        let source = ArrayDataSource(buffer: bElement.offset.bytes)
                        let disassembler = WASMDisassembler(dataSource: source)
                        let instructions = try disassembler.disassembleExpression()
                        let offset = Expression(instructions: instructions)
                        let indices = bElement.functionIndices
                        let element = Element(tableIndex: tableIndex, offset: offset, indices: indices)
                        elements.append(element)
                    }
                case .codeSection(_, let bCodeEntries):
                    for bCodeEntry in bCodeEntries {
                        let typeIndex = functionTypeMap[functions.count]
                        let locals = [ValueType]()
                        let source = ArrayDataSource(buffer: bCodeEntry.data)
                        let disassembler = WASMDisassembler(dataSource: source)
                        let instructions = try disassembler.disassembleFunction()
                        let body = Expression(instructions: instructions)
                        let function = Function(type: typeIndex, locals: locals, body: body)
                        functions.append(function)
                    }
                case .dataSection(_, let bDataSegments):
                    for bDataSegment in bDataSegments {
                        let memoryIndex = bDataSegment.memoryIndex
                        let source = ArrayDataSource(buffer: bDataSegment.offset.bytes)
                        let disassembler = WASMDisassembler(dataSource: source)
                        let instructions = try disassembler.disassembleExpression()
                        let offset = Expression(instructions: instructions)
                        let values = bDataSegment.data
                        let segment = Data(memoryIndex: memoryIndex, offset: offset, bytes: values)
                        data.append(segment)
                    }
                }
            }
            self.types = types
            self.functions = functions
            self.tables = tables
            self.memories = memories
            self.globals = globals
            self.elements = elements
            self.data = data
            self.start = start
            self.imports = imports
            self.exports = exports
        }
    }
    struct Import {
        let module: String
        let name: String
        let description: ImportDescription
    }
    enum ImportDescription {
        case function(Int)
        case table(Table)
        case memory(Memory)
        case global(type: ValueType, mutable: Bool)
    }
    struct Export {
        let name: String
        let description: ExportDescription
    }
    enum ExportDescription {
        case function(Int)
        case table(Int)
        case memory(Int)
        case global(Int)
    }
    struct Start {
        let functionIndex: Int
    }
    struct Data {
        let memoryIndex: Int
        let offset: Expression
        let bytes: [UInt8]
    }
    struct Element {
        let tableIndex: Int
        let offset: Expression
        let indices: [Int]
    }
    struct Global {
        let type: ValueType
        let mutable: Bool
        let initialValue: Expression
    }
    struct Memory {
        let limit: Limit
    }
    struct Limit {
        let min: Int
        let max: Int?
    }
    struct Table {
        let limit: Limit
        let elementType: TableElementType
    }
    enum TableElementType {
        case functionReference
    }
    struct Function {
        let type: Int
        let locals: [ValueType]
        let body: Expression
    }
    struct Expression {
        let instructions: [Instruction]
    }
    struct FunctionType {
        let parameters: [ValueType]
        let results: [ValueType]
    }
    enum BlockType {
        case none
        case valueType(ValueType)
    }
    enum ValueType {
        case i32
        case i64
        case f32
        case f64
    }
    enum Instruction {
        case unreachable
        case nop
        case blockStart(rt: BlockType)
        case loopStart(rt: BlockType)
        case ifStart(rt: BlockType)
        case elseStart
        case end
        case br(labelIndex: Int)
        case brIf(labelIndex: Int)
        case brTable([Int], labelIndex: Int)
        case ret
        case call(functionIndex: Int)
        case callIndirect(typeIndex: Int)

        // Parametric Instructions
        case drop
        case select

        // Variable Instructions
        case localGet(Int)
        case localSet(Int)
        case localTee(Int)
        case globalGet(Int)
        case globalSet(Int)

        // Memory instructions
        case i32Load(align: Int, offset: Int)
        case i64Load(align: Int, offset: Int)
        case f32Load(align: Int, offset: Int)
        case f64Load(align: Int, offset: Int)
        case i32LoadS8(align: Int, offset: Int)
        case i32LoadU8(align: Int, offset: Int)
        case i32LoadS16(align: Int, offset: Int)
        case i32LoadU16(align: Int, offset: Int)
        case i64LoadS8(align: Int, offset: Int)
        case i64LoadU8(align: Int, offset: Int)
        case i64LoadS16(align: Int, offset: Int)
        case i64LoadU16(align: Int, offset: Int)
        case i64LoadS32(align: Int, offset: Int)
        case i64LoadU32(align: Int, offset: Int)

        case i32Store(align: Int, offset: Int)
        case i64Store(align: Int, offset: Int)
        case f32Store(align: Int, offset: Int)
        case f64Store(align: Int, offset: Int)
        case i32Store8(align: Int, offset: Int)
        case i32Store16(align: Int, offset: Int)
        case i64Store8(align: Int, offset: Int)
        case i64Store16(align: Int, offset: Int)
        case i64Store32(align: Int, offset: Int)
        case memorySize
        case memoryGrow

        // Numeric Instructions
        case i32Const(UInt32)
        case i64Const(UInt64)
        case f32Const(Float32)
        case f64Const(Float64)

        case i32EqualToZero
        case i32Equal
        case i32NotEqual
        case i32SignedLess
        case i32UnsignedLess
        case i32SignedGreater
        case i32UnsignedGreater
        case i32SignedLessEqual
        case i32UnsignedLessEqual
        case i32SignedGreaterEqual
        case i32UnsignedGreaterEqual

        case i64EqualToZero
        case i64Equal
        case i64NotEqual
        case i64SignedLess
        case i64UnsignedLess
        case i64SignedGreater
        case i64UnsignedGreater
        case i64SignedLessEqual
        case i64UnsignedLessEqual
        case i64SignedGreaterEqual
        case i64UnsignedGreaterEqual

        case f32Equal
        case f32NotEqual
        case f32Less
        case f32Greater
        case f32LessEqual
        case f32GreaterEqual

        case f64Equal
        case f64NotEqual
        case f64Less
        case f64Greater
        case f64LessEqual
        case f64GreaterEqual

        case i32CountLeadingZeroes
        case i32CountTrailingZeroes
        case i32PopCount
        case i32Add
        case i32Subtract
        case i32Multiply
        case i32DivideSigned
        case i32DivideUnsigned
        case i32RemainderSigned
        case i32RemainderUnsigned
        case i32And
        case i32Or
        case i32Xor
        case i32ShiftLeft
        case i32ShiftRightSigned
        case i32ShiftRightUnsigned
        case i32RotateLeft
        case i32RotateRight

        case i64CountLeadingZeroes
        case i64CountTrailingZeroes
        case i64PopCount
        case i64Add
        case i64Subtract
        case i64Multiply
        case i64DivideSigned
        case i64DivideUnsigned
        case i64RemainderSigned
        case i64RemainderUnsigned
        case i64And
        case i64Or
        case i64Xor
        case i64ShiftLeft
        case i64ShiftRightSigned
        case i64ShiftRightUnsigned
        case i64RotateLeft
        case i64RotateRight

        case f32Absolute
        case f32Negate
        case f32Ceil
        case f32Floor
        case f32Truncate
        case f32Nearest
        case f32SquareRoot
        case f32Add
        case f32Subtract
        case f32Multiply
        case f32Divide
        case f32Minimum
        case f32Maximum
        case f32CopySign

        case f64Absolute
        case f64Negate
        case f64Ceil
        case f64Floor
        case f64Truncate
        case f64Nearest
        case f64SquareRoot
        case f64Add
        case f64Subtract
        case f64Multiply
        case f64Divide
        case f64Minimum
        case f64Maximum
        case f64CopySign

        case i32WrapI64
        case i32TruncateF32Signed
        case i32TruncateF32Unsigned
        case i32TruncateF64Signed
        case i32TruncateF64Unsigned
        case i64ExtendI32Signed
        case i64ExtendI32Unsigned
        case i64TruncateF32Signed
        case i64TruncateF32Unsigned
        case i64TruncateF64Signed
        case i64TruncateF64Unsigned
        case f32ConvertI32Signed
        case f32ConvertI32Unsigned
        case f32ConvertI64Signed
        case f32ConvertI64Unsigned
        case f32DemoteF64
        case f64ConvertI32Signed
        case f64ConvertI32Unsigned
        case f64ConvertI64Signed
        case f64ConvertI64Unsigned
        case f64PromoteF32
        case i32ReinterpretF32
        case i64ReinterpretF64
        case f32ReinterpretI32
        case f64ReinterpretI64
    }
}
