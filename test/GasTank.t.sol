// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "../src/GasTank.sol";
import {Test, console} from "forge-std/Test.sol";

contract SignalBotFactoryTest is Test {
    GasTank public gasTank;

    function setUp() public {
        vm.startPrank(msg.sender);

        gasTank = new GasTank(msg.sender);

        vm.stopPrank();
    }

    function test_depositGas() public {

        uint256 initialBalance = 1100 ether;
        uint256 fillValue = 10 ether;

        address sender = address(0x123);

        vm.startPrank(sender);
        vm.deal(sender, initialBalance);

        assertEq(gasTank.getGas(), 0);

        gasTank.deposit{value: fillValue}();

        assertEq(gasTank.getGas(), fillValue);
        assertEq(sender.balance, (initialBalance - fillValue));

        vm.stopPrank();
    }

    function test_withdrawGas() public {
        uint256 initialBalance = 1100 ether;
        uint256 fillValue = 10 ether;
        address sender = address(0x123);

        vm.startPrank(sender);
        vm.deal(sender, initialBalance);

        assertEq(gasTank.getGas(), 0);

        gasTank.deposit{value: fillValue}();

        assertEq(gasTank.getGas(), fillValue);
        assertEq(sender.balance, (initialBalance - fillValue));

        gasTank.withdraw(fillValue);

        assertEq(gasTank.getGas(), 0);
        assertEq(sender.balance, initialBalance);

        vm.stopPrank();
    }

    function test_burnGas() public {
        uint256 initialBalance = 1100 ether;
        uint256 fillValue = 1000 wei;
        uint256 pipeValue = 500 wei;
        uint256 difference = fillValue - pipeValue;
        address sender = address(0x123);

        vm.startPrank(sender);
        vm.deal(sender, initialBalance);

        assertEq(gasTank.getGas(), 0);

        gasTank.deposit{value: fillValue}();

        assertEq(gasTank.getGas(), fillValue);
        assertEq(sender.balance, (initialBalance - fillValue));

        vm.stopPrank();
        vm.startPrank(msg.sender);

        uint256 msgSenderBalanceBefore = msg.sender.balance;

        gasTank.burn(sender, pipeValue, address(1));
        assertEq(gasTank.getAddressGas(sender), difference);
        assertEq(msg.sender.balance, (msgSenderBalanceBefore + pipeValue));

        vm.stopPrank();
    }
}
