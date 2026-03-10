// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {AbstractPayer} from "../lib/reactive-lib/src/abstract-base/AbstractPayer.sol";
import {IPayable} from "../lib/reactive-lib/src/interfaces/IPayable.sol";

contract DestinationCallbackReceiver is AbstractPayer {
    event CallbackReceived(
        address indexed origin,
        address indexed sender,
        address indexed rvmId,
        uint256 originChainId,
        address originContract,
        address originalSender,
        uint256 newValue,
        uint256 originTimestamp
    );

    address public immutable callbackProxy;
    address public immutable authorizedRvmId;

    address public lastOriginalSender;
    uint256 public lastOriginChainId;
    address public lastOriginContract;
    uint256 public mirroredValue;
    uint256 public lastOriginTimestamp;

    modifier rvmIdOnly(address rvmId) {
        require(authorizedRvmId == address(0) || authorizedRvmId == rvmId, "Authorized RVM ID only");
        _;
    }

    constructor(address _callbackProxy) payable {
        callbackProxy = _callbackProxy;
        authorizedRvmId = msg.sender;
        vendor = IPayable(payable(_callbackProxy));
        addAuthorizedSender(_callbackProxy);
    }

    function callback(
        address rvmId,
        uint256 originChainId,
        address originContract,
        address originalSender,
        uint256 newValue,
        uint256 originTimestamp
    ) external authorizedSenderOnly rvmIdOnly(rvmId) {
        lastOriginChainId = originChainId;
        lastOriginContract = originContract;
        lastOriginalSender = originalSender;
        mirroredValue = newValue;
        lastOriginTimestamp = originTimestamp;

        emit CallbackReceived(tx.origin, msg.sender, rvmId, originChainId, originContract, originalSender, newValue, originTimestamp);
    }
}
