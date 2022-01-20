pragma solidity ^0.6.7;

import "../strategy-png-minichef-farm-base.sol";

contract StrategyPngAvaxHtz is StrategyPngMiniChefFarmBase {
    uint256 public _poolId = 69;

    // Token addresses
    address public png_avax_htz_lp = 0x45430378272aed047cD33b688aDa004a06f435C0;
    address public htz = 0x9C8E99eb130AED653Ef90fED709D9C3E9cC8b269;

    constructor(
        address _governance,
        address _strategist,
        address _controller,
        address _timelock
    )
        public
        StrategyPngMiniChefFarmBase(
            _poolId,
            png_avax_htz_lp,
            _governance,
            _strategist,
            _controller,
            _timelock
        )
    {}

    function _takeFeeHtzToSnob(uint256 _keep) internal {
        address[] memory path = new address[](3);
        path[0] = htz;
        path[1] = wavax;
        path[2] = snob;
        IERC20(htz).safeApprove(pangolinRouter, 0);
        IERC20(htz).safeApprove(pangolinRouter, _keep);
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
        uint256 _htz = IERC20(htz).balanceOf(address(this));
        if (_png > 0) {
            // 10% is sent to treasury
            uint256 _keep = _png.mul(keep).div(keepMax);
            if (_keep > 0) {
                _takeFeePngToSnob(_keep);
            }

            _png = IERC20(png).balanceOf(address(this));  
        }

        if (_htz > 0) {
            uint256 _keep2 = _htz.mul(keep).div(keepMax);
            if (_keep2 > 0){
                _takeFeeHtzToSnob(_keep2);
            }
            
            _htz = IERC20(htz).balanceOf(address(this));
        }

        // In the case of PNG Rewards, swap PNG for WAVAX and HTZ
        if(_png > 0){
            IERC20(png).safeApprove(pangolinRouter, 0);
            IERC20(png).safeApprove(pangolinRouter, _png);   
            _swapPangolin(png, wavax, _png.div(2));
            _swapPangolin(png, htz, _png.div(2));
        }

        // In the case of HTZ Rewards, swap HTZ for WAVAX
        if(_htz > 0){
            IERC20(htz).safeApprove(pangolinRouter, 0);
            IERC20(htz).safeApprove(pangolinRouter, _htz.div(2));   
            _swapPangolin(htz, wavax, _htz.div(2)); 
        }

        

        // Adds in liquidity for AVAX/HTZ
        uint256 _wavax = IERC20(wavax).balanceOf(address(this));
        _htz = IERC20(htz).balanceOf(address(this));

        if (_wavax > 0 && _htz > 0) {
            IERC20(wavax).safeApprove(pangolinRouter, 0);
            IERC20(wavax).safeApprove(pangolinRouter, _wavax);

            IERC20(htz).safeApprove(pangolinRouter, 0);
            IERC20(htz).safeApprove(pangolinRouter, _htz);

            IPangolinRouter(pangolinRouter).addLiquidity(
                wavax,
                htz,
                _wavax,
                _htz,
                0,
                0,
                address(this),
                now + 60
            );

            _wavax = IERC20(wavax).balanceOf(address(this));
            _htz = IERC20(htz).balanceOf(address(this));
            _png = IERC20(png).balanceOf(address(this));
            
            // Donates DUST
            if (_wavax > 0){
                IERC20(wavax).transfer(
                    IController(controller).treasury(),
                    _wavax
                );
            }
            if (_htz > 0){
                IERC20(htz).safeTransfer(
                    IController(controller).treasury(),
                    _htz
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
        return "StrategyPngAvaxHtz";
    }
}