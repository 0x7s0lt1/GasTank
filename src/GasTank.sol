// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.9.0;

import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {Pausable} from "@openzeppelin/contracts/utils/Pausable.sol";
import {ReentrancyGuard} from "@openzeppelin/contracts/utils/ReentrancyGuard.sol";

contract GasTank is Ownable, Pausable, ReentrancyGuard {
    error ZeroAmount();
    error NotAuthorized();
    error InsufficientBalance();
    error TransferFailed();

    address private immutable facility;
    mapping(address => uint256) private tank;
    mapping(address => bool) private pipes;

    event Deposit(address cell, uint256 amount);
    event Withdraw(address cell, uint256 amount);
    event Piped(address addr, bool status);
    event Burn(address from, uint256 amount, address executor);

    modifier onlyOwnerOrFacility() {
        if (msg.sender != owner() && msg.sender != facility) {
            revert NotAuthorized();
        }
        _;
    }

    modifier onlyOwnerOrPipe() {
        if (!pipes[msg.sender] && msg.sender != owner()) {
            revert NotAuthorized();
        }
        _;
    }

    constructor(address _owner, address _facility) Ownable(_owner) {
        facility = _facility;
    }

    receive() external payable {
        revert("Use deposit() instead");
    }

    fallback() external payable {
        revert("Use deposit() instead");
    }

    function deposit() external payable nonReentrant whenNotPaused {
        if (msg.value == 0) revert ZeroAmount();
        unchecked {
            tank[msg.sender] += msg.value;
        }

        emit Deposit(msg.sender, msg.value);
    }

    function withdraw(uint256 amount) external nonReentrant whenNotPaused {
        if (amount == 0) revert ZeroAmount();
        if (tank[msg.sender] < amount) revert InsufficientBalance();

        unchecked {
            tank[msg.sender] -= amount;
        }
        (bool sent,) = msg.sender.call{value: amount}("");
        if (!sent) revert TransferFailed();

        emit Withdraw(msg.sender, amount);
    }

    function setPipe(address addr, bool status) external onlyOwnerOrFacility nonReentrant whenNotPaused {
        pipes[addr] = status;
        emit Piped(addr, status);
    }

    function burn(address from, uint256 amount) external onlyOwnerOrPipe whenNotPaused nonReentrant {
        _validateBurn(from, amount);
        _executeBurn(from, amount);
    }

    function _validateBurn(address from, uint256 amount) private view {
        if (from == address(0)) revert NotAuthorized();
        if (amount == 0) revert ZeroAmount();
        if (tank[from] < amount) revert InsufficientBalance();
    }

    function _executeBurn(address from, uint256 amount) private {
        if (tank[from] < amount) revert InsufficientBalance();
        unchecked {
            tank[from] -= amount;
        }

        (bool sent,) = owner().call{value: amount}("");
        if (!sent) revert TransferFailed();

        emit Burn(from, amount, msg.sender);
    }

    function getFacility() external view onlyOwner returns (address) {
        return facility;
    }

    function getAddressGas(address addr) external view onlyOwnerOrFacility returns (uint256) {
        return tank[addr];
    }

    function getGas() external view returns (uint256) {
        return tank[msg.sender];
    }

    function pause() external onlyOwner nonReentrant {
        _pause();
    }

    function unpause() external onlyOwner nonReentrant {
        _unpause();
    }
}
