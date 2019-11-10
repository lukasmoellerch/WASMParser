//
//  WASMBinaryFormat.swift
//  BinaryDataReader
//
//  Created by Lukas Möller on 11.11.19.
//

import Foundation
import BinaryUtilities
public struct WASMBinaryFormat {
    enum Opcode: Byte {
        case unreachable = 0x00
        case nop = 0x01
        case blockstart = 0x02
        case loopstart = 0x03
        case ifstart = 0x04
        case elsestart = 0x05
        case blockend = 0x0b
        case br = 0x0c
        case brIf = 0x0d
        case brTable = 0x0e
        case ret = 0x0f
        case call = 0x10
        case callIndirect = 0x11

        // Parametric Instructions
        case drop = 0x1a
        case select = 0x1b

        // Variable Instructions
        case localGet = 0x20
        case localSet = 0x21
        case localTee = 0x22
        case globalGet = 0x23
        case globalSet = 0x24

        // Memory instructions
        case i32Load = 0x28
        case i64Load = 0x29
        case f32Load = 0x2a
        case f64Load = 0x2b
        case i32LoadS8 = 0x2c
        case i32LoadU8 = 0x2d
        case i32LoadS16 = 0x2e
        case i32LoadU16 = 0x2f
        case i64LoadS8 = 0x30
        case i64LoadU8 = 0x31
        case i64LoadS16 = 0x32
        case i64LoadU16 = 0x33
        case i64LoadS32 = 0x34
        case i64LoadU32 = 0x35

        case i32Store = 0x36
        case i64Store = 0x37
        case f32Store = 0x38
        case f64Store = 0x39
        case i32Store8 = 0x3a
        case i32Store16 = 0x3b
        case i64Store8 = 0x3c
        case i64Store16 = 0x3d
        case i64Store32 = 0x3e
        case memorySize = 0x3f // 0x00
        case memoryGrow = 0x40 // 0x00

        // Numeric Instructions
        case i32Const = 0x41
        case i64Const = 0x42
        case f32Const = 0x43
        case f64Const = 0x44

        case i32EqualToZero = 0x45
        case i32Equal = 0x46
        case i32NotEqual = 0x47
        case i32SignedLess = 0x48
        case i32UnsignedLess = 0x49
        case i32SignedGreater = 0x4a
        case i32UnsignedGreater = 0x4b
        case i32SignedLessEqual = 0x4c
        case i32UnsignedLessEqual = 0x4d
        case i32SignedGreaterEqual = 0x4e
        case i32UnsignedGreaterEqual = 0x4f

        case i64EqualToZero = 0x50
        case i64Equal = 0x51
        case i64NotEqual = 0x52
        case i64SignedLess = 0x53
        case i64UnsignedLess = 0x54
        case i64SignedGreater = 0x55
        case i64UnsignedGreater = 0x56
        case i64SignedLessEqual = 0x57
        case i64UnsignedLessEqual = 0x58
        case i64SignedGreaterEqual = 0x59
        case i64UnsignedGreaterEqual = 0x5a

        case f32Equal = 0x5b
        case f32NotEqual = 0x5c
        case f32Less = 0x5d
        case f32Greater = 0x5e
        case f32LessEqual = 0x5f
        case f32GreaterEqual = 0x60

        case f64Equal = 0x61
        case f64NotEqual = 0x62
        case f64Less = 0x63
        case f64Greater = 0x64
        case f64LessEqual = 0x65
        case f64GreaterEqual = 0x66

        case i32CountLeadingZeroes = 0x67
        case i32CountTrailingZeroes = 0x68
        case i32PopCount = 0x69
        case i32Add = 0x6a
        case i32Subtract = 0x6b
        case i32Multiply = 0x6c
        case i32DivideSigned = 0x6d
        case i32DivideUnsigned = 0x6e
        case i32RemainderSigned = 0x6f
        case i32RemainderUnsigned = 0x70
        case i32And = 0x71
        case i32Or = 0x72
        case i32Xor = 0x73
        case i32ShiftLeft = 0x74
        case i32ShiftRightSigned = 0x75
        case i32ShiftRightUnsigned = 0x76
        case i32RotateLeft = 0x77
        case i32RotateRight = 0x78

        case i64CountLeadingZeroes = 0x79
        case i64CountTrailingZeroes = 0x7a
        case i64PopCount = 0x7b
        case i64Add = 0x7c
        case i64Subtract = 0x7d
        case i64Multiply = 0x7e
        case i64DivideSigned = 0x7f
        case i64DivideUnsigned = 0x80
        case i64RemainderSigned = 0x81
        case i64RemainderUnsigned = 0x82
        case i64And = 0x83
        case i64Or = 0x84
        case i64Xor = 0x85
        case i64ShiftLeft = 0x86
        case i64ShiftRightSigned = 0x87
        case i64ShiftRightUnsigned = 0x88
        case i64RotateLeft = 0x89
        case i64RotateRight = 0x8a

        case f32Absolute = 0x8b
        case f32Negate = 0x8c
        case f32Ceil = 0x8d
        case f32Floor = 0x8e
        case f32Truncate = 0x8f
        case f32Nearest = 0x90
        case f32SquareRoot = 0x91
        case f32Add = 0x92
        case f32Subtract = 0x93
        case f32Multiply = 0x94
        case f32Divide = 0x95
        case f32Minimum = 0x96
        case f32Maximum = 0x97
        case f32CopySign = 0x98

        case f64Absolute = 0x99
        case f64Negate = 0x9a
        case f64Ceil = 0x9b
        case f64Floor = 0x9c
        case f64Truncate = 0x9d
        case f64Nearest = 0x9e
        case f64SquareRoot = 0x9f
        case f64Add = 0xa0
        case f64Subtract = 0xa1
        case f64Multiply = 0xa2
        case f64Divide = 0xa3
        case f64Minimum = 0xa4
        case f64Maximum = 0xa5
        case f64CopySign = 0xa6

        case i32WrapI64 = 0xa7
        case i32TruncateF32Signed = 0xa8
        case i32TruncateF32Unsigned = 0xa9
        case i32TruncateF64Signed = 0xaa
        case i32TruncateF64Unsigned = 0xab
        case i64ExtendI32Signed = 0xac
        case i64ExtendI32Unsigned = 0xad
        case i64TruncateF32Signed = 0xae
        case i64TruncateF32Unsigned = 0xaf
        case i64TruncateF64Signed = 0xb0
        case i64TruncateF64Unsigned = 0xb1
        case f32ConvertI32Signed = 0xb2
        case f32ConvertI32Unsigned = 0xb3
        case f32ConvertI64Signed = 0xb4
        case f32ConvertI64Unsigned = 0xb5
        case f32DemoteF64 = 0xb6
        case f64ConvertI32Signed = 0xb7
        case f64ConvertI32Unsigned = 0xb8
        case f64ConvertI64Signed = 0xb9
        case f64ConvertI64Unsigned = 0xba
        case f64PromoteF32 = 0xbb
        case i32ReinterpretF32 = 0xbc
        case i64ReinterpretF64 = 0xbd
        case f32ReinterpretI32 = 0xbe
        case f64ReinterpretI64 = 0xbf
    }
    public struct Module {
        let version: Int
        let sections: [Section]
    }
    enum SectionId: Byte {
        case customSection
        case typeSection
        case importSection
        case functionSection
        case tableSection
        case memorySection
        case globalSection
        case exportSection
        case startSection
        case elementSection
        case codeSection
        case dataSection
    }
    public enum Section {
        case customSection(header: SectionHeader, [UInt8])
        case typeSection(header: SectionHeader, [FunctionType])
        case importSection(header: SectionHeader, [Import])
        case functionSection(header: SectionHeader, [Int])
        case tableSection(header: SectionHeader, [TableType])
        case memorySection(header: SectionHeader, [Memory])
        case globalSection(header: SectionHeader, [Global])
        case exportSection(header: SectionHeader, [Export])
        case startSection(header: SectionHeader, Int)
        case elementSection(header: SectionHeader, [Element])
        case codeSection(header: SectionHeader, [CodeEntry])
        case dataSection(header: SectionHeader, [DataSegment])
    }
    public enum LimitType: Byte {
        case unbounded
        case bounded
    }
    public enum Limit {
        case unbounded(min: UInt)
        case bounded(min: UInt, max: UInt)
    }
    enum TableElementType: Byte {
        case function = 0x70
    }
    public struct TableType {
        let elementType: TableElementType
        let limit: Limit
    }
    public struct Expression {
        var bytes: [UInt8]
    }
    public struct Global {
        let type: GlobalType
        let code: Expression
    }
    public struct GlobalType {
        let type: ValueType
        let mutable: Bool
    }
    public typealias Memory = Limit
    public struct FunctionType {
        static let magicByte = 0x60
        let argTypes: [ValueType]
        let resultTypes: [ValueType]
    }
    enum ValueType: Byte {
        case i32 = 0x7f
        case i64 = 0x7e
        case f32 = 0x7d
        case f64 = 0x7c
    }
    public enum ResultType: Byte {
        case i32 = 0x7f
        case i64 = 0x7e
        case f32 = 0x7d
        case f64 = 0x7c
        case none = 0x40
    }
    public struct SectionHeader {
        let sectionStart: Int
        let sectionEnd: Int
        let sectionSize: Int
    }
    public struct Import {
        let mod: String
        let name: String
        let description: ImportDescription
    }
    public enum ImportDescriptionType: Byte {
        case function
        case table
        case memory
        case global
    }
    public enum ImportDescription {
        case function(UInt)
        case table(TableType)
        case memory(Memory)
        case global(GlobalType)
    }
    public struct Export {
        let name: String
        let description: ExportDescription
    }
    public enum ExportDescriptionType: Byte {
        case function
        case table
        case memory
        case global
    }
    public enum ExportDescription {
        case function(Int)
        case table(Int)
        case memory(Int)
        case global(Int)
    }
    public struct Element {
        let tableIndex: Int
        let offset: Expression
        let functionIndices: [Int]
    }
    public struct CodeEntry {
        let data: [UInt8]
    }
    public struct DataSegment {
        let memoryIndex: Int
        let offset: Expression
        let data: [UInt8]
    }
}
