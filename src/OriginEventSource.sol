// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

contract OriginEventSource {
    event ValueSet(address indexed sender, uint256 indexed newValue, uint256 emittedAt);

    uint256 public value;

    function setValue(uint256 newValue) external {
        value = newValue;
        emit ValueSet(msg.sender, newValue, block.timestamp);
    }

    function valueSetTopic0() external pure returns (bytes32) {
        return keccak256("ValueSet(address,uint256,uint256)");
    }
}
