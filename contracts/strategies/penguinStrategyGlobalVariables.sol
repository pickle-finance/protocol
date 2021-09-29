pragma solidity ^0.6.7;

import "../lib/ownable.sol";

contract PenguinStrategyGlobalVariables is Ownable {


    uint public POOL_CREATOR_FEE_BIPS;
    uint public NEST_FEE_BIPS;
    uint public DEV_FEE_BIPS;
    uint public ALTERNATE_FEE_BIPS;
    uint constant public MAX_TOTAL_FEE = 1000;

    address public devAddress;
    address public nestAddress;
    address public alternateAddress;

    event FeeStructureUpdated(uint newPOOL_CREATOR_FEE_BIPS, uint newNEST_FEE_BIPS, uint newDEV_FEE_BIPS, uint newALTERNATE_FEE_BIPS);
    event UpdateDevAddress(address oldValue, address newValue);
    event UpdateNestAddress(address oldValue, address newValue);
    event UpdateAlternateAddress(address oldValue, address newValue);

    constructor(uint newPOOL_CREATOR_FEE_BIPS, uint newNEST_FEE_BIPS, uint newDEV_FEE_BIPS, uint newALTERNATE_FEE_BIPS, address newDevAddress, address newNestAddress, address newAlternateAddress) {
        updateFeeStructure(newPOOL_CREATOR_FEE_BIPS, newNEST_FEE_BIPS, newDEV_FEE_BIPS, newALTERNATE_FEE_BIPS);
        updateDevAddress(newDevAddress);
        updateNestAddress(newNestAddress);
        updateAlternateAddress(newAlternateAddress);
    }

    function updateFeeStructure(uint newPOOL_CREATOR_FEE_BIPS, uint newNEST_FEE_BIPS, uint newDEV_FEE_BIPS, uint newALTERNATE_FEE_BIPS) public onlyOwner {
        require((newPOOL_CREATOR_FEE_BIPS + newNEST_FEE_BIPS + newDEV_FEE_BIPS + newALTERNATE_FEE_BIPS) <= MAX_TOTAL_FEE, "new fees too high");
        POOL_CREATOR_FEE_BIPS = newPOOL_CREATOR_FEE_BIPS;
        NEST_FEE_BIPS = newNEST_FEE_BIPS;
        DEV_FEE_BIPS = newDEV_FEE_BIPS;
        ALTERNATE_FEE_BIPS = newALTERNATE_FEE_BIPS;
        emit FeeStructureUpdated(newPOOL_CREATOR_FEE_BIPS, newNEST_FEE_BIPS, newDEV_FEE_BIPS, newALTERNATE_FEE_BIPS);
    }
    function updateDevAddress(address newValue) public onlyOwner {
        emit UpdateDevAddress(devAddress, newValue);
        devAddress = newValue;
    }
    function updateNestAddress(address newValue) public onlyOwner {
        emit UpdateNestAddress(nestAddress, newValue);
        nestAddress = newValue;
    }
    function updateAlternateAddress(address newValue) public onlyOwner {
        emit UpdateAlternateAddress(nestAddress, newValue);
        alternateAddress = newValue;
    }
}