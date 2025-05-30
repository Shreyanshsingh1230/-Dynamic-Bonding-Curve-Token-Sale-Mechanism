// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
 * @title DynamicBondingCurveTokenSale
 * @dev ERC20 token sale with a dynamic bonding curve pricing mechanism
 */
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract Project is ERC20, Ownable {
    uint256 public constant INITIAL_SUPPLY = 1000 * 10**18;

    // Parameters for bonding curve: price = basePrice + slope * supply
    uint256 public basePrice; // in wei per token
    uint256 public slope;     // price increase per token minted (in wei)

    event TokensPurchased(address indexed buyer, uint256 amount, uint256 totalCost);
    event TokensSold(address indexed seller, uint256 amount, uint256 totalReturn);

    constructor(uint256 _basePrice, uint256 _slope) ERC20("BondingCurveToken", "BCT") Ownable(msg.sender) {
        basePrice = _basePrice;
        slope = _slope;

        // Mint initial supply to owner (could be zero if desired)
        _mint(msg.sender, INITIAL_SUPPLY);
    }

    /**
     * @dev Calculate price for next token based on current total supply
     * @param supply Total tokens currently minted (in wei)
     */
    function getPrice(uint256 supply) public view returns (uint256) {
        return basePrice + (slope * supply) / 1e18;
    }

    /**
     * @dev Calculate cost to buy amount of tokens based on bonding curve
     * Uses a loop to sum price for each token (inefficient for large amounts, for demo only)
     */
    function calculateCost(uint256 amount) public view returns (uint256) {
        uint256 totalSupply = totalSupply();
        uint256 cost = 0;
        for (uint256 i = 0; i < amount; i++) {
            uint256 price = getPrice(totalSupply + i * 1e18);
            cost += price;
        }
        return cost;
    }

    /**
     * @dev Buy tokens by sending ETH, price depends on bonding curve
     * @param amount Amount of tokens to buy (in wei)
     */
    function buyTokens(uint256 amount) external payable {
        require(amount > 0, "Amount must be > 0");
        uint256 cost = calculateCost(amount);
        require(msg.value >= cost, "Insufficient ETH sent");

        _mint(msg.sender, amount);

        // Refund excess ETH
        if (msg.value > cost) {
            payable(msg.sender).transfer(msg.value - cost);
        }

        emit TokensPurchased(msg.sender, amount, cost);
    }

    /**
     * @dev Sell tokens back to contract, return ETH based on bonding curve (approximate)
     * @param amount Amount of tokens to sell (in wei)
     */
    function sellTokens(uint256 amount) external {
        require(amount > 0, "Amount must be > 0");
        require(balanceOf(msg.sender) >= amount, "Not enough tokens");

        uint256 totalSupply = totalSupply();
        uint256 refund = 0;
        for (uint256 i = 0; i < amount; i++) {
            uint256 price = getPrice(totalSupply - i * 1e18);
            refund += price;
        }

        _burn(msg.sender, amount);

        payable(msg.sender).transfer(refund);

        emit TokensSold(msg.sender, amount, refund);
    }

    // To receive ETH
    receive() external payable {}
}
