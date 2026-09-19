//! Raw C-ABI bindings for Volta native engine.

#[repr(C)]
#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub struct CTxCall {
    pub selector: [u8; 4],
    pub args: [u64; 4],
    pub caller: [u8; 20],
    pub value: u64,
}

#[repr(C)]
#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub struct CTraceResult {
    pub original_steps: u32,
    pub minimized_steps: u32,
    pub elapsed_nanos: u64,
    pub causal_step_indices: [u32; 32],
    pub has_callback_harness: bool,
}

#[derive(Debug, Clone, Copy, PartialEq, Eq)]
#[repr(u8)]
pub enum CallbackType {
    None = 0,
    ERC3156FlashBorrower = 1,
    UniswapV3SwapCallback = 2,
    ERC777TokensReceived = 3,
    ReentrancyCustom = 4,
}

extern "C" {
    /// Return current Volta engine semantic version string pointer
    pub fn volta_c_version() -> *const std::os::raw::c_char;

    /// Execute raw EVM bytecode in bare-silicon VM
    pub fn volta_c_execute(bytecode_ptr: *const u8, bytecode_len: usize) -> u8;

    /// Run full 22-detector static security audit suite on bytecode
    pub fn volta_c_audit(bytecode_ptr: *const u8, bytecode_len: usize) -> u32;

    /// Minimize an execution trace using RAW dynamic dependency slicing
    pub fn volta_c_minimize_trace(
        step_count: u32,
        read_slots: *const u64,
        write_slots: *const u64,
        failing_step: u32,
        out_result: *mut CTraceResult,
    ) -> u32;

    /// Synthesize a runnable Foundry Solidity PoC (.t.sol) into a caller-supplied buffer
    pub fn volta_c_synthesize_poc(
        test_name_ptr: *const u8,
        test_name_len: usize,
        target_hex_ptr: *const u8,
        target_hex_len: usize,
        inv_name_ptr: *const u8,
        inv_name_len: usize,
        callback_type: u8,
        out_buf: *mut u8,
        out_buf_max_len: usize,
    ) -> usize;
}
