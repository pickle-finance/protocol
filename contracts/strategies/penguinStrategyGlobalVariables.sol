// SPDX-License-Identifier: MIT
pragma solidity ^0.6.7;

import "../lib/ownable.sol";

contract PenguinStrategyGlobalVariables is Ownable {
    uint256 public POOL_CREATOR_FEE_BIPS;
    uint256 public NEST_FEE_BIPS;
    uint256 public DEV_FEE_BIPS;
    uint256 public ALTERNATE_FEE_BIPS;
    uint256 public constant MAX_TOTAL_FEE = 1000;

    address public devAddress;
    address public nestAddress;
    address public alternateAddress;

    event FeeStructureUpdated(
        uint256 newPOOL_CREATOR_FEE_BIPS,
        uint256 newNEST_FEE_BIPS,
        uint256 newDEV_FEE_BIPS,
        uint256 newALTERNATE_FEE_BIPS
    );
    event UpdateDevAddress(address oldValue, address newValue);
    event UpdateNestAddress(address oldValue, address newValue);
    event UpdateAlternateAddress(address oldValue, address newValue);

    constructor(
        uint256 newPOOL_CREATOR_FEE_BIPS,
        uint256 newNEST_FEE_BIPS,
        uint256 newDEV_FEE_BIPS,
        uint256 newALTERNATE_FEE_BIPS,
        address newDevAddress,
        address newNestAddress,
        address newAlternateAddress
    ) public {
        updateFeeStructure(
            newPOOL_CREATOR_FEE_BIPS,
            newNEST_FEE_BIPS,
            newDEV_FEE_BIPS,
            newALTERNATE_FEE_BIPS
        );
        updateDevAddress(newDevAddress);
        updateNestAddress(newNestAddress);
        updateAlternateAddress(newAlternateAddress);
    }

    function updateFeeStructure(
        uint256 newPOOL_CREATOR_FEE_BIPS,
        uint256 newNEST_FEE_BIPS,
        uint256 newDEV_FEE_BIPS,
        uint256 newALTERNATE_FEE_BIPS
    ) public onlyOwner {
        require(
            (newPOOL_CREATOR_FEE_BIPS +
                newNEST_FEE_BIPS +
                newDEV_FEE_BIPS +
                newALTERNATE_FEE_BIPS) <= MAX_TOTAL_FEE,
            "new fees too high"
        );
        POOL_CREATOR_FEE_BIPS = newPOOL_CREATOR_FEE_BIPS;
        NEST_FEE_BIPS = newNEST_FEE_BIPS;
        DEV_FEE_BIPS = newDEV_FEE_BIPS;
        ALTERNATE_FEE_BIPS = newALTERNATE_FEE_BIPS;
        emit FeeStructureUpdated(
            newPOOL_CREATOR_FEE_BIPS,
            newNEST_FEE_BIPS,
            newDEV_FEE_BIPS,
            newALTERNATE_FEE_BIPS
        );
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
