// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {Test, console} from "forge-std/Test.sol";
import {FundMe} from "../src/FundMe.sol";
import {DeployFundMe} from "../script/DeployFundMe.s.sol";

contract FundMeTest is Test {
    FundMe fundMe;
    uint constant SEND_VALUE = 1 ether;
    uint constant STARTING_BALANCE = 100 ether;
    address USER = makeAddr("user");
    address owner;

    function setUp() external {
        DeployFundMe deployFundMe = new DeployFundMe();
        fundMe = deployFundMe.run();
        vm.deal(USER, STARTING_BALANCE);
        owner = fundMe.getOwner();
    }

    function testMinimumDollarIsFive() public {
        assertEq(fundMe.MINIMUM_USD(), 5e18);
    }

    function testOwnerIsMsgSender() public {
        assertEq(owner, msg.sender);
    }

    function testGetVersion() public {
        assertEq(fundMe.getVersion(), 4);
    }

    function testFundFailsWithoutEnoughETH() public {
        vm.expectRevert();
        fundMe.fund();
    }

    function testFundUpdates() public {
        vm.prank(USER);
        fundMe.fund{value: SEND_VALUE}();
        uint amountFunded = fundMe.getAddressToAmountFunded(USER);
        assertEq(amountFunded, SEND_VALUE);
    }

    function testAddsFunderToArrayOfFunders() public {
        vm.prank(USER);
        fundMe.fund{value: SEND_VALUE}();
        address funder = fundMe.getFunder(0);
        assertEq(funder, USER);
    }

    modifier funded() {
        vm.prank(USER);
        fundMe.fund{value: SEND_VALUE}();
        _;
    }

    function testOnlyOwnerCanWithdraw() public funded {
        vm.prank(USER);
        vm.expectRevert();
        fundMe.withdraw();
    }

    function testWithdrawWithASingleFunder() public {
        //Arrange
        uint startingOwnerBalance = owner.balance;
        uint startingFundMeBalance = address(fundMe).balance;
        //Act
        vm.prank(owner);
        fundMe.withdraw();
        //Assert
        assertEq(address(fundMe).balance, 0);
        assertEq(owner.balance, startingOwnerBalance + startingFundMeBalance);
    }

    function testWithdrawFromMultipleFunders() public funded {
        uint160 numberOfFunders = 10;
        uint160 startingFundedIndex = 1;
        for (uint160 i = startingFundedIndex; i < numberOfFunders; i++) {
            hoax(address(i), SEND_VALUE);
            fundMe.fund{value: SEND_VALUE}();
        }
        uint startingOwnerBalance = owner.balance;
        uint startingFundMeBalance = address(fundMe).balance;

        vm.prank(owner);
        fundMe.withdraw();

        assertEq(address(fundMe).balance, 0);
        assertEq(owner.balance, startingOwnerBalance + startingFundMeBalance);
    }
}
