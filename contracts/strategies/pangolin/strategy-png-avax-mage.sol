pragma solidity ^0.6.7;

import "../strategy-png-minichef-farm-base.sol";

contract StrategyPngAvaxMage is StrategyPngMiniChefFarmBase {
    uint256 public _poolId = 68;

    // Token addresses
    address public png_avax_mage_lp = 0x902c65C90327285BB1d8BdC07B59Cd199410A71b;
    address public mage = 0x921f99719Eb6C01b4B8f0BA7973A7C24891e740A;

    constructor(
        address _governance,
        address _strategist,
        address _controller,
        address _timelock
    )
        public
        StrategyPngMiniChefFarmBase(
            _poolId,
            png_avax_mage_lp,
            _governance,
            _strategist,
            _controller,
            _timelock
        )
    {}

    function _takeFeeMageToSnob(uint256 _keep) internal {
        address[] memory path = new address[](3);
        path[0] = mage;
        path[1] = wavax;
        path[2] = snob;
        IERC20(mage).safeApprove(pangolinRouter, 0);
        IERC20(mage).safeApprove(pangolinRouter, _keep);
        _swapPangolinWithPath(path, _keep);
        uint256 _snob = IERC20(snob).balanceOf(address(this));
        uint256 _share = _snob.mul(revenueShare).div(revenueShareMax);
        IERC20(snob).safeTransfer(
            feeDistributor,
            _share
        );
        IERC20(snob).safeTransfer(
            IController(controller).treasury(),
            _snob.sub(_share)
        );
    }

    // **** State Mutations ****

    function harvest() public override onlyBenevolent {
        // Collects Png tokens
        IMiniChef(miniChef).harvest(poolId, address(this));

        // Take AVAX Rewards    
        uint256 _avax = address(this).balance;              // get balance of native AVAX
        if (_avax > 0) {                                    // wrap AVAX into ERC20
            WAVAX(wavax).deposit{value: _avax}();
        }

        uint256 _png = IERC20(png).balanceOf(address(this));
        uint256 _mage = IERC20(mage).balanceOf(address(this));
        if (_png > 0) {
            // 10% is sent to treasury
            uint256 _keep = _png.mul(keep).div(keepMax);
            if (_keep > 0) {
                _takeFeePngToSnob(_keep);
            }

            _png = IERC20(png).balanceOf(address(this));  
        }

        if (_mage > 0) {
            uint256 _keep2 = _mage.mul(keep).div(keepMax);
            if (_keep2 > 0){
                _takeFeeMageToSnob(_keep2);
            }
            
            _mage = IERC20(mage).balanceOf(address(this));
        }

        uint256 _wavax = IERC20(wavax).balanceOf(address(this));
        // In the case of PNG Rewards, swap PNG for WAVAX and MAGE
        if(_png > 0){
            IERC20(png).safeApprove(pangolinRouter, 0);
            IERC20(png).safeApprove(pangolinRouter, _png);   
            _swapPangolin(png, wavax, _png);
            _wavax = IERC20(wavax).balanceOf(address(this));
            _swapPangolin(wavax, mage, _wavax.div(2));
        }

        // In the case of MAGE Rewards, swap MAGE for WAVAX
        if(_mage > 0){
            IERC20(mage).safeApprove(pangolinRouter, 0);
            IERC20(mage).safeApprove(pangolinRouter, _mage.div(2));   
            _swapPangolin(mage, wavax, _mage.div(2)); 
        }

        

        // Adds in liquidity for AVAX/MAGE
        _wavax = IERC20(wavax).balanceOf(address(this));
        _mage = IERC20(mage).balanceOf(address(this));

        if (_wavax > 0 && _mage > 0) {
            IERC20(wavax).safeApprove(pangolinRouter, 0);
            IERC20(wavax).safeApprove(pangolinRouter, _wavax);

            IERC20(mage).safeApprove(pangolinRouter, 0);
            IERC20(mage).safeApprove(pangolinRouter, _mage);

            IPangolinRouter(pangolinRouter).addLiquidity(
                wavax,
                mage,
                _wavax,
                _mage,
                0,
                0,
                address(this),
                now + 60
            );

            _wavax = IERC20(wavax).balanceOf(address(this));
            _mage = IERC20(mage).balanceOf(address(this));
            _png = IERC20(png).balanceOf(address(this));
            
            // Donates DUST
            if (_wavax > 0){
                IERC20(wavax).transfer(
                    IController(controller).treasury(),
                    _wavax
                );
            }
            if (_mage > 0){
                IERC20(mage).safeTransfer(
                    IController(controller).treasury(),
                    _mage
                );
            }
            if (_png > 0){
                IERC20(png).safeTransfer(
                    IController(controller).treasury(),
                    _png
                );
            }
        }
        _distributePerformanceFeesAndDeposit();
    }

    // **** Views ****

    function getName() external pure override returns (string memory) {
        return "StrategyPngAvaxMage";
    }
}