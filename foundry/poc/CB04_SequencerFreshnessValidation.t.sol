// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

contract MockBaseSequencerOracle {
    uint256 public constant MAX_SEQUENCER_DOWNTIME = 3600; // 1 hour
    uint256 public constant GRACE_PERIOD_TIME = 1800; // 30 minutes

    function verifyStateProofBroken(uint256 rootTimestamp, uint256 blockTimestamp) external pure returns (bool) {
        // Bug: state root accepted regardless of sequencer downtime / restart window
        _ = blockTimestamp;
        _ = rootTimestamp;
        return true;
    }

    function verifyStateProofHardened(uint256 rootTimestamp, uint256 blockTimestamp, uint256 uptimeTimestamp, bool isSequencerUp) external pure returns (bool) {
        require(isSequencerUp, "SEQUENCER_DOWN");
        require(blockTimestamp - uptimeTimestamp >= GRACE_PERIOD_TIME, "GRACE_PERIOD_NOT_ELAPSED");
        require(blockTimestamp - rootTimestamp <= MAX_SEQUENCER_DOWNTIME, "STALE_STATE_ROOT");
        return true;
    }
}

contract CB04_SequencerFreshnessValidationTest {
    MockBaseSequencerOracle oracle;

    function setUp() public {
        oracle = new MockBaseSequencerOracle();
    }

    function test_CB04_TruePositive_StaleRootAccepted() public {
        // 5 hours stale
        bool valid = oracle.verifyStateProofBroken(1000, 1000 + 18000);
        require(valid, "Exploit verified: Stale root accepted without uptime validation");
    }

    function test_CB04_TrueNegative_FreshRootWithGracePeriod() public {
        uint256 current = 20000;
        uint256 rootTime = 19500;
        uint256 uptime = 18000;
        bool valid = oracle.verifyStateProofHardened(rootTime, current, uptime, true);
        require(valid, "Fresh root and elapsed grace period verified successfully");
    }
}
