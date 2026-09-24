// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/// @title RocheChecker
/// @notice Solidity helper library providing assertion & invariant verification primitives for Roche Engine
library RocheChecker {
    event InvariantChecked(string tag, bool passed);

    function assertInvariant(bool condition, string memory tag) internal {
        emit InvariantChecked(tag, condition);
        require(condition, string(abi.encodePacked("Roche Invariant Violation: ", tag)));
    }

    function assertStateNoReentrancy(bool lockState, string memory tag) internal pure {
        require(lockState, string(abi.encodePacked("Roche Reentrancy Violation: ", tag)));
    }
}
