// SPDX-License-Identifier: UNLICENSED

pragma solidity >=0.8.0;

import "../interfaces/IPayer.sol";
import "../interfaces/IPayable.sol";

/// @title Abstract base contract for contracts needing to handle payments to the system contract or callback proxies.
abstract contract AbstractPayer is IPayer {
    IPayable internal vendor;

    /// @notice ACL for addresses allowed to make callbacks and/or request payment.
    mapping(address => bool) senders;

    constructor() {}

    /// @inheritdoc IPayer
    receive() virtual external payable {}

    modifier authorizedSenderOnly() {
        require(senders[msg.sender], "Authorized sender only");
        _;
    }

    /// @inheritdoc IPayer
    function pay(uint256 amount) external authorizedSenderOnly {
        _pay(payable(msg.sender), amount);
    }

    /// @notice Automatically cover the outstanding debt to the system contract or callback proxy, provided the contract has sufficient funds.
    function coverDebt() external {
        uint256 amount = vendor.debt(address(this));
        _pay(payable(vendor), amount);
    }

    /// @notice Attempts to safely transfer the specified sum to the given address.
    function _pay(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Insufficient funds");
        if (amount > 0) {
            (bool success,) = payable(recipient).call{value: amount}(new bytes(0));
            require(success, "Transfer failed");
        }
    }

    /// @notice Adds the given address to the ACL.
    function addAuthorizedSender(address sender) internal {
        senders[sender] = true;
    }

    /// @notice Removes the given address from the ACL.
    function removeAuthorizedSender(address sender) internal {
        senders[sender] = false;
    }
}

