// SPDX-License-Identifier: MIT
pragma solidity ^0.6.0;

import "./KeeperBase.sol";
import "./KeeperCompatibleInterface.sol";

abstract contract KeeperCompatible is KeeperBase, KeeperCompatibleInterface {}
