// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.9.0;

import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {Pausable} from "@openzeppelin/contracts/utils/Pausable.sol";
import {ReentrancyGuard} from "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import {Nonces} from "@openzeppelin/contracts/utils/Nonces.sol";
import {ECDSA} from "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import {EnumerableSet} from "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";

contract GasTank is Ownable, Pausable, ReentrancyGuard, Nonces {
    using EnumerableSet for EnumerableSet.AddressSet;

    error ZeroAmount();
    error NotAuthorized();
    error InsufficientBalance();
    error TransferFailed();
    error TransferNotAllowed();
    error ContractsNotAllowed();
    error ZeroAddressNotAllowed();

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

    modifier onlyEOA() {
        address sender = msg.sender;
        uint256 size;
        assembly {
            size := extcodesize(sender)
        }
        require(size == 0, "Contracts not allowed");
        _;
    }

    modifier noZeroAddress(address addr) {
        if (addr == address(0)) {
            revert ZeroAddressNotAllowed();
        }
        _;
    }

    modifier onlyOwnerOrFacility() {
        if (msg.sender != owner() && !facilities.contains(msg.sender)) {
            revert NotAuthorized();
        }
        _;
    }

    modifier onlyOwnerOrPipe() {
        if (msg.sender != owner() && !pipes.contains(msg.sender)) {
            revert NotAuthorized();
        }
        _;
    }

    modifier onlyOwnerPipeFacility() {
        if (msg.sender != owner() && !facilities.contains(msg.sender) && !pipes.contains(msg.sender)) {
            revert NotAuthorized();
        }
        _;
    }

    constructor(address owner) Ownable(owner) {}

    receive() external payable {
        revert TransferNotAllowed();
    }

    fallback() external payable {
        revert TransferNotAllowed();
    }

    function deposit(uint256 nonce) external payable onlyEOA nonReentrant whenNotPaused {
        if (msg.value == 0) revert ZeroAmount();

        _useCheckedNonce(msg.sender, nonce);

        unchecked {
            tank[msg.sender] += msg.value;
        }

        emit Deposit(msg.sender, msg.value);
    }

    function withdraw(uint256 amount, uint256 nonce) external onlyEOA nonReentrant whenNotPaused {
        if (amount == 0) revert ZeroAmount();
        if (tank[msg.sender] < amount) revert InsufficientBalance();

        _useCheckedNonce(msg.sender, nonce);

        unchecked {
            tank[msg.sender] -= amount;
        }
        (bool sent,) = msg.sender.call{value: amount}("");
        if (!sent) revert TransferFailed();

        emit Withdraw(msg.sender, amount);
    }

    function addFacility(address addr) external onlyOwner nonReentrant whenNotPaused noZeroAddress(addr) {
        facilities.add(addr);
        emit FacilityAdded(addr);
    }

    function removeFacility(address addr) external onlyOwner nonReentrant whenNotPaused {
        facilities.remove(addr);
        emit FacilityRemoved(addr);
    }

    function addPipe(address addr) external onlyOwnerOrFacility nonReentrant whenNotPaused noZeroAddress(addr) {
        pipes.add(addr);
        emit PipedAdded(addr);
    }

    function removePipe(address addr) external onlyOwnerOrFacility nonReentrant whenNotPaused {
        pipes.remove(addr);
        emit PipedRemoved(addr);
    }

    function burn(address from, uint256 amount, uint256 nonce) external onlyOwnerOrPipe whenNotPaused nonReentrant {
        if (from == address(0)) revert ZeroAddressNotAllowed();
        if (amount == 0) revert ZeroAmount();
        if (tank[from] < amount) revert InsufficientBalance();

        _useCheckedNonce(from, nonce);

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

    function getAddressNonce(address addr) external view onlyOwnerPipeFacility noZeroAddress(addr) returns (uint256) {
        return nonces(addr);
    }

    function getNonce() external view returns (uint256) {
        return nonces(msg.sender);
    }

    function getAddressGas(address addr) external view onlyOwnerOrFacility noZeroAddress(addr) returns (uint256) {
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
