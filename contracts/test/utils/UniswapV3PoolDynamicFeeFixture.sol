// SPDX-License-Identifier: MIT
pragma solidity =0.7.6;

import "contracts/UniswapV3Pool.sol";
import "contracts/UniswapV3Factory.sol";
import "contracts/UniswapV3PoolDeployer.sol";
import "contracts/interfaces/IUniswapV3Pool.sol";
import "contracts/libraries/TickMath.sol";

import "contracts/test/TestERC20.sol";

import "forge-std/Test.sol";
import { console } from "forge-std/console.sol";

contract UniswapV3PoolDynamicFeeFixture is Test {
    // Contract variables
    UniswapV3Pool public uniswapV3Pool;
    UniswapV3Factory public uniswapV3Factory;
    UniswapV3PoolDeployer public uniswapV3PoolDeployer;

    TestERC20 public token1; 
    TestERC20 public token2; 

    // Addresses
    address public poolDeployer = vm.addr(1);
    address public alice = vm.addr(2);
    address public bob = vm.addr(3);

    // Initialization variables
    uint24 fee = 3000; // 0.3% fee. It doesn't matter because its not used
    int24 tickSpacing;

    function setUp() public virtual {
        // Label and deal addresses
        vm.label(poolDeployer, "Pool Deployer");
        vm.label(alice, "Alice");
        vm.label(bob, "Bob");

        // Deal ETH
        vm.deal(poolDeployer, 5 ether);
        vm.deal(alice, 5 ether);
        vm.deal(bob, 5 ether);

        vm.startPrank(poolDeployer);

        // Deploy and deal TestERC20 tokens
        token1 = new TestERC20(500_000 * 1e18);
        token2 = new TestERC20(500_000 * 1e18);

        token0.mint(alice, 100_000 * 10**18);
        token0.mint(alice, 100_000 * 10**18);
        token1.mint(bob, 100_000 * 10**18);
        token1.mint(bob, 100_000 * 10**18);

        // Deploy UniswapV3Factory contract
        uniswapV3Factory = new UniswapV3Factory();

        // Deploy the UniswapV3Pool
        address poolAddress = uniswapV3Factory.createPool(
            address(token1), 
            address(token2), 
            fee
        );
        uniswapV3Pool = IUniswapV3Pool(poolAddress);

        // Get tick spacing
        tickSpacing = uniswapV3Pool.tickSpacing();

        // Initialize the pool
        (uint160 sqrtPriceX96, ) = calculateSqrtPriceX96AndTick(1, 1);
        uniswapV3Pool.initialize(sqrtPriceX96);

        // Approve tokens for adding liquidity
        token1.approve(address(this), type(uint256).max);
        token2.approve(address(this), type(uint256).max);

        // Add liquidity
        addLiquidity(
            -tickSpacing * 100,  // Lower tick
            tickSpacing * 100,   // Upper tick
            100 * 1e18,          // Amount of token0
            100 * 1e18           // Amount of token1
        );

        vm.stopPrank();
    }

    // Helper function to add liquidity
    function addLiquidity(
        int24 tickLower,
        int24 tickUpper,
        uint256 amount0Desired,
        uint256 amount1Desired
    ) internal returns (uint256 amount0, uint256 amount1, uint128 liquidity) {
        (amount0, amount1, liquidity) = uniswapV3Pool.mint(
            poolDeployer,
            tickLower,
            tickUpper,
            uint128((amount0Desired + amount1Desired) / 2),
            abi.encode(0)
        );
    }

    // Helper function to get the sqrtPriceX96
    function getSqrtPriceX96AndTick(
        uint256 token0Amount, 
        uint256 token1Amount
    ) internal pure returns (uint160 sqrtPriceX96, int24 tick) {
        // Calculate initial price based on the ratio of tokens (simplified)
        uint256 price = (token1Amount * 10**18) / token0Amount;
        
        // Convert price to sqrt(price)
        sqrtPriceX96 = uint160(sqrt(price) * (2**96));
        
        // Calculating the exact tick is complex and might require more precise logic
        tick = 0;
    }

    // Helper function for square roots
    function sqrt(uint256 x) internal pure returns (uint256 y) {
        uint256 z = (x + 1) / 2;
        y = x;
        while (z < y) {
            y = z;
            z = (x / z + z) / 2;
        }
    }
}
