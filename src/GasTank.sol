// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.9.0;

import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {Pausable} from "@openzeppelin/contracts/utils/Pausable.sol";
import {ReentrancyGuard} from "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import {EnumerableSet} from "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";

contract GasTank is Ownable, Pausable, ReentrancyGuard {
    using EnumerableSet for EnumerableSet.AddressSet;

    error ZeroAmount();
    error NotAuthorized();
    error InsufficientBalance();
    error TransferFailed();
    error TransferNotAllowed();

    event Deposit(address user, uint256 amount);
    event Withdraw(address user, uint256 amount);
    event Burn(address from, uint256 amount, address executor);
    event FacilityAdded(address addr);
    event FacilityRemoved(address addr);
    event PipedAdded(address addr);
    event PipedRemoved(address addr);

    mapping(address => uint256) private tank;

    EnumerableSet.AddressSet private facilities;
    EnumerableSet.AddressSet private pipes;

    modifier onlyOwnerOrFacility() {
        if (msg.sender != owner() && !facilities.contains(msg.sender)) {
            revert NotAuthorized();
        }
        _;
    }

    modifier onlyOwnerOrPipe() {
        if (!pipes.contains(msg.sender) && msg.sender != owner()) {
            revert NotAuthorized();
        }
        _;
    }

    constructor(address _owner) Ownable(_owner) {}

    receive() external payable {
        revert TransferNotAllowed();
    }

    fallback() external payable {
        revert TransferNotAllowed();
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

    function addFacility(address addr) external onlyOwner nonReentrant whenNotPaused {
        facilities.add(addr);
        emit FacilityAdded(addr);
    }

    function removeFacility(address addr) external onlyOwner nonReentrant whenNotPaused {
        facilities.remove(addr);
        emit FacilityAdded(addr);
    }

    function addPipe(address addr) external onlyOwnerOrFacility nonReentrant whenNotPaused {
        pipes.add(addr);
        emit PipedAdded(addr);
    }

    function removePipe(address addr) external onlyOwnerOrFacility nonReentrant whenNotPaused {
        pipes.remove(addr);
        emit PipedRemoved(addr);
    }

    function burn(address from, uint256 amount) external onlyOwnerOrPipe whenNotPaused nonReentrant {
        if (from == address(0)) revert NotAuthorized();
        if (amount == 0) revert ZeroAmount();
        if (tank[from] < amount) revert InsufficientBalance();

        unchecked {
            tank[from] -= amount;
        }

        (bool sent,) = owner().call{value: amount}("");
        if (!sent) revert TransferFailed();

        emit Burn(from, amount, msg.sender);
    }

    function getFacility() external view onlyOwner returns (address[] memory) {
        return facilities.values();
    }

    function getPipes() external view onlyOwnerOrFacility returns (address[] memory) {
        return pipes.values();
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
