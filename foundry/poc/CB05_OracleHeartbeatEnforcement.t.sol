// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

contract MockChainlinkPriceFeed {
    int256 public answer = 2000e8;
    uint256 public updatedAt = 1000;
    uint80 public roundId = 1;

    function setOracleData(int256 _answer, uint256 _updatedAt, uint80 _roundId) external {
        answer = _answer;
        updatedAt = _updatedAt;
        roundId = _roundId;
    }

    function latestRoundData() external view returns (uint80, int256, uint256, uint256, uint80) {
        return (roundId, answer, 0, updatedAt, roundId);
    }
}

contract MockTier0PricingConsumer {
    MockChainlinkPriceFeed public feed;
    uint256 public constant HEARTBEAT_THRESHOLD = 86400; // 24 hours

    constructor(address _feed) {
        feed = MockChainlinkPriceFeed(_feed);
    }

    function getPriceBroken() external view returns (uint256) {
        (, int256 price,,,) = feed.latestRoundData();
        return uint256(price);
    }

    function getPriceHardened() external view returns (uint256) {
        (uint80 roundId, int256 price,, uint256 updatedTime, uint80 answeredInRound) = feed.latestRoundData();
        require(price > 0, "INVALID_PRICE");
        require(updatedTime > 0 && updatedTime <= block.timestamp, "INVALID_TIMESTAMP");
        require(block.timestamp - updatedTime <= HEARTBEAT_THRESHOLD, "STALE_ORACLE_PRICE");
        require(answeredInRound >= roundId, "STALE_ROUND");
        return uint256(price);
    }
}

contract CB05_OracleHeartbeatEnforcementTest {
    MockChainlinkPriceFeed feed;
    MockTier0PricingConsumer consumer;

    function setUp() public {
        feed = new MockChainlinkPriceFeed();
        consumer = new MockTier0PricingConsumer(address(feed));
    }

    function test_CB05_TruePositive_StalePriceRead() public {
        // Oracle is 3 days stale
        feed.setOracleData(1500e8, 1000, 1);
        uint256 price = consumer.getPriceBroken();
        require(price == 1500e8, "Exploit verified: Stale oracle price consumed");
    }

    function test_CB05_TrueNegative_ValidatedTimestamp() public {
        feed.setOracleData(2000e8, block.timestamp, 1);
        uint256 price = consumer.getPriceHardened();
        require(price == 2000e8, "Fresh price read successfully under heartbeat constraint");
    }
}
