// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

contract FriendTech is ERC20, Ownable {
    using SafeMath for uint256;

    address public owner;
    uint256 public sharePrice;
    uint256 public lockUpPeriod;

    mapping(address => uint256) private totalShares;
    mapping(address => uint256) private lockedShares;
    mapping(address => uint256) private lastDividendClaim;

    // Dividends
    mapping(address => uint256) private dividendBalance;

    // Role-based access control
    modifier onlyOwner() {
        require(msg.sender == owner, "Only the owner can call this function");
        _;
    }

    constructor() ERC20("FriendTech", "FTK") {
        owner = msg.sender;
        lockUpPeriod = 1 days; // 1 day lock-up period
    }

    function setSharePrice(uint256 price) external onlyOwner {
        require(price > 0, "Price must be greater than zero");
        sharePrice = price;
    }

    function buyShares(address seller, uint256 amount) external payable {
        require(amount > 0, "Amount must be greater than zero");
        require(totalShares[seller] >= amount, "Seller does not have enough shares");
        require(sharePrice.mul(amount) == msg.value, "Incorrect payment amount");

        totalShares[seller] = totalShares[seller].sub(amount);
        totalShares[msg.sender] = totalShares[msg.sender].add(amount);
        
        // Calculate the amount of tokens to mint based on the share price
        uint256 tokensToMint = amount * 10**decimals();
        _mint(msg.sender, tokensToMint);
    }

    function sellShares(address buyer, uint256 amount) external {
        require(amount > 0, "Amount must be greater than zero");
        require(totalShares[msg.sender] >= amount, "Insufficient shares");

        // Applying lock-up period
        require(block.timestamp > lastDividendClaim[msg.sender] + lockUpPeriod, "Shares are still locked");

        totalShares[msg.sender] = totalShares[msg.sender].sub(amount);
        totalShares[buyer] = totalShares[buyer].add(amount);

        // Calculate the amount of tokens to burn based on the share price
        uint256 tokensToBurn = amount * 10**decimals();
        _burn(msg.sender, tokensToBurn);

        // Distribute dividends to the seller
        uint256 dividend = tokensToBurn * 2; // Example dividend calculation
        dividendBalance[msg.sender] = dividendBalance[msg.sender].add(dividend);
    }

    function claimDividend() external {
        uint256 dividend = dividendBalance[msg.sender];
        require(dividend > 0, "No dividend to claim");

        dividendBalance[msg.sender] = 0;
        lastDividendClaim[msg.sender] = block.timestamp;

        // Distribute dividends to the shareholder
        _mint(msg.sender, dividend);
    }

    // Voting
    struct Vote {
        uint256 votes;
        bool voted;
    }

    mapping(address => Vote) public votes;

    function vote(uint256 option) external {
        require(totalShares[msg.sender] > 0, "Must own shares to vote");
        require(!votes[msg.sender].voted, "Already voted");

        // Perform the voting logic

        votes[msg.sender].votes = option;
        votes[msg.sender].voted = true;
    }

    // Governance Token
    contract GovernanceToken is ERC20 {
        constructor() ERC20("GovernanceToken", "GOV") {
        }
        // Add any additional governance token functions here
    }
}