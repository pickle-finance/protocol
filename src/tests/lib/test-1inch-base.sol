pragma solidity ^0.6.7;

import "../../lib/safe-math.sol";
import "../../lib/erc20.sol";

import "./hevm.sol";
import "./user.sol";
import "./test-approx.sol";

import "../../interfaces/strategy.sol";
import "../../interfaces/1inch-farm-lp.sol";
import "../../interfaces/1inch-farm.sol";

contract DSTest1inchBase is DSTestApprox {
    using SafeERC20 for IERC20;
    using SafeMath for uint256;

    IMooniswap mooniswap;
    
    uint256 startTime = block.timestamp;

    Hevm hevm = Hevm(0x7109709ECfa91a80626fF3989D68f67F5b1DD12D);

    function _setUp(address _pool) internal {
        mooniswap = IMooniswap(_pool);
    }

    function _getTokenWithEth(address token, uint256 _amount) internal {

        uint256 inAmount = mooniswap.getReturn(IERC20(token), IERC20(address(0)), _amount); 

        mooniswap.swap(IERC20(address(0)), IERC20(token), inAmount, 0, address(0));
    }
}
