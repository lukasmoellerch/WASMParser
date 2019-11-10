//
//  Disassembler.swift
//  BinaryDataReader
//
//  Created by Lukas Möller on 11.11.19.
//

import Foundation
import BinaryDataReader
class WASMDisassembler: BinaryDataReader {
    enum WASMDisassemblerError: Error {
        case invalidOpcode
        case invalidBlockType
        case invalidValueType
    }
    func readBlockType() throws -> WASM.BlockType {
        let byte = try read()
        if byte == 0x40 {
            return .none
        } else if byte == 0x7f {
            return .valueType(.i32)
        } else if byte == 0x7e {
            return .valueType(.i64)
        } else if byte == 0x7d {
            return .valueType(.f32)
        } else if byte == 0x7c {
            return .valueType(.i64)
        }
        throw WASMDisassemblerError.invalidBlockType
    }
    func readValueType() throws -> WASM.ValueType {
        let byte = try read()
        guard let valueType = WASMBinaryFormat.ValueType(rawValue: byte) else {
            throw WASMDisassemblerError.invalidValueType
        }
        switch valueType {
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
    func disassembleFunction() throws -> [WASM.Instruction] {
        let numLocalDeclarations = try readULEB128()
        var localDeclarations = [WASM.ValueType]()
        localDeclarations.reserveCapacity(Int(numLocalDeclarations))
        for _ in 0..<numLocalDeclarations {
            let n = try readULEB128()
            let t = try readValueType()
            for _ in 0..<n {
                localDeclarations.append(t)
            }
        }
        let instructions = try disassembleExpression()
        return instructions
    }
    func disassembleExpression() throws -> [WASM.Instruction] {
        //let numInstructions = try readULEB128()
        var instructions = [WASM.Instruction]()
        //instructions.reserveCapacity(Int(numInstructions))
        while source.hasData {
            instructions.append(try readInstruction())
        }
        return instructions
    }
    func readInstruction() throws -> WASM.Instruction {
        let byte = try read()
        guard let opcode = WASMBinaryFormat.Opcode(rawValue: byte) else {
            throw WASMDisassemblerError.invalidOpcode
        }
        switch opcode {
        case .unreachable:
            return .unreachable
        case .nop:
            return .nop
        case .blockstart:
            let type = try readBlockType()
            return .blockStart(rt: type)
        case .loopstart:
            let type = try readBlockType()
            return .loopStart(rt: type)
        case .ifstart:
            let type = try readBlockType()
            return .ifStart(rt: type)
        case .elsestart:
            return .elseStart
        case .blockend:
            return .end
        case .br:
            let labelIndex = try readULEB128()
            return .br(labelIndex: Int(labelIndex))
        case .brIf:
            let labelIndex = try readULEB128()
            return .brIf(labelIndex: Int(labelIndex))
        case .brTable:
            let vectorLength = try readULEB128()
            var indices = [Int]()
            indices.reserveCapacity(Int(vectorLength))
            for _ in 0..<vectorLength {
                indices.append(Int(try readULEB128()))
            }
            let labelIndex = try readULEB128()
            return .brTable(indices, labelIndex: Int(labelIndex))
        case .ret:
            return .ret
        case .call:
            let functionIndex = try readULEB128()
            return .call(functionIndex: Int(functionIndex))
        case .callIndirect:
            let typeIndex = try readULEB128()
            _ = try read()
            return .callIndirect(typeIndex: Int(typeIndex))
        case .drop:
            return .drop
        case .select:
            return .select
        case .localGet:
            let index = try readULEB128()
            return .localGet(Int(index))
        case .localSet:
            let index = try readULEB128()
            return .localSet(Int(index))
        case .localTee:
            let index = try readULEB128()
            return .localTee(Int(index))
        case .globalGet:
            let index = try readULEB128()
            return .globalGet(Int(index))
        case .globalSet:
            let index = try readULEB128()
            return .globalSet(Int(index))
        case .i32Load:
            let align = try readULEB128()
            let offset = try readULEB128()
            return .i32Load(align: Int(align), offset: Int(offset))
        case .i64Load:
            let align = try readULEB128()
            let offset = try readULEB128()
            return .i64Load(align: Int(align), offset: Int(offset))
        case .f32Load:
            let align = try readULEB128()
            let offset = try readULEB128()
            return .f32Load(align: Int(align), offset: Int(offset))
        case .f64Load:
            let align = try readULEB128()
            let offset = try readULEB128()
            return .f64Load(align: Int(align), offset: Int(offset))
        case .i32LoadS8:
            let align = try readULEB128()
            let offset = try readULEB128()
            return .i32LoadS8(align: Int(align), offset: Int(offset))
        case .i32LoadU8:
            let align = try readULEB128()
            let offset = try readULEB128()
            return .i32LoadU8(align: Int(align), offset: Int(offset))
        case .i32LoadS16:
            let align = try readULEB128()
            let offset = try readULEB128()
            return .i32LoadS16(align: Int(align), offset: Int(offset))
        case .i32LoadU16:
            let align = try readULEB128()
            let offset = try readULEB128()
            return .i32LoadU16(align: Int(align), offset: Int(offset))
        case .i64LoadS8:
            let align = try readULEB128()
            let offset = try readULEB128()
            return .i64LoadS8(align: Int(align), offset: Int(offset))
        case .i64LoadU8:
            let align = try readULEB128()
            let offset = try readULEB128()
            return .i64LoadU8(align: Int(align), offset: Int(offset))
        case .i64LoadS16:
            let align = try readULEB128()
            let offset = try readULEB128()
            return .i64LoadS16(align: Int(align), offset: Int(offset))
        case .i64LoadU16:
            let align = try readULEB128()
            let offset = try readULEB128()
            return .i64LoadU16(align: Int(align), offset: Int(offset))
        case .i64LoadS32:
            let align = try readULEB128()
            let offset = try readULEB128()
            return .i64Store32(align: Int(align), offset: Int(offset))
        case .i64LoadU32:
            let align = try readULEB128()
            let offset = try readULEB128()
            return .i64LoadU32(align: Int(align), offset: Int(offset))
        case .i32Store:
            let align = try readULEB128()
            let offset = try readULEB128()
            return .i32Store(align: Int(align), offset: Int(offset))
        case .i64Store:
            let align = try readULEB128()
            let offset = try readULEB128()
            return .i64Store(align: Int(align), offset: Int(offset))
        case .f32Store:
            let align = try readULEB128()
            let offset = try readULEB128()
            return .f32Store(align: Int(align), offset: Int(offset))
        case .f64Store:
            let align = try readULEB128()
            let offset = try readULEB128()
            return .f64Store(align: Int(align), offset: Int(offset))
        case .i32Store8:
            let align = try readULEB128()
            let offset = try readULEB128()
            return .i32Store8(align: Int(align), offset: Int(offset))
        case .i32Store16:
            let align = try readULEB128()
            let offset = try readULEB128()
            return .i32Store16(align: Int(align), offset: Int(offset))
        case .i64Store8:
            let align = try readULEB128()
            let offset = try readULEB128()
            return .i64Store8(align: Int(align), offset: Int(offset))
        case .i64Store16:
            let align = try readULEB128()
            let offset = try readULEB128()
            return .i64Store16(align: Int(align), offset: Int(offset))
        case .i64Store32:
            let align = try readULEB128()
            let offset = try readULEB128()
            return .i64Store32(align: Int(align), offset: Int(offset))
        case .memorySize:
            return .memorySize
        case .memoryGrow:
            return .memoryGrow
        case .i32Const:
            let value = try readSLEB128()
            return .i32Const(UInt32(bitPattern: Int32(value)))
        case .i64Const:
            let value = try readSLEB128()
            return .i64Const(UInt64(bitPattern: value))
        case .f32Const:
            let value = try readFloat32()
            return .f32Const(value)
        case .f64Const:
            let value = try readFloat64()
            return .f64Const(value)
        case .i32EqualToZero:
            return .i32EqualToZero
        case .i32Equal:
            return .i32Equal
        case .i32NotEqual:
            return .i32NotEqual
        case .i32SignedLess:
            return .i32SignedLess
        case .i32UnsignedLess:
            return .i32UnsignedLess
        case .i32SignedGreater:
            return .i32SignedGreater
        case .i32UnsignedGreater:
            return .i32UnsignedGreater
        case .i32SignedLessEqual:
            return .i32SignedLessEqual
        case .i32UnsignedLessEqual:
            return .i32UnsignedLessEqual
        case .i32SignedGreaterEqual:
            return .i32SignedGreaterEqual
        case .i32UnsignedGreaterEqual:
            return .i32UnsignedGreaterEqual
        case .i64EqualToZero:
            return .i64EqualToZero
        case .i64Equal:
            return .i64Equal
        case .i64NotEqual:
            return .i64NotEqual
        case .i64SignedLess:
            return .i64SignedLess
        case .i64UnsignedLess:
            return .i64UnsignedLess
        case .i64SignedGreater:
            return .i64SignedGreater
        case .i64UnsignedGreater:
            return .i64UnsignedGreater
        case .i64SignedLessEqual:
            return .i64SignedLessEqual
        case .i64UnsignedLessEqual:
            return .i64UnsignedLessEqual
        case .i64SignedGreaterEqual:
            return .i64SignedGreaterEqual
        case .i64UnsignedGreaterEqual:
            return .f32Equal
        case .f32Equal:
            return .f32Equal
        case .f32NotEqual:
            return .f32NotEqual
        case .f32Less:
            return .f32Less
        case .f32Greater:
            return .f32Greater
        case .f32LessEqual:
            return .f32LessEqual
        case .f32GreaterEqual:
            return .f32GreaterEqual
        case .f64Equal:
            return .f64Equal
        case .f64NotEqual:
            return .f64NotEqual
        case .f64Less:
            return .f64Less
        case .f64Greater:
            return .f64Greater
        case .f64LessEqual:
            return .f64LessEqual
        case .f64GreaterEqual:
            return .f64GreaterEqual
        case .i32CountLeadingZeroes:
            return .i32CountLeadingZeroes
        case .i32CountTrailingZeroes:
            return .i32CountTrailingZeroes
        case .i32PopCount:
            return .i32PopCount
        case .i32Add:
            return .i32Add
        case .i32Subtract:
            return .i32Subtract
        case .i32Multiply:
            return .i32Multiply
        case .i32DivideSigned:
            return .i32DivideSigned
        case .i32DivideUnsigned:
            return .i32DivideUnsigned
        case .i32RemainderSigned:
            return .i32RemainderSigned
        case .i32RemainderUnsigned:
            return .i32RemainderUnsigned
        case .i32And:
            return .i32And
        case .i32Or:
            return .i32Or
        case .i32Xor:
            return .i32Xor
        case .i32ShiftLeft:
            return .i32ShiftLeft
        case .i32ShiftRightSigned:
            return .i32ShiftRightSigned
        case .i32ShiftRightUnsigned:
            return .i32ShiftRightUnsigned
        case .i32RotateLeft:
            return .i32RotateLeft
        case .i32RotateRight:
            return .i32RotateRight
        case .i64CountLeadingZeroes:
            return .i64CountLeadingZeroes
        case .i64CountTrailingZeroes:
            return .i64CountTrailingZeroes
        case .i64PopCount:
            return .i64PopCount
        case .i64Add:
            return .i64Add
        case .i64Subtract:
            return .i64Subtract
        case .i64Multiply:
            return .i64Multiply
        case .i64DivideSigned:
            return .i64DivideSigned
        case .i64DivideUnsigned:
            return .i64DivideUnsigned
        case .i64RemainderSigned:
            return .i64RemainderSigned
        case .i64RemainderUnsigned:
            return .i64RemainderUnsigned
        case .i64And:
            return .i64And
        case .i64Or:
            return .i64Or
        case .i64Xor:
            return .i64Xor
        case .i64ShiftLeft:
            return .i64ShiftLeft
        case .i64ShiftRightSigned:
            return .i64ShiftRightSigned
        case .i64ShiftRightUnsigned:
            return .i64ShiftRightUnsigned
        case .i64RotateLeft:
            return .i64RotateLeft
        case .i64RotateRight:
            return .i64RotateRight
        case .f32Absolute:
            return .f32Absolute
        case .f32Negate:
            return .f32Negate
        case .f32Ceil:
            return .f32Ceil
        case .f32Floor:
            return .f32Floor
        case .f32Truncate:
            return .f32Nearest
        case .f32Nearest:
            return .f32Nearest
        case .f32SquareRoot:
            return .f32SquareRoot
        case .f32Add:
            return .f32Add
        case .f32Subtract:
            return .f32Subtract
        case .f32Multiply:
            return .f32Multiply
        case .f32Divide:
            return .f32Divide
        case .f32Minimum:
            return .f32Minimum
        case .f32Maximum:
            return .f32Maximum
        case .f32CopySign:
            return .f32CopySign
        case .f64Absolute:
            return .f64Absolute
        case .f64Negate:
            return .f64Negate
        case .f64Ceil:
            return .f64Ceil
        case .f64Floor:
            return .f64Floor
        case .f64Truncate:
            return .f64Truncate
        case .f64Nearest:
            return .f64Nearest
        case .f64SquareRoot:
            return .f64SquareRoot
        case .f64Add:
            return .f64Add
        case .f64Subtract:
            return .f64Subtract
        case .f64Multiply:
            return .f64Multiply
        case .f64Divide:
            return .f64Divide
        case .f64Minimum:
            return .f64Minimum
        case .f64Maximum:
            return .f64Maximum
        case .f64CopySign:
            return .f64CopySign
        case .i32WrapI64:
            return .i32WrapI64
        case .i32TruncateF32Signed:
            return .i32TruncateF32Signed
        case .i32TruncateF32Unsigned:
            return .i32TruncateF32Unsigned
        case .i32TruncateF64Signed:
            return .i32TruncateF64Signed
        case .i32TruncateF64Unsigned:
            return .i32TruncateF64Unsigned
        case .i64ExtendI32Signed:
            return .i64ExtendI32Signed
        case .i64ExtendI32Unsigned:
            return .i64ExtendI32Unsigned
        case .i64TruncateF32Signed:
            return .i64TruncateF32Signed
        case .i64TruncateF32Unsigned:
            return .i64TruncateF32Unsigned
        case .i64TruncateF64Signed:
            return .i64TruncateF64Signed
        case .i64TruncateF64Unsigned:
            return .i64TruncateF64Unsigned
        case .f32ConvertI32Signed:
            return .f32ConvertI32Signed
        case .f32ConvertI32Unsigned:
            return .f32ConvertI32Unsigned
        case .f32ConvertI64Signed:
            return .f32ConvertI64Signed
        case .f32ConvertI64Unsigned:
            return .f32ConvertI64Unsigned
        case .f32DemoteF64:
            return .f32DemoteF64
        case .f64ConvertI32Signed:
            return .f64ConvertI32Signed
        case .f64ConvertI32Unsigned:
            return .f64ConvertI32Unsigned
        case .f64ConvertI64Signed:
            return .f64ConvertI64Signed
        case .f64ConvertI64Unsigned:
            return .f64ConvertI64Unsigned
        case .f64PromoteF32:
            return .f64PromoteF32
        case .i32ReinterpretF32:
            return .i32ReinterpretF32
        case .i64ReinterpretF64:
            return .i64ReinterpretF64
        case .f32ReinterpretI32:
            return .f32ReinterpretI32
        case .f64ReinterpretI64:
            return .f64ReinterpretI64
        }
    }
}
