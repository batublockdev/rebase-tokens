//SPDX-License-Identifier: MIT

pragma solidity ^0.8.24;

import {Test, console} from "forge-std/Test.sol";
import {RebaseToken} from "../src/RebaseToken.sol";
import {Vault} from "../src/Vault.sol";
import {IRebaseToken} from "../src/Interface/IRebaseToken.sol";

contract RebaseTokenTest is Test {
    //USERS
    address public owner = makeAddr("owner");
    address public user = makeAddr("user");
    address public user2 = makeAddr("user2");

    uint256 public userBalance = 100 ether;
    uint256 private constant PRECISION_FACTOR = 1e18;

    RebaseToken private rebaseToken;
    Vault private vault;

    function setUp() public {
        vm.startPrank(owner);
        rebaseToken = new RebaseToken();
        vault = new Vault(IRebaseToken(address(rebaseToken)));
        rebaseToken.grantMintAndBurnRole(address(vault));
        vm.stopPrank();
        vm.deal(owner, userBalance);
        vm.deal(user, userBalance);
        vm.deal(user2, userBalance);
    }

    ///////// Deposit test ////////
    function test_deposit() public {
        vm.startPrank(user);
        uint256 amount = 100;
        vault.deposit{value: amount}();
        vm.stopPrank();
        assertEq(rebaseToken.balanceOf(user), amount);
    }

    function test_deposit_Vault__AmountCanNotBeZero() public {
        vm.startPrank(user);
        uint256 amount = 0;
        vm.expectRevert(Vault.Vault__AmountCanNotBeZero.selector);
        vault.deposit{value: amount}();
        vm.stopPrank();
    }

    function test_redeem() public {
        vm.startPrank(user);
        uint256 amount = 100;
        vault.deposit{value: amount}();
        vault.redeem(amount);
        assertEq(rebaseToken.balanceOf(user), 0);
        assertEq(user.balance, userBalance);
    }

    function test_redeem_Vault__AmountCanNotBeZero() public {
        vm.startPrank(user);
        uint256 amount = 0;
        vault.deposit{value: 100}();
        vm.expectRevert(Vault.Vault__AmountCanNotBeZero.selector);
        vault.redeem(amount);
        vm.stopPrank();
    }

    function test_redeem_Vault__AmountExeedTheBalance() public {
        vm.startPrank(user);
        uint256 amount = 110;
        vault.deposit{value: 100}();
        vm.expectRevert(Vault.Vault__AmountExeedTheBalance.selector);
        vault.redeem(amount);
        vm.stopPrank();
    }

    function test_getRebaseToken() public {
        assertEq(vault.getRebaseToken(), address(rebaseToken));
    }

    //////////////// Test Grant Rol /////////////////////
    function test_grantMintAndBurnRole() public {
        vm.startPrank(owner);
        address newVault = makeAddr("newVault");
        rebaseToken.grantMintAndBurnRole(newVault);
        vm.stopPrank();
        assert(rebaseToken.hasRole(rebaseToken.MINT_AND_BURN_ROLE(), newVault));
    }

    /////////// transfer /////////////
    function test_transfer() public {
        vm.startPrank(user);
        uint256 amount = 100;
        vault.deposit{value: amount}();
        vm.stopPrank();
        vm.prank(owner);
        rebaseToken.setInterestRate(100);
        vm.prank(user2);
        vault.deposit{value: amount}();
        vm.startPrank(user);
        rebaseToken.transfer(user2, amount);

        assertEq(rebaseToken.balanceOf(user2), amount * 2);
        assertEq(rebaseToken.getUserInterestRate(user2), 100);
    }

    function test_transfer_v2() public {
        vm.startPrank(user);
        uint256 amount = 100;
        vault.deposit{value: amount}();
        vm.stopPrank();

        vm.startPrank(user);
        rebaseToken.transfer(user2, amount);

        assertEq(rebaseToken.balanceOf(user2), amount);
        assertEq(
            rebaseToken.getUserInterestRate(user2),
            rebaseToken.getUserInterestRate(user)
        );
    }

    function test_transferFrom() public {
        vm.startPrank(user);
        uint256 amount = 100;
        vault.deposit{value: amount}();
        vm.stopPrank();

        vm.startPrank(user);
        rebaseToken.approve(owner, amount);
        vm.stopPrank();

        vm.prank(owner);
        rebaseToken.transferFrom(user, user2, amount);

        assertEq(rebaseToken.balanceOf(user2), amount);
        assertEq(
            rebaseToken.getUserInterestRate(user2),
            rebaseToken.getUserInterestRate(user)
        );
    }

    /////////// interest rate /////////////
    function test_Interest_overtime() public {
        vm.startPrank(user);
        uint256 amount = 1 ether;
        uint256 time = block.timestamp;
        vault.deposit{value: amount}();
        vm.stopPrank();
        uint256 startedBalance = rebaseToken.balanceOf(user);
        console.log("startedBalance", startedBalance);

        vm.warp(block.timestamp + 1 hours);

        uint256 afterBalance = rebaseToken.balanceOf(user);
        console.log("afterBalance", afterBalance);
        assert(afterBalance > startedBalance);
        assert(afterBalance == rebaseToken.balanceOf(user));
    }

    function test_setInterestRate() public {
        vm.startPrank(owner);
        uint256 interestRate = 100;
        rebaseToken.setInterestRate(interestRate);
        vm.stopPrank();
        assertEq(rebaseToken.getInterestRate(), interestRate);
    }

    function test_setInterestRate_error() public {
        vm.startPrank(owner);
        uint256 interestRate = 1 ether;
        vm.expectRevert(
            abi.encodeWithSelector(
                RebaseToken.RebaseToken__InterestRateCannotIncrease.selector,
                interestRate,
                rebaseToken.getInterestRate()
            )
        );
        rebaseToken.setInterestRate(interestRate);
        vm.stopPrank();
    }
}
