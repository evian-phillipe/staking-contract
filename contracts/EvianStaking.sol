// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "https://raw.githubusercontent.com/OpenZeppelin/openzeppelin-contracts/master/contracts/token/ERC20/IERC20.sol";
import "https://raw.githubusercontent.com/OpenZeppelin/openzeppelin-contracts/master/contracts/access/Ownable.sol";

contract EvianStaking is Ownable {
    IERC20 public stakingToken;
    uint256 public rewardRatePerSecond;

    mapping(address => uint256) public stakedBalance;
    mapping(address => uint256) public rewards;
    mapping(address => uint256) public lastUpdated;

    constructor(address _stakingToken, uint256 _rewardRatePerSecond) Ownable(msg.sender) {
        stakingToken = IERC20(_stakingToken);
        rewardRatePerSecond = _rewardRatePerSecond;
    }

    function _updateReward(address account) internal {
        if (account != address(0)) {
            uint256 earnedAmount = earned(account);
            rewards[account] = earnedAmount;
            lastUpdated[account] = block.timestamp;
        }
    }

    function stake(uint256 amount) external {
        require(amount > 0, "Amount must be greater than 0");

        _updateReward(msg.sender);

        bool success = stakingToken.transferFrom(msg.sender, address(this), amount);
        require(success, "Token transfer failed");

        stakedBalance[msg.sender] += amount;
    }

    function unstake(uint256 amount) external {
        require(amount > 0, "Amount must be greater than 0");
        require(stakedBalance[msg.sender] >= amount, "Insufficient staked balance");

        _updateReward(msg.sender);

        stakedBalance[msg.sender] -= amount;

        bool success = stakingToken.transfer(msg.sender, amount);
        require(success, "Token transfer failed");
    }

    function claimReward() external {
        _updateReward(msg.sender);

        uint256 reward = rewards[msg.sender];
        require(reward > 0, "No rewards available");
        require(stakingToken.balanceOf(address(this)) >= stakedBalance[msg.sender] + reward, "Insufficient reward pool");

        rewards[msg.sender] = 0;

        bool success = stakingToken.transfer(msg.sender, reward);
        require(success, "Reward transfer failed");
    }

    function earned(address account) public view returns (uint256) {
        uint256 timeElapsed = block.timestamp - lastUpdated[account];
        uint256 pendingReward = (stakedBalance[account] * rewardRatePerSecond * timeElapsed) / 1e18;
        return rewards[account] + pendingReward;
    }

    function fundRewards(uint256 amount) external onlyOwner {
        require(amount > 0, "Amount must be greater than 0");

        bool success = stakingToken.transferFrom(msg.sender, address(this), amount);
        require(success, "Funding transfer failed");
    }

    function setRewardRate(uint256 _newRate) external onlyOwner {
        rewardRatePerSecond = _newRate;
    }
}
