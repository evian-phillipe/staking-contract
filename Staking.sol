// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

contract Staking {
    mapping(address => uint256) public balance;

    function stake() public payable {
        require(msg.value > 0, "Must stake ETH");
        balance[msg.sender] += msg.value;
    }

    function withdraw(uint256 amount) public {
        require(balance[msg.sender] >= amount, "Not enough balance");

        balance[msg.sender] -= amount;
        payable(msg.sender).transfer(amount);
    }
}
