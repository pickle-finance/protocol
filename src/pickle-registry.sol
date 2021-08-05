// SPDX-License-Identifier: MIT

pragma solidity ^0.6.7;
pragma experimental ABIEncoderV2;

import "./lib/enumerableSet.sol";
import "./interfaces/jar.sol";

contract PickleRegistry {
  using EnumerableSet for EnumerableSet.AddressSet;

  address public governance;
  mapping(address => bool) public curators;
  EnumerableSet.AddressSet private development;
  EnumerableSet.AddressSet private production;

  event RegisterVault(address vault);
  event PromoteVault(address vault);
  event DemoteVault(address vault);
  event RemoveVault(address vault);

  event RegisterGauge(address gauge);
  event RemoveGauge(address gauge);
  
  constructor() public {
    governance = msg.sender;
    curators[msg.sender] = true;
  }

  function setGovernance(address _governance) public {
    require(msg.sender == governance, "!governance");
    governance = _governance;
    curators[_governance] = true;
  }

  function addCurators(address[] calldata _curators) external {
    require(curators[msg.sender], "!curator");
    for (uint i = 0; i < _curators.length; i++) {
      curators[_curators[i]] = true;
    }
  }
  
  function removeCurators(address[] calldata _curators) external {
    require(msg.sender == governance, "!governance");
    for(uint i = 0; i < _curators.length; i++) {
      require(_curators[i] != governance, "cannot remove governance");
    }
    for (uint i = 0; i < _curators.length; i++) {
      curators[_curators[i]] = false;
    }
  }

  function registerVault(address _vault) external {
    require(curators[msg.sender], "!curator");
    require(!development.contains(_vault), "vault previously registered");
    require(!production.contains(_vault), "vault previously registered");
    bool added = development.add(_vault);
    if (added) {
      emit RegisterVault(_vault);
    }
  }

  function promoteVault(address _vault) external {
    require(curators[msg.sender], "!curator");
    require(development.contains(_vault), "!development");
    bool removed = development.remove(_vault);
    bool added = production.add(_vault);
    if (removed && added) {
      emit PromoteVault(_vault);
    }
  }

  function demoteVault(address _vault) external {
    require(curators[msg.sender], "!curator");
    require(production.contains(_vault), "!production");
    bool removed = production.remove(_vault);
    bool added = development.add(_vault);
    if (removed && added) {
      emit DemoteVault(_vault);
    }
  }

  function removeVault(address _vault) external {
    require(curators[msg.sender], "!curator");
    bool devRemoved = false;
    bool prodRemoved = false;
    if (development.contains(_vault)) {
      devRemoved = development.remove(_vault);
    }
    if (production.contains(_vault)) {
      prodRemoved = production.remove(_vault);
    }
    if (devRemoved || prodRemoved) {
      emit RemoveVault(_vault);
    }
  }

  function addGauge(address _gauge) external {
    require(curators[msg.sender], "!curator");
    emit RegisterGauge(_gauge);
  }

  function removeGauge(address _gauge) external {
    require(curators[msg.sender], "!curator");
    emit RemoveGauge(_gauge);
  }

  function developmentVaults() external view returns (address[] memory) {
    uint256 vaults = development.length();
    address[] memory details = new address[](vaults);

    for (uint i = 0; i < vaults; i++) {
      details[i] = development.at(i);
    }

    return details;
  }

  function productionVaults() external view returns (address[] memory) {
    uint256 vaults = production.length();
    address[] memory details = new address[](vaults);

    for (uint i = 0; i < vaults; i++) {
      details[i] = production.at(i);
    }

    return details;
  }

}
