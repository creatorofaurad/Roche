//! # roche-rs: Institutional EVM Verification & Roche Limit Trace Reduction Engine
//!
//! Native Rust bindings for the bare-silicon **Roche** engine written in Pure Zig 0.16.0.
//! Provides sub-microsecond EVM execution, dynamic RAW trace reduction, static security audits,
//! and automated Foundry PoC exploit synthesis with 0 dynamic heap allocations.

pub mod ffi;

pub use ffi::{CTraceResult, CTxCall, CallbackType};
use std::ffi::CStr;

/// Audit vulnerability bitmask flags
pub mod audit_flags {
    pub const REENTRANCY: u32 = 1 << 0;
    pub const UNPROTECTED_SELFDESTRUCT: u32 = 1 << 1;
    pub const UNINITIALIZED_STORAGE: u32 = 1 << 2;
    pub const UNCHECKED_LOW_LEVEL_CALL: u32 = 1 << 3;
    pub const ARBITRARY_DELEGATECALL: u32 = 1 << 4;
    pub const TX_ORIGIN_AUTH: u32 = 1 << 5;
    pub const READ_ONLY_REENTRANCY: u32 = 1 << 6;
}

/// Execution status codes returned by the bare-silicon EVM
#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub enum ExecutionStatus {
    Success = 0,
    Revert = 1,
    OutOfGas = 2,
    StackUnderflow = 3,
    StackOverflow = 4,
    InvalidOpcode = 5,
    InvalidJump = 6,
    WriteProtection = 7,
    Unknown = 255,
}

impl From<u8> for ExecutionStatus {
    fn from(val: u8) -> Self {
        match val {
            0 => ExecutionStatus::Success,
            1 => ExecutionStatus::Revert,
            2 => ExecutionStatus::OutOfGas,
            3 => ExecutionStatus::StackUnderflow,
            4 => ExecutionStatus::StackOverflow,
            5 => ExecutionStatus::InvalidOpcode,
            6 => ExecutionStatus::InvalidJump,
            7 => ExecutionStatus::WriteProtection,
            _ => ExecutionStatus::Unknown,
        }
    }
}

/// Roche Native Engine Interface
pub struct Roche;

impl Roche {
    /// Return the semantic version string of the underlying bare-silicon engine
    pub fn version() -> &'static str {
        unsafe {
            let ptr = ffi::roche_c_version();
            if ptr.is_null() {
                "unknown"
            } else {
                CStr::from_ptr(ptr).to_str().unwrap_or("unknown")
            }
        }
    }

    /// Execute bytecode directly on Roche bare-silicon VM
    pub fn execute(bytecode: &[u8]) -> ExecutionStatus {
        if bytecode.is_empty() {
            return ExecutionStatus::Success;
        }
        let status = unsafe { ffi::roche_c_execute(bytecode.as_ptr(), bytecode.len()) };
        ExecutionStatus::from(status)
    }

    /// Run full Slither-equivalent static security audit detector suite
    pub fn audit(bytecode: &[u8]) -> u32 {
        if bytecode.is_empty() {
            return 0;
        }
        unsafe { ffi::roche_c_audit(bytecode.as_ptr(), bytecode.len()) }
    }

    /// Minimize a multi-step execution trace via RAW dynamic backward DAG reachability
    pub fn minimize_trace(
        read_slots: &[u64],
        write_slots: &[u64],
        failing_step: u32,
    ) -> Option<CTraceResult> {
        let count = read_slots.len().min(write_slots.len()) as u32;
        if count == 0 || failing_step >= count {
            return None;
        }

        let mut result = CTraceResult {
            original_steps: count,
            minimized_steps: 0,
            elapsed_nanos: 0,
            causal_step_indices: [0; 32],
            has_callback_harness: false,
        };

        let reduced = unsafe {
            ffi::roche_c_minimize_trace(
                count,
                read_slots.as_ptr(),
                write_slots.as_ptr(),
                failing_step,
                &mut result as *mut CTraceResult,
            )
        };

        if reduced > 0 {
            Some(result)
        } else {
            None
        }
    }

    /// Synthesize a runnable Foundry Solidity test (.t.sol) PoC
    pub fn synthesize_poc(
        test_name: &str,
        target_bytecode_hex: &str,
        invariant_name: &str,
        callback: CallbackType,
    ) -> Result<String, &'static str> {
        let mut buf = vec![0u8; 16384];
        let written = unsafe {
            ffi::roche_c_synthesize_poc(
                test_name.as_ptr(),
                test_name.len(),
                target_bytecode_hex.as_ptr(),
                target_bytecode_hex.len(),
                invariant_name.as_ptr(),
                invariant_name.len(),
                callback as u8,
                buf.as_mut_ptr(),
                buf.len(),
            )
        };

        if written == 0 {
            return Err("Failed to synthesize PoC harness");
        }

        buf.truncate(written);
        String::from_utf8(buf).map_err(|_| "Invalid UTF-8 in synthesized PoC")
    }
}

// Backward-compatibility alias
pub type Volta = Roche;

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_roche_version() {
        let ver = Roche::version();
        assert!(!ver.is_empty());
    }

    #[test]
    fn test_roche_execution() {
        let code = [0x60, 0x01, 0x60, 0x02, 0x01, 0x60, 0x00, 0x55, 0x00];
        let status = Roche::execute(&code);
        assert_eq!(status, ExecutionStatus::Success);
    }

    #[test]
    fn test_roche_audit() {
        let code = [0x60, 0x01, 0x60, 0x02, 0x01, 0x60, 0x00, 0x55, 0x00];
        let mask = Roche::audit(&code);
        let _ = mask;
    }

    #[test]
    fn test_trace_minimizer() {
        let reads = [0x00, 0x00, 0x100];
        let writes = [0x100, 0x200, 0x00];
        let res = Roche::minimize_trace(&reads, &writes, 2);
        assert!(res.is_some());
        let res = res.unwrap();
        assert_eq!(res.minimized_steps, 2);
    }

    #[test]
    fn test_poc_synthesis() {
        let poc = Roche::synthesize_poc(
            "ArbitrumVaultExploit",
            "6000F16103E860005500",
            "verifySolvency",
            CallbackType::ERC3156FlashBorrower,
        );
        assert!(poc.is_ok());
        let poc_str = poc.unwrap();
        assert!(poc_str.contains("IERC3156FlashBorrower"));
        assert!(poc_str.contains("ArbitrumVaultExploit_AttackerHarness"));
    }
}
