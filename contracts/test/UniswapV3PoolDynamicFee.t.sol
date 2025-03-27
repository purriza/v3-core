// SPDX-License-Identifier: BUSL-1.1
pragma solidity =0.7.6;
pragma abicoder v2;

import "./utils/UniswapV3PoolDynamicFeeFixture.sol";

contract UniswapV3PoolDynamicFeeTest is UniswapV3PoolDynamicFeeFixture {
    function setUp() public override {
        super.setUp();
    }

    function testDynamicFeeTWAP() public {
        // Perform a series of swaps to generate fee history
        vm.startPrank(alice);
        
        // Approve tokens for swapping
        token0.approve(address(uniswapV3Pool), type(uint256).max);
        token1.approve(address(uniswapV3Pool), type(uint256).max);

        // Simulate multiple swaps over time
        for (uint i = 0; i < 5; i++) {
            // Swap token0 for token1
            uniswapV3Pool.swap(
                address(this),
                true, 
                int256(10_000 * 10**18),
                TickMath.MIN_SQRT_RATIO + 1,
                abi.encode(0)
            );

            // Simulate time passing
            vm.warp(block.timestamp + 120); // 2 minutes between swaps
        }

        vm.stopPrank();

        // Check the dynamic fee calculation
        uint24 currentDynamicFee = uniswapV3Pool.currentDynamicFee();
        
        // Dynamic fee should be calculated
        assertGt(uint256(currentDynamicFee), 0, "Dynamic fee should be calculated");
        
        // Checking if the fee is within an expected range
        assertLt(uint256(currentDynamicFee), 100000, "Dynamic fee should be within reasonable bounds");

        // Log the calculated dynamic fee for inspection
        emit log_named_uint("Calculated Dynamic Fee:", uint256(currentDynamicFee));
    }
}
