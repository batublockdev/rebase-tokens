//SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

//// ---IMPORTS ---/////////
import {IRebaseToken} from "./Interface/IRebaseToken.sol";

/**
 * @title Vault
 * @author batublockdev
 * @notice this contract is used to store the funds of the users
 * while earning rewards in the RebaseToken contract
 * and in the same time to allow the users to withdraw their funds
 * and redeem their rewards
 */

contract Vault {
    ///////-- Errors ---/////////
    error Vault__AmountCanNotBeZero();
    error Vault__TransferFaild();
    error Vault__AmountExeedTheBalance();
    //// variables
    IRebaseToken private immutable i_rebaseToken;

    ///////Events
    event Deposit(address indexed user, uint256 amount);

    constructor(IRebaseToken _rebaseToken) {
        i_rebaseToken = _rebaseToken;
    }

    receive() external payable {}

    function deposit() external payable {
        if (msg.value == 0) {
            revert Vault__AmountCanNotBeZero();
        }
        uint256 interestRate = i_rebaseToken.getUserInterestRate(msg.sender);
        i_rebaseToken.mint(msg.sender, msg.value, interestRate);
        emit Deposit(msg.sender, msg.value);
    }

    function redeem(uint256 _amount) external {
        if (_amount == type(uint256).max) {
            _amount = i_rebaseToken.balanceOf(msg.sender);
        }
        if (_amount == 0) {
            revert Vault__AmountCanNotBeZero();
        }
        if (_amount > i_rebaseToken.balanceOf(msg.sender)) {
            revert Vault__AmountExeedTheBalance();
        }
        (bool success, ) = payable(msg.sender).call{value: _amount}("");
        if (!success) {
            revert Vault__TransferFaild();
        }
        i_rebaseToken.burn(msg.sender, _amount);
    }

    function getRebaseToken() external view returns (address) {
        return address(i_rebaseToken);
    }
}
