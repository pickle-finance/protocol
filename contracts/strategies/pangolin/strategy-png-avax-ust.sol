pragma solidity ^0.6.7;

import "../strategy-png-minichef-farm-base.sol";

contract StrategyPngAvaxUst is StrategyPngMiniChefFarmBase {
    uint256 public _poolId = 74;

    // Token addresses
    address public png_avax_ust_lp = 0xdeaBb6e80141F5E557EcBDD7e9580F37D7BBc371;
    address public ust = 0x260Bbf5698121EB85e7a74f2E45E16Ce762EbE11;
    address public luna = 0x120AD3e5A7c796349e591F1570D9f7980F4eA9cb;

    constructor(
        address _governance,
        address _strategist,
        address _controller,
        address _timelock
    )
        public
        StrategyPngMiniChefFarmBase(
            _poolId,
            png_avax_ust_lp,
            _governance,
            _strategist,
            _controller,
            _timelock
        )
    {}

    function _takeFeeUstToSnob(uint256 _keep) internal {
        address[] memory path = new address[](3);
        path[0] = ust;
        path[1] = wavax;
        path[2] = snob;
        IERC20(ust).safeApprove(pangolinRouter, 0);
        IERC20(ust).safeApprove(pangolinRouter, _keep);
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

    function _takeFeeLunaToSnob(uint256 _keep) internal {
        address[] memory path = new address[](3);
        path[0] = luna;
        path[1] = wavax;
        path[2] = snob;
        IERC20(luna).safeApprove(pangolinRouter, 0);
        IERC20(luna).safeApprove(pangolinRouter, _keep);
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

    function _swapBaseToToken(uint256 _amount, address token1, address token2) internal {
        address[] memory path = new address[](3);
        path[0] = token1;
        path[1] = wavax;
        path[2] = token2;
        IERC20(token1).safeApprove(pangolinRouter, 0);
        IERC20(token1).safeApprove(pangolinRouter, _amount);
        _swapPangolinWithPath(path, _amount);
    }

    // **** State Mutations ****

    function harvest() public override onlyBenevolent {
        // Collects Token Fees
        IMiniChef(miniChef).harvest(poolId, address(this));

        // Take AVAX Rewards    
        uint256 _avax = address(this).balance;              // get balance of native AVAX
        if (_avax > 0) {                                    // wrap AVAX into ERC20
            WAVAX(wavax).deposit{value: _avax}();
        }

        // 10% is sent to treasury
        uint256 _ust = IERC20(ust).balanceOf(address(this));
        uint256 _wavax = IERC20(wavax).balanceOf(address(this));
        uint256 _png = IERC20(png).balanceOf(address(this));
        uint256 _luna = IERC20(luna).balanceOf(address(this));
        
        if (_ust > 0) {
            uint256 _keep = _ust.mul(keep).div(keepMax);
            if (_keep > 0){
                _takeFeeUstToSnob(_keep);
            }
            
            _ust = IERC20(ust).balanceOf(address(this));
        }

        if (_wavax > 0) {
            uint256 _keep = _wavax.mul(keep).div(keepMax);
            if (_keep > 0) {
                _takeFeeWavaxToSnob(_keep);
            }  

            _wavax = IERC20(wavax).balanceOf(address(this));
        }

        if (_png > 0) {
            uint256 _keep = _png.mul(keep).div(keepMax);
            if (_keep > 0) {
                _takeFeePngToSnob(_keep);
            }

            _png = IERC20(png).balanceOf(address(this));  
        }

        if (_luna > 0) {
            uint256 _keep = _luna.mul(keep).div(keepMax);
            if (_keep > 0) {
                _takeFeeLunaToSnob(_keep);
            }

            _luna = IERC20(luna).balanceOf(address(this));  
        }       

        // In the case of AVAX Rewards, swap half WAVAX for UST
        if(_wavax > 0){
            IERC20(wavax).safeApprove(pangolinRouter, 0);
            IERC20(wavax).safeApprove(pangolinRouter, _wavax.div(2));   
            _swapPangolin(wavax, ust, _wavax.div(2)); 
        } 

        // In the case of UST Rewards, swap half UST for WAVAX
        if(_ust > 0){
            IERC20(ust).safeApprove(pangolinRouter, 0);
            IERC20(ust).safeApprove(pangolinRouter, _ust.div(2));   
            _swapPangolin(ust, wavax, _ust.div(2)); 
        }            

        // In the case of PNG Rewards, swap PNG for WAVAX and UST
        if(_png > 0){
            IERC20(png).safeApprove(pangolinRouter, 0);
            IERC20(png).safeApprove(pangolinRouter, _png);   
            _swapPangolin(png, wavax, _png.div(2));
            _swapBaseToToken(_png.div(2), png, ust); 
        }

        // In the case of LUNA Rewards, swap LUNA for WAVAX and UST
        if(_luna > 0){
            IERC20(luna).safeApprove(pangolinRouter, 0);
            IERC20(luna).safeApprove(pangolinRouter, _luna); 
            _swapPangolin(luna, wavax, _luna.div(2));
            _swapBaseToToken(_luna.div(2), luna, ust); 
        } 

        // Adds in liquidity for AVAX/UST
        _wavax = IERC20(wavax).balanceOf(address(this));
        _ust = IERC20(ust).balanceOf(address(this));

        if (_wavax > 0 && _ust > 0) {
            IERC20(wavax).safeApprove(pangolinRouter, 0);
            IERC20(wavax).safeApprove(pangolinRouter, _wavax);

            IERC20(ust).safeApprove(pangolinRouter, 0);
            IERC20(ust).safeApprove(pangolinRouter, _ust);

            IPangolinRouter(pangolinRouter).addLiquidity(
                wavax,
                ust,
                _wavax,
                _ust,
                0,
                0,
                address(this),
                now + 60
            );

            // Donates DUST
            _wavax = IERC20(wavax).balanceOf(address(this));
            _ust = IERC20(ust).balanceOf(address(this));
            _png = IERC20(png).balanceOf(address(this));
            _luna = IERC20(luna).balanceOf(address(this));

            if (_wavax > 0){
                IERC20(wavax).transfer(
                    IController(controller).treasury(),
                    _wavax
                );
            }

            if (_ust > 0){
                IERC20(ust).safeTransfer(
                    IController(controller).treasury(),
                    _ust
                );
            }          

            if (_png > 0){
                IERC20(png).safeTransfer(
                    IController(controller).treasury(),
                    _png
                );
            }
            
            if (_luna > 0){
                IERC20(luna).safeTransfer(
                    IController(controller).treasury(),
                    _luna
                );
            }
        }
        
        _distributePerformanceFeesAndDeposit();
    }

    // **** Views ****

    function getName() external pure override returns (string memory) {
        return "StrategyPngAvaxUst";
    }
}