
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/**
 * @title CryptoHarvest
 * @dev A decentralized token staking platform where users can stake tokens and earn rewards
 */
contract Project {
    // State variables
    address public owner;
    uint256 public rewardRate; // Reward rate per second (in wei per token staked)
    uint256 public totalStaked;
    
    struct Stake {
        uint256 amount;
        uint256 startTime;
        uint256 lastClaimTime;
    }
    
    mapping(address => Stake) public stakes;
    mapping(address => uint256) public earnedRewards;
    
    // Events
    event Staked(address indexed user, uint256 amount, uint256 timestamp);
    event Harvested(address indexed user, uint256 reward, uint256 timestamp);
    event Unstaked(address indexed user, uint256 amount, uint256 reward, uint256 timestamp);
    event RewardRateUpdated(uint256 newRate, uint256 timestamp);
    
    // Modifiers
    modifier onlyOwner() {
        require(msg.sender == owner, "Only owner can call this function");
        _;
    }
    
    constructor(uint256 _rewardRate) {
        owner = msg.sender;
        rewardRate = _rewardRate;
    }
    
    /**
     * @dev Stake ETH to start earning rewards
     * Core Function 1: Staking mechanism
     */
    function stake() external payable {
        require(msg.value > 0, "Cannot stake 0 ETH");
        
        // If user already has a stake, harvest pending rewards first
        if (stakes[msg.sender].amount > 0) {
            _harvestRewards(msg.sender);
        }
        
        // Update stake information
        stakes[msg.sender].amount += msg.value;
        stakes[msg.sender].startTime = block.timestamp;
        stakes[msg.sender].lastClaimTime = block.timestamp;
        
        totalStaked += msg.value;
        
        emit Staked(msg.sender, msg.value, block.timestamp);
    }
    
    /**
     * @dev Harvest accumulated rewards without unstaking
     * Core Function 2: Reward harvesting mechanism
     */
    function harvest() external {
        require(stakes[msg.sender].amount > 0, "No active stake");
        
        uint256 reward = _harvestRewards(msg.sender);
        require(reward > 0, "No rewards to harvest");
        
        emit Harvested(msg.sender, reward, block.timestamp);
    }
    
    /**
     * @dev Unstake tokens and claim all rewards
     * Core Function 3: Unstaking mechanism
     */
    function unstake(uint256 amount) external {
        require(stakes[msg.sender].amount >= amount, "Insufficient staked amount");
        require(amount > 0, "Cannot unstake 0");
        
        // Harvest any pending rewards
        uint256 reward = _harvestRewards(msg.sender);
        
        // Update stake
        stakes[msg.sender].amount -= amount;
        totalStaked -= amount;
        
        // If fully unstaking, reset the stake
        if (stakes[msg.sender].amount == 0) {
            delete stakes[msg.sender];
        }
        
        // Transfer staked amount back to user
        (bool success, ) = msg.sender.call{value: amount}("");
        require(success, "Transfer failed");
        
        emit Unstaked(msg.sender, amount, reward, block.timestamp);
    }
    
    /**
     * @dev Internal function to calculate and transfer rewards
     */
    function _harvestRewards(address user) internal returns (uint256) {
        uint256 reward = calculateRewards(user);
        
        if (reward > 0) {
            stakes[user].lastClaimTime = block.timestamp;
            earnedRewards[user] += reward;
            
            // Transfer reward to user
            (bool success, ) = user.call{value: reward}("");
            require(success, "Reward transfer failed");
        }
        
        return reward;
    }
    
    /**
     * @dev Calculate pending rewards for a user
     */
    function calculateRewards(address user) public view returns (uint256) {
        Stake memory userStake = stakes[user];
        
        if (userStake.amount == 0) {
            return 0;
        }
        
        uint256 stakingDuration = block.timestamp - userStake.lastClaimTime;
        uint256 reward = (userStake.amount * rewardRate * stakingDuration) / 1e18;
        
        return reward;
    }
    
    /**
     * @dev Get stake information for a user
     */
    function getStakeInfo(address user) external view returns (
        uint256 stakedAmount,
        uint256 startTime,
        uint256 pendingRewards,
        uint256 totalEarned
    ) {
        Stake memory userStake = stakes[user];
        return (
            userStake.amount,
            userStake.startTime,
            calculateRewards(user),
            earnedRewards[user]
        );
    }
    
    /**
     * @dev Update reward rate (only owner)
     */
    function updateRewardRate(uint256 newRate) external onlyOwner {
        rewardRate = newRate;
        emit RewardRateUpdated(newRate, block.timestamp);
    }
    
    /**
     * @dev Fund the contract with ETH for rewards (only owner)
     */
    function fundRewards() external payable onlyOwner {
        require(msg.value > 0, "Must send ETH to fund rewards");
    }
    
    /**
     * @dev Get contract balance
     */
    function getContractBalance() external view returns (uint256) {
        return address(this).balance;
    }
    
    /**
     * @dev Emergency withdraw (only owner, for security purposes)
     */
    function emergencyWithdraw() external onlyOwner {
        uint256 balance = address(this).balance;
        (bool success, ) = owner.call{value: balance}("");
        require(success, "Emergency withdraw failed");
    }
    
    // Fallback function to receive ETH
    receive() external payable {}
}
