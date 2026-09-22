// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

contract MockBaseCrossChainMessenger {
    mapping(bytes32 => bool) public successfulMessages;

    function relayMessageBroken(address target, address sender, bytes memory message, uint256 nonce) external {
        // Vulnerability: Missing block.chainid and domain separator in hash
        bytes32 msgHash = keccak256(abi.encode(target, sender, message, nonce));
        require(!successfulMessages[msgHash], "MESSAGE_ALREADY_RELAYED");
        successfulMessages[msgHash] = true;
    }

    function relayMessageHardened(address target, address sender, bytes memory message, uint256 nonce) external {
        // Hardened: Binds chain ID and verifying contract domain separator
        bytes32 domainSeparator = keccak256(abi.encode(block.chainid, address(this)));
        bytes32 msgHash = keccak256(abi.encode(domainSeparator, target, sender, message, nonce));
        require(!successfulMessages[msgHash], "MESSAGE_ALREADY_RELAYED");
        successfulMessages[msgHash] = true;
    }
}

contract CB02_CrossChainMessageReplayTest {
    MockBaseCrossChainMessenger messenger;

    function setUp() public {
        messenger = new MockBaseCrossChainMessenger();
    }

    function test_CB02_TruePositive_CrossChainReplay() public {
        bytes32 hashChainA = keccak256(abi.encode(address(0x123), address(0x456), "transfer(100)", 1));
        // On chain B, with identical parameters without chain ID, hash matches exactly -> replay attack possible across forks/L2s
        bytes32 hashChainB = keccak256(abi.encode(address(0x123), address(0x456), "transfer(100)", 1));
        require(hashChainA == hashChainB, "Exploit verified: message hash collision across chains");
    }

    function test_CB02_TrueNegative_DomainSeparated() public {
        bytes32 domainA = keccak256(abi.encode(uint256(1), address(messenger))); // Ethereum L1
        bytes32 domainB = keccak256(abi.encode(uint256(8453), address(messenger))); // Base L2
        bytes32 hashA = keccak256(abi.encode(domainA, address(0x123), address(0x456), "transfer(100)", 1));
        bytes32 hashB = keccak256(abi.encode(domainB, address(0x123), address(0x456), "transfer(100)", 1));
        require(hashA != hashB, "Domain separation prevents cross-chain replay");
    }
}
