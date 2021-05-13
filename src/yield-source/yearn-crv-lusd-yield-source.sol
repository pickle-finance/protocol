pragma solidity ^0.6.7;

import "../lib/yearn-affiliate-wrapper.sol";
import "./yield-source-base.sol";

contract YearnCrvLusdYieldSource is YieldSourceBase, YearnAffiliateWrapper {
    address public crv_lusd_lp = 0xEd279fDD11cA84bEef15AF5D39BB4d4bEE23F0cA;
    address public yearn_registry = 0x50c1a2eA0a861A967D9d0FFE2AE4012c2E053804;

    constructor() public YieldSourceBase(crv_lusd_lp) YearnAffiliateWrapper(crv_lusd_lp, yearn_registry) {}

    function balanceOfToken(address addr) public override returns (uint256) {
        return totalVaultBalance(addr);
    }

    function supplyTokenTo(uint256 amount, address to) public override {
        _deposit(msg.sender, to, amount, true);
    }

    function redeemToken(uint256 amount) public override returns (uint256) {
        return _withdraw(msg.sender, msg.sender, amount, true);
    }
}