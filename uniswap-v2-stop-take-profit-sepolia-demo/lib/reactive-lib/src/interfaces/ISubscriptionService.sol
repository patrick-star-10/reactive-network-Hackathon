// SPDX-License-Identifier: UNLICENSED

pragma solidity >=0.8.0;

import "./IPayable.sol";

/// @title Interface for event subscription service.
/// @notice Reactive contracts receive notifications about new events matching the criteria of their event subscriptions.
interface ISubscriptionService is IPayable {
    function subscribe(
        uint256 chain_id,
        address _contract,
        uint256 topic_0,
        uint256 topic_1,
        uint256 topic_2,
        uint256 topic_3
    ) external;

    function unsubscribe(
        uint256 chain_id,
        address _contract,
        uint256 topic_0,
        uint256 topic_1,
        uint256 topic_2,
        uint256 topic_3
    ) external;
}
