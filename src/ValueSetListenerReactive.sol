// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {AbstractReactive} from "../lib/reactive-lib/src/abstract-base/AbstractReactive.sol";
import {IReactive} from "../lib/reactive-lib/src/interfaces/IReactive.sol";
import {IPayable} from "../lib/reactive-lib/src/interfaces/IPayable.sol";
import {ISystemContract} from "../lib/reactive-lib/src/interfaces/ISystemContract.sol";

contract ValueSetListenerReactive is IReactive, AbstractReactive {
    error UnexpectedSource(uint256 chainId, address contractAddress, uint256 topic0);

    uint64 public constant CALLBACK_GAS_LIMIT = 1_000_000;

    uint256 public immutable originChainId;
    uint256 public immutable destinationChainId;
    address public immutable originContract;
    uint256 public immutable expectedTopic0;
    address public immutable destinationContract;

    constructor(
        address _service,
        uint256 _originChainId,
        uint256 _destinationChainId,
        address _originContract,
        uint256 _expectedTopic0,
        address _destinationContract
    ) payable {
        service = ISystemContract(payable(_service));
        vendor = IPayable(payable(_service));
        addAuthorizedSender(_service);
        originChainId = _originChainId;
        destinationChainId = _destinationChainId;
        originContract = _originContract;
        expectedTopic0 = _expectedTopic0;
        destinationContract = _destinationContract;

        if (!vm) {
            service.subscribe(
                _originChainId, _originContract, _expectedTopic0, REACTIVE_IGNORE, REACTIVE_IGNORE, REACTIVE_IGNORE
            );
        }
    }

    function react(LogRecord calldata logRecord) external vmOnly {
        if (
            logRecord.chain_id != originChainId || logRecord._contract != originContract
                || logRecord.topic_0 != expectedTopic0
        ) {
            revert UnexpectedSource(logRecord.chain_id, logRecord._contract, logRecord.topic_0);
        }

        address originalSender = address(uint160(logRecord.topic_1));
        uint256 newValue = logRecord.topic_2;
        uint256 originTimestamp = abi.decode(logRecord.data, (uint256));

        bytes memory payload = abi.encodeWithSignature(
            "callback(address,uint256,address,address,uint256,uint256)",
            address(0),
            logRecord.chain_id,
            logRecord._contract,
            originalSender,
            newValue,
            originTimestamp
        );

        emit Callback(destinationChainId, destinationContract, CALLBACK_GAS_LIMIT, payload);
    }
}
