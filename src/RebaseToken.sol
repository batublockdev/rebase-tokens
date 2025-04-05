//SPDX-License-Identifier: MIT
// Layout of Contract:
// version
// imports
// errors
// interfaces, libraries, contracts
// Type declarations
// State variables
// Events
// Modifiers
// Functions

// Layout of Functions:
// constructor
// receive function (if exists)
// fallback function (if exists)
// external
// public
// internal
// private
// view & pure functions
pragma solidity ^0.8.24;

import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {AccessControl} from "@openzeppelin/contracts/access/AccessControl.sol";

/**
 * @title RebaseToken
 * @author BatuBlockDev
 * @notice This is a cross-chain rebase token which incentivises users to deposi into a vault to earn rewards
 * @notice the interest rate in the smart contract can only decresase
 * @dev This contract is an ERC20 token with the name "Rebase Token" and the symbol "RBT"
 */
contract RebaseToken is ERC20, Ownable, AccessControl {
    ///////-- Errors ---/////////
    error RebaseToken__InterestRateCannotIncrease(
        uint256 newInterestRate,
        uint256 oldInterestRate
    );
    ///////-- State Variables ---////////
    uint256 private constant PRECISION_FACTOR = 1e18;
    bytes32 public constant MINT_AND_BURN_ROLE =
        keccak256("MINT_AND_BURN_ROLE");
    mapping(address => uint256) private s_usersInterestRate;
    mapping(address => uint256) private s_userLastUpdateTimestamp;
    uint256 private s_interestRate = (5 * PRECISION_FACTOR) / 1e8;

    //////// -- Events ---////////
    event InterestRateSet(uint256 newInterestRate);

    constructor() ERC20("Rebase Token", "RBT") Ownable(msg.sender) {}

    function grantMintAndBurnRole(address _account) external onlyOwner {
        _grantRole(MINT_AND_BURN_ROLE, _account);
    }

    /**
     * @dev the follow funtion is used to set the interest rate in the smart contract
     * @param _newInterestRate which is the new interest rate to be set
     * @notice the interest rate in the smart contract can only decresase
     */
    function setInterestRate(uint256 _newInterestRate) external onlyOwner {
        //Check if the new interest rate is less than the current interest rate
        if (_newInterestRate > s_interestRate) {
            revert RebaseToken__InterestRateCannotIncrease(
                _newInterestRate,
                s_interestRate
            );
        }
        s_interestRate = _newInterestRate;
        emit InterestRateSet(_newInterestRate);
    }

    /**
     * @dev the following function is used to get the principal balance of a user with no interest
     * @param _user which is the address of the user
     * @return the principal balance of the user
     */
    function principalBalanceOf(address _user) external view returns (uint256) {
        return super.balanceOf(_user);
    }

    /**
     *
     * @param _to which is the address of the user
     * @param _amount which is the amount of tokens to mint
     * @notice the interest rate of the user is set to the current interest rate
     */
    function mint(
        address _to,
        uint256 _amount,
        uint256 _interestRate
    ) external onlyRole(MINT_AND_BURN_ROLE) {
        if (_interestRate == 0) {
            _interestRate = s_interestRate;
        }
        _minAccruedInterest(_to);
        s_usersInterestRate[_to] = _interestRate;
        _mint(_to, _amount);
    }

    /**
     * @dev the following function is used to burn tokens from a user
     * @param _from which is the address of the user
     * @param _amount which is the amount of tokens to burn
     */
    function burn(
        address _from,
        uint256 _amount
    ) external onlyRole(MINT_AND_BURN_ROLE) {
        if (_amount == type(uint256).max) {
            _amount = balanceOf(_from);
        }
        _minAccruedInterest(_from);
        _burn(_from, _amount);
    }

    /**
     * @dev the following function is used to see the balance of a user accumulated with interest
     * @param _user which is the address of the user
     * @return the balance of the user accumulated with interest
     */

    function balanceOf(
        address _user
    ) public view virtual override returns (uint256) {
        return
            (super.balanceOf(_user) *
                _calculateAccruedInterestSinceLastUpdate(_user)) /
            PRECISION_FACTOR;
    }

    /**
     * @notice the following function is used to transfer tokens from one user to another
     * @param _recipient the address of the user who is receiving the tokens
     * @param _amount the amount of tokens to transfer
     * @return a boolean value
     */
    function transfer(
        address _recipient,
        uint256 _amount
    ) public virtual override returns (bool) {
        _minAccruedInterest(msg.sender);
        _minAccruedInterest(_recipient);
        if (_amount == type(uint256).max) {
            _amount = balanceOf(_recipient);
        }
        if (balanceOf(_recipient) == 0) {
            s_usersInterestRate[_recipient] = s_usersInterestRate[msg.sender];
        }
        return super.transfer(_recipient, _amount);
    }

    /**
     * @notice the following function is used to transfer tokens from one user to another
     * @param _sender the address of the user who is sending the tokens
     * @param _recipient the address of the user who is receiving the tokens
     * @param _amount the amount of tokens to transfer
     * @return a boolean value
     */
    function transferFrom(
        address _sender,
        address _recipient,
        uint256 _amount
    ) public virtual override returns (bool) {
        _minAccruedInterest(_sender);
        _minAccruedInterest(_recipient);
        if (_amount == type(uint256).max) {
            _amount = balanceOf(_sender);
        }
        if (balanceOf(_recipient) == 0) {
            s_usersInterestRate[_recipient] = s_usersInterestRate[_sender];
        }
        return super.transferFrom(_sender, _recipient, _amount);
    }

    /**
     * @notice the following function is used to calculate the accrued interest of a user
     * @param _user which is the address of the user to calculate the accrued interest
     * @return the accrued interest of the user
     */
    function _calculateAccruedInterestSinceLastUpdate(
        address _user
    ) internal view returns (uint256) {
        uint256 timePassed = block.timestamp - s_userLastUpdateTimestamp[_user];
        return (PRECISION_FACTOR + (timePassed * s_usersInterestRate[_user]));
    }

    /**
     * @dev the following function is used to mint the accrued interest of a user
     * @param _user which is the address of the user
     */
    function _minAccruedInterest(address _user) internal {
        uint256 previousBalance = super.balanceOf(_user);
        uint256 currentBalance = balanceOf(_user);
        uint256 interestAccrued = currentBalance - previousBalance;
        s_userLastUpdateTimestamp[_user] = block.timestamp;
        _mint(_user, interestAccrued);
    }

    /**
     * @dev the following function is used to get the interest rate of a user
     * @param _user which is the address of the user
     * @return the interest rate of the user
     */
    function getUserInterestRate(
        address _user
    ) external view returns (uint256) {
        return s_usersInterestRate[_user];
    }

    /**
     * @dev the following function is used to get the interest rate of the smart contract
     * @return the interest rate of the smart contract
     */
    function getInterestRate() external view returns (uint256) {
        return s_interestRate;
    }
}
