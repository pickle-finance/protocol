pragma solidity ^0.6.7;

import "../lib/safe-math.sol";
import "../lib/erc20.sol";

import "../interfaces/uniswapv2.sol";
import "../interfaces/curve.sol";
import "../interfaces/globe.sol";

// Converts Primitive tokens to Snow Globe Tokens
contract Instabrine {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    // Emergency withdrawal
    address owner;

    constructor() public {
        owner = msg.sender;
    }

    // Safety logic

    function emergencyERC20Retrieve(address token) public {
        require(msg.sender == owner, "!owner");
        uint256 _bal = IERC20(token).balanceOf(address(this));
        IERC20(token).safeTransfer(msg.sender, _bal);
    }

    // Internal functions

    function _curveLpToSnowGlobeAndRefund(address curveLp, address snowGlobe)
        internal
        returns (uint256)
    {
        uint256 curveLpAmount = IERC20(curveLp).balanceOf(address(this));

        IERC20(curveLp).safeApprove(snowGlobe, 0);
        IERC20(curveLp).safeApprove(snowGlobe, curveLpAmount);

        IGlobe(snowGlobe).depositAll();

        // Refund msg.sender
        uint256 _globe = IGlobe(snowGlobe).balanceOf(address(this));
        IGlobe(snowGlobe).transfer(msg.sender, _globe);

        return _globe;
    }

    // **** Primitive Tokens **** ///

    function primitiveToSnowGlobe(
        address underlying,
        uint256 amount,
        address globe
    ) public returns (uint256) {
        IERC20(underlying).safeTransferFrom(msg.sender, address(this), amount);

        IERC20(underlying).safeApprove(globe, 0);
        IERC20(underlying).safeApprove(globe, amount);

        IGlobe(globe).deposit(amount);
        
        uint256 _globe = IGlobe(globe).balanceOf(address(this));
        IERC20(globe).safeTransfer(msg.sender, _globe);

        return _globe;
    }

    function snowGlobeToPrimitive(
        address globe,
        uint256 amount,
        address underlying
    ) public returns (uint256) {
        IERC20(globe).safeTransferFrom(msg.sender, address(this), amount);

        IERC20(globe).safeApprove(globe, 0);
        IERC20(globe).safeApprove(globe, amount);

        IGlobe(globe).withdrawAll();
        uint256 _underlying = IERC20(underlying).balanceOf(address(this));
        IERC20(underlying).safeTransfer(msg.sender, _underlying);

        return _underlying;
    }

    // **** Curve **** //
    // Stupid non-standard API

    function primitiveToCurveSnowGlobe_2(
        address curve,
        address[2] memory underlying,
        uint256[2] memory underlyingAmounts,
        address curveLp,
        address snowGlobe
    ) public returns (uint256) {
        // Primitive -> Curve LP
        for (uint256 i = 0; i < underlying.length; i++) {
            IERC20(underlying[i]).safeTransferFrom(
                msg.sender,
                address(this),
                underlyingAmounts[i]
            );

            IERC20(underlying[i]).safeApprove(curve, 0);
            IERC20(underlying[i]).safeApprove(curve, underlyingAmounts[i]);
        }

        ICurveFi_2(curve).add_liquidity(underlyingAmounts, 0);

        // Curve LP -> SnowGlobe
        return _curveLpToSnowGlobeAndRefund(curveLp, snowGlobe);
    }

    function primitiveToCurveSnowGlobe_3(
        address curve,
        address[3] memory underlying,
        uint256[3] memory underlyingAmounts,
        address curveLp,
        address snowGlobe
    ) public returns (uint256) {
        // Primitive -> Curve LP
        for (uint256 i = 0; i < underlying.length; i++) {
            IERC20(underlying[i]).safeTransferFrom(
                msg.sender,
                address(this),
                underlyingAmounts[i]
            );

            IERC20(underlying[i]).safeApprove(curve, 0);
            IERC20(underlying[i]).safeApprove(curve, underlyingAmounts[i]);
        }

        ICurveFi_3(curve).add_liquidity(underlyingAmounts, 0);

        // Curve LP -> SnowGlobe
        return _curveLpToSnowGlobeAndRefund(curveLp, snowGlobe);
    }

    function primitiveToCurveSnowGlobe_4(
        address curve,
        address[4] memory underlying,
        uint256[4] memory underlyingAmounts,
        address curveLp,
        address snowGlobe
    ) public returns (uint256) {
        // Primitive -> Curve LP
        for (uint256 i = 0; i < underlying.length; i++) {
            IERC20(underlying[i]).safeTransferFrom(
                msg.sender,
                address(this),
                underlyingAmounts[i]
            );

            IERC20(underlying[i]).safeApprove(curve, 0);
            IERC20(underlying[i]).safeApprove(curve, underlyingAmounts[i]);
        }

        ICurveFi_4(curve).add_liquidity(underlyingAmounts, 0);

        // Curve LP -> SnowGlobe
        return _curveLpToSnowGlobeAndRefund(curveLp, snowGlobe);
    }

    // **** SnowGlobe **** //

    function curveSnowGlobeToPrimitive_1(
        address snowGlobe,
        uint256 amount,
        address curveLp,
        address curve,
        int128 index,
        address underlying
    ) public returns (uint256) {
        IERC20(snowGlobe).safeTransferFrom(msg.sender, address(this), amount);

        IERC20(snowGlobe).safeApprove(snowGlobe, 0);
        IERC20(snowGlobe).safeApprove(snowGlobe, amount);

        IGlobe(snowGlobe).withdraw(amount);

        uint256 curveLpAmount = IERC20(curveLp).balanceOf(address(this));

        IERC20(curveLp).safeApprove(curve, 0);
        IERC20(curveLp).safeApprove(curve, curveLpAmount);

        ICurveZap(curve).remove_liquidity_one_coin(
            curveLpAmount,
            index,
            uint256(0)
        );

        uint256 _underlying = IERC20(underlying).balanceOf(address(this));
        IERC20(underlying).safeTransfer(msg.sender, _underlying);
        return _underlying;
    }

    function curveSnowGlobeToPrimitive_2(
        address snowGlobe,
        uint256 amount,
        address curveLp,
        address curve,
        address[2] memory underlying
    ) public returns (uint256, uint256) {
        IERC20(snowGlobe).safeTransferFrom(msg.sender, address(this), amount);

        IERC20(snowGlobe).safeApprove(snowGlobe, 0);
        IERC20(snowGlobe).safeApprove(snowGlobe, amount);

        IGlobe(snowGlobe).withdraw(amount);

        uint256 curveLpAmount = IERC20(curveLp).balanceOf(address(this));

        IERC20(curveLp).safeApprove(curve, 0);
        IERC20(curveLp).safeApprove(curve, curveLpAmount);

        ICurveFi_2(curve).remove_liquidity(
            curveLpAmount,
            [uint256(0), uint256(0)]
        );

        uint256[] memory ret = new uint256[](2);
        for (uint256 i = 0; i < underlying.length; i++) {
            uint256 _underlying = IERC20(underlying[i]).balanceOf(
                address(this)
            );
            IERC20(underlying[i]).safeTransfer(msg.sender, _underlying);
            ret[i] = _underlying;
        }
        return (ret[0], ret[1]);
    }

    function curveSnowGlobeToPrimitive_3(
        address snowGlobe,
        uint256 amount,
        address curveLp,
        address curve,
        address[3] memory underlying
    )
        public
        returns (
            uint256,
            uint256,
            uint256
        )
    {
        IERC20(snowGlobe).safeTransferFrom(msg.sender, address(this), amount);

        IERC20(snowGlobe).safeApprove(snowGlobe, 0);
        IERC20(snowGlobe).safeApprove(snowGlobe, amount);

        IGlobe(snowGlobe).withdraw(amount);

        uint256 curveLpAmount = IERC20(curveLp).balanceOf(address(this));

        IERC20(curveLp).safeApprove(curve, 0);
        IERC20(curveLp).safeApprove(curve, curveLpAmount);

        ICurveFi_3(curve).remove_liquidity(
            curveLpAmount,
            [uint256(0), uint256(0), uint256(0)]
        );

        uint256[] memory ret = new uint256[](3);
        for (uint256 i = 0; i < underlying.length; i++) {
            uint256 _underlying = IERC20(underlying[i]).balanceOf(
                address(this)
            );
            IERC20(underlying[i]).safeTransfer(msg.sender, _underlying);
            ret[i] = _underlying;
        }
        return (ret[0], ret[1], ret[2]);
    }

    function curveSnowGlobeToPrimitive_4(
        address snowGlobe,
        uint256 amount,
        address curveLp,
        address curve,
        address[4] memory underlying
    )
        public
        returns (
            uint256,
            uint256,
            uint256,
            uint256
        )
    {
        IERC20(snowGlobe).safeTransferFrom(msg.sender, address(this), amount);

        IERC20(snowGlobe).safeApprove(snowGlobe, 0);
        IERC20(snowGlobe).safeApprove(snowGlobe, amount);

        IGlobe(snowGlobe).withdraw(amount);

        uint256 curveLpAmount = IERC20(curveLp).balanceOf(address(this));

        IERC20(curveLp).safeApprove(curve, 0);
        IERC20(curveLp).safeApprove(curve, curveLpAmount);

        ICurveFi_4(curve).remove_liquidity(
            curveLpAmount,
            [uint256(0), uint256(0), uint256(0), uint256(0)]
        );

        uint256[] memory ret = new uint256[](4);
        for (uint256 i = 0; i < underlying.length; i++) {
            uint256 _underlying = IERC20(underlying[i]).balanceOf(
                address(this)
            );
            IERC20(underlying[i]).safeTransfer(msg.sender, _underlying);
            ret[i] = _underlying;
        }
        return (ret[0], ret[1], ret[2], ret[3]);
    }
}
