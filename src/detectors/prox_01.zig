//! prox_01.zig: ERC-1967 / ERC-7201 Proxy Storage Invariant Detector
//! Part of ROCHE Silicon EVM Security Engine.
//! Written in Pure Zig 0.16.0 with 0 Dynamic Heap Allocations.
//! Invariant: Zero Heap Allocation (`malloc=0`) | Fixed-Size Buffers | Cache-Line Aligned.

const std = @import("std");

// ============================================================================
// CONSTANTS: ERC-1967 & ERC-7201 SLOTS & SELECTORS
// ============================================================================

/// ERC-1967 Implementation Slot:
/// bytes32(uint256(keccak256('eip1967.proxy.implementation')) - 1)
pub const ERC1967_IMPLEMENTATION_SLOT: u256 = 0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc;

/// ERC-7201 Initializable Storage Slot (OpenZeppelin v5 Initializable namespace):
/// keccak256(abi.encode(uint256(keccak256("openzeppelin.storage.Initializable")) - 1)) & ~bytes32(uint256(0xff))
pub const ERC7201_INITIALIZABLE_SLOT: u256 = 0xf0c57e16840df040f15088dc2f81fe391c3923bec73e23a9662efc9c229c6a00;

/// Value written by OpenZeppelin `_disableInitializers()`:
/// uint64.max stored in low 64 bits = 0xffffffffffffffff
pub const INITIALIZABLE_LOCKED_VALUE: u64 = 0xffffffffffffffff;

/// ERC-20 totalSupply() function selector: bytes4(keccak256("totalSupply()"))
pub const TOTAL_SUPPLY_SELECTOR: [4]u8 = [_]u8{ 0x18, 0x16, 0x0d, 0xdd };

// ============================================================================
// ZERO-HEAP FINDING & DETECTOR INTERFACE STRUCTURES
// ============================================================================

pub const Severity = enum(u8) {
    Info = 1,
    Low = 3,
    Medium = 5,
    High = 8,
    Critical = 10,
};

pub const Finding = struct {
    severity: Severity = .Info,
    title: [64]u8 = [_]u8{0} ** 64,
    title_len: usize = 0,
    description: [256]u8 = [_]u8{0} ** 256,
    description_len: usize = 0,

    pub fn init(severity: Severity, title_str: []const u8, desc_str: []const u8) Finding {
        var f = Finding{
            .severity = severity,
        };
        const t_len = @min(title_str.len, 64);
        @memcpy(f.title[0..t_len], title_str[0..t_len]);
        f.title_len = t_len;

        const d_len = @min(desc_str.len, 256);
        @memcpy(f.description[0..d_len], desc_str[0..d_len]);
        f.description_len = d_len;
        return f;
    }

    pub fn getTitle(self: *const Finding) []const u8 {
        return self.title[0..self.title_len];
    }

    pub fn getDescription(self: *const Finding) []const u8 {
        return self.description[0..self.description_len];
    }
};

pub const MAX_FINDINGS_PER_MODULE: usize = 8;

pub const Findings = struct {
    items: [MAX_FINDINGS_PER_MODULE]Finding = [_]Finding{.{}} ** MAX_FINDINGS_PER_MODULE,
    count: usize = 0,

    pub fn add(self: *Findings, finding: Finding) void {
        if (self.count < MAX_FINDINGS_PER_MODULE) {
            self.items[self.count] = finding;
            self.count += 1;
        }
    }

    pub fn hasFindings(self: *const Findings) bool {
        return self.count > 0;
    }
};

/// Fixed-size Storage Key: [20-byte address, 32-byte slot]
pub const StorageKey = struct {
    address: [20]u8 = [_]u8{0} ** 20,
    slot: [32]u8 = [_]u8{0} ** 32,

    pub inline fn fromU256(addr: [20]u8, slot_u256: u256) StorageKey {
        var k = StorageKey{ .address = addr };
        std.mem.writeInt(u256, &k.slot, slot_u256, .big);
        return k;
    }
};

/// Fixed-capacity state view for detector evaluation (0 heap allocation)
pub const MAX_STATE_ENTRIES: usize = 64;

pub const StateEntry = struct {
    key: StorageKey = .{},
    value: u256 = 0,
    is_set: bool = false,
};

pub const State = struct {
    proxy_address: [20]u8 = [_]u8{0} ** 20,
    entries: [MAX_STATE_ENTRIES]StateEntry = [_]StateEntry{.{}} ** MAX_STATE_ENTRIES,
    entry_count: usize = 0,
    total_supply: ?u256 = null,

    pub fn init(proxy_addr: [20]u8) State {
        return .{
            .proxy_address = proxy_addr,
        };
    }

    pub fn setStorage(self: *State, addr: [20]u8, slot: u256, val: u256) void {
        const key = StorageKey.fromU256(addr, slot);
        for (0..self.entry_count) |i| {
            if (std.mem.eql(u8, &self.entries[i].key.address, &key.address) and
                std.mem.eql(u8, &self.entries[i].key.slot, &key.slot))
            {
                self.entries[i].value = val;
                self.entries[i].is_set = true;
                return;
            }
        }
        if (self.entry_count < MAX_STATE_ENTRIES) {
            self.entries[self.entry_count] = .{
                .key = key,
                .value = val,
                .is_set = true,
            };
            self.entry_count += 1;
        }
    }

    pub fn readStorage(self: *const State, addr: [20]u8, slot: u256) u256 {
        const key = StorageKey.fromU256(addr, slot);
        for (0..self.entry_count) |i| {
            if (self.entries[i].is_set and
                std.mem.eql(u8, &self.entries[i].key.address, &key.address) and
                std.mem.eql(u8, &self.entries[i].key.slot, &key.slot))
            {
                return self.entries[i].value;
            }
        }
        return 0;
    }

    pub fn setTotalSupply(self: *State, supply: u256) void {
        self.total_supply = supply;
    }

    pub fn readTotalSupply(self: *const State, _: [20]u8) u256 {
        return self.total_supply orelse 0;
    }
};

// ============================================================================
// DETECTOR IMPLEMENTATION
// ============================================================================

pub const Prox01Detector = struct {
    pub fn evaluate(state: *const State) Findings {
        var findings = Findings{};

        // 1. Read the implementation address from the target contract's storage (ERC-1967 slot)
        const impl_u256 = state.readStorage(state.proxy_address, ERC1967_IMPLEMENTATION_SLOT);
        if (impl_u256 == 0) {
            // Not an ERC-1967 proxy, return early with zero findings
            return findings;
        }

        // Convert u256 to 20-byte address (lower 160 bits)
        var impl_addr: [20]u8 = [_]u8{0} ** 20;
        var temp_val = impl_u256;
        var i: usize = 20;
        while (i > 0) {
            i -= 1;
            impl_addr[i] = @truncate(temp_val & 0xFF);
            temp_val >>= 8;
        }

        // 2. Read the ERC-7201 slot from the IMPLEMENTATION address
        const init_slot_val = state.readStorage(impl_addr, ERC7201_INITIALIZABLE_SLOT);

        // Check if locked: low 64 bits equal type(uint64).max (0xffffffffffffffff)
        const low64: u64 = @truncate(init_slot_val);
        const is_locked = (low64 == INITIALIZABLE_LOCKED_VALUE);

        // 3. If locked, evaluate proxy operational status via totalSupply (selector 0x18160ddd)
        // DO NOT emit a Critical finding.
        if (is_locked) {
            const total_supply = state.readTotalSupply(state.proxy_address);
            if (total_supply > 0) {
                findings.add(Finding.init(
                    .Info,
                    "PROX-01: Proxy Operational",
                    "Proxy operational, implementation securely locked.",
                ));
            } else {
                findings.add(Finding.init(
                    .Low,
                    "PROX-01: Uninitialized Proxy Storage",
                    "Proxy storage uninitialized, verify deployment.",
                ));
            }
        }

        return findings;
    }
};

// Interface wrapper conforming to standard Detector contract
pub const DetectorInterface = struct {
    pub fn evaluate(state: *State) Findings {
        return Prox01Detector.evaluate(state);
    }
};

// ============================================================================
// UNIT TESTS (Pure Zig 0.16.0, 0 Allocations)
// ============================================================================

test "PROX-01: Returns early if contract is not a proxy (impl == 0)" {
    const proxy_addr: [20]u8 = [_]u8{0xAA} ** 20;
    var state = State.init(proxy_addr);

    const findings = Prox01Detector.evaluate(&state);
    try std.testing.expectEqual(@as(usize, 0), findings.count);
    try std.testing.expect(!findings.hasFindings());
}

test "PROX-01: Implementation locked and totalSupply > 0 emits Info finding" {
    const proxy_addr: [20]u8 = [_]u8{0x11} ** 20;
    const impl_addr: [20]u8 = [_]u8{0x22} ** 20;
    var state = State.init(proxy_addr);

    // Set implementation address in ERC-1967 slot
    var impl_u256: u256 = 0;
    for (impl_addr) |b| {
        impl_u256 = (impl_u256 << 8) | @as(u256, b);
    }
    state.setStorage(proxy_addr, ERC1967_IMPLEMENTATION_SLOT, impl_u256);

    // Set ERC-7201 initializable slot on implementation to uint64.max
    state.setStorage(impl_addr, ERC7201_INITIALIZABLE_SLOT, 0xffffffffffffffff);

    // Set totalSupply on proxy > 0 (e.g. 11,055,756 USDC)
    state.setTotalSupply(11_055_756_000_000);

    const findings = Prox01Detector.evaluate(&state);
    try std.testing.expectEqual(@as(usize, 1), findings.count);
    try std.testing.expectEqual(Severity.Info, findings.items[0].severity);
    try std.testing.expectEqualStrings("Proxy operational, implementation securely locked.", findings.items[0].getDescription());
}

test "PROX-01: Implementation locked and totalSupply == 0 emits Low finding" {
    const proxy_addr: [20]u8 = [_]u8{0x33} ** 20;
    const impl_addr: [20]u8 = [_]u8{0x44} ** 20;
    var state = State.init(proxy_addr);

    var impl_u256: u256 = 0;
    for (impl_addr) |b| {
        impl_u256 = (impl_u256 << 8) | @as(u256, b);
    }
    state.setStorage(proxy_addr, ERC1967_IMPLEMENTATION_SLOT, impl_u256);

    // Implementation locked
    state.setStorage(impl_addr, ERC7201_INITIALIZABLE_SLOT, 0xffffffffffffffff);

    // totalSupply == 0
    state.setTotalSupply(0);

    const findings = Prox01Detector.evaluate(&state);
    try std.testing.expectEqual(@as(usize, 1), findings.count);
    try std.testing.expectEqual(Severity.Low, findings.items[0].severity);
    try std.testing.expectEqualStrings("Proxy storage uninitialized, verify deployment.", findings.items[0].getDescription());
}
