// ============================================================================
// VOLTA SILICON KERNEL: Port of Eveem Proxy & Interface Pattern Classifier
// Invariant: Zero Heap Allocation | 64-Byte Cache Aligned | Zig 0.16.0
// ============================================================================

const std = @import("std");

pub const ProxyPatternType = enum(u8) {
    NotProxy,
    EIP1967_Implementation,
    EIP1967_Beacon,
    EIP1822_Universal,
    Diamond_Storage,
};

pub const EIP1967_IMPLEMENTATION_SLOT: u256 = 0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc;
pub const EIP1967_BEACON_SLOT: u256 = 0xa3f0ad74e5423aebfd80d3ef4346578335a9a72aeaee59ff6cb3582b35133d50;
pub const EIP1822_PROXIABLE_SLOT: u256 = 0xc5f1683664b30ec827f00e808a1184263bce43e7c92d300d36b0337157747a02;

pub const ProxyClassifier = struct {
    pub fn classifyBySlot(slot: u256) ProxyPatternType {
        if (slot == EIP1967_IMPLEMENTATION_SLOT) return .EIP1967_Implementation;
        if (slot == EIP1967_BEACON_SLOT) return .EIP1967_Beacon;
        if (slot == EIP1822_PROXIABLE_SLOT) return .EIP1822_Universal;
        return .NotProxy;
    }

    pub fn inspectBytecodeForDelegatecall(code: []const u8) bool {
        for (code) |op| {
            if (op == 0xF4) return true; // DELEGATECALL
        }
        return false;
    }
};
