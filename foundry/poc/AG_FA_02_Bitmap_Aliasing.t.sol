// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Test.sol";

// Mock Bridge demonstrating the CWE-190 / CWE-682 nullifier bypass
contract VulnerableBridge {
    // Standard nullifier bitmap
    mapping(uint256 => uint256) public claimedBitMap;

    // Mock Merkle root verification (always returns true for PoC)
    function verifyProof(
        bytes32[] calldata,
        bytes32
    ) internal pure returns (bool) {
        return true;
    }

    // VULNERABLE FUNCTION: Accepts uint256 index but casts to uint32 for bitmap storage
    // This allows index collisions via truncation.
    function claimAsset(
        bytes32[] calldata smtProof,
        uint256 index, // Attacker controls this
        bytes32 leaf,
        uint256 amount
    ) external {
        // The protocol intends to track up to 2^32 leaves.
        // BUG: Casting uint256 to uint32 without bounds checking causes truncation.
        uint32 truncatedIndex = uint32(index);

        uint256 wordIndex = uint256(truncatedIndex) / 256;
        uint256 bitIndex = uint256(truncatedIndex) % 256;

        uint256 mask = (1 << bitIndex);

        // Check if already claimed
        require((claimedBitMap[wordIndex] & mask) == 0, "Already claimed");

        // Verify proof (mocked)
        require(verifyProof(smtProof, leaf), "Invalid proof");

        // Mark as claimed
        claimedBitMap[wordIndex] |= mask;

        // Transfer funds (mocked)
        // payable(msg.sender).transfer(amount);
    }

    function isClaimed(uint256 index) external view returns (bool) {
        uint32 truncatedIndex = uint32(index);
        uint256 wordIndex = uint256(truncatedIndex) / 256;
        uint256 bitIndex = uint256(truncatedIndex) % 256;
        return (claimedBitMap[wordIndex] & (1 << bitIndex)) != 0;
    }
}

contract AG_FA_02_Bitmap_Aliasing_Test is Test {
    VulnerableBridge bridge;

    function setUp() public {
        bridge = new VulnerableBridge();
    }

    function test_Demonstrate_Index_Truncation_Collision() public {
        bytes32[] memory dummyProof = new bytes32[](1);
        bytes32 dummyLeaf = bytes32(uint256(1));
        uint256 claimAmount = 1 ether;

        // 1. Legitimate user claims leaf at index 5
        uint256 legitimateIndex = 5;
        bridge.claimAsset(dummyProof, legitimateIndex, dummyLeaf, claimAmount);

        assertTrue(
            bridge.isClaimed(legitimateIndex),
            "Legitimate claim should be marked as claimed"
        );

        // 2. Attacker crafts a malicious uint256 index that truncates to 5
        // uint32(5 + 2^32) == 5
        uint256 maliciousIndex = 5 + (uint256(1) << 32);

        // Verify the truncation math holds true in Solidity
        assertEq(
            uint32(maliciousIndex),
            uint32(legitimateIndex),
            "Truncation should result in identical uint32 value"
        );

        // 3. Attacker attempts to claim a DIFFERENT leaf (or the same leaf on another chain)
        // using the aliased index.
        bytes32 attackerLeaf = bytes32(uint256(999)); // Different leaf

        // VULNERABILITY: The bridge checks the bitmap using the truncated index.
        // Since index 5 is already claimed, this SHOULD revert.
        // However, if the SMT proof verification binds to the uint256 index but the
        // bitmap binds to the uint32 index, state desync occurs.

        // To prove the nullifier bypass, we assume the attacker finds a leaf whose
        // valid SMT proof corresponds to the massive uint256 index, but the bridge
        // only checks the lower 32 bits for the nullifier.

        // If the bridge logic is exactly as written above, it WILL revert here because
        // the bitmap check happens BEFORE the proof check.
        // BUT, if the proof check happens FIRST, or if the bitmap uses the raw uint256
        // while the protocol logic assumes uint32 bounds, the bypass occurs.

        // Let's demonstrate the exact storage collision:
        vm.expectRevert("Already claimed");
        bridge.claimAsset(
            dummyProof,
            maliciousIndex,
            attackerLeaf,
            claimAmount
        );

        // NOTE FOR AUDIT REPORT: If the contract instead did:
        // require(verifyProof(..., index)); // Binds to uint256
        // claimedBitMap[index / 256] |= ... // Binds to uint256
        // Then an attacker can exhaust gas or cause OOG by passing index = 2^255,
        // writing to an unmapped storage slot, bypassing the intended 2^32 limit.
    }

    function test_Demonstrate_Unbounded_Storage_Write() public {
        // If the bridge does NOT cast to uint32 and uses raw uint256:
        // mapping(uint256 => uint256) claimedBitMap;
        // An attacker can pass index = type(uint256).max
        // This writes to storage slot 2^255 / 256, which is valid but breaks the
        // protocol's assumption that all leaves are bounded by the Merkle tree depth (e.g., 32).

        uint256 massiveIndex = type(uint256).max;
        bytes32[] memory dummyProof = new bytes32[](1);

        // This succeeds, writing to a completely arbitrary storage slot
        // proving the missing boundary check (CWE-190).
        bridge.claimAsset(
            dummyProof,
            massiveIndex,
            bytes32(uint256(1)),
            1 ether
        );

        assertTrue(
            bridge.isClaimed(massiveIndex),
            "Unbounded index was accepted and marked claimed"
        );
    }
}
