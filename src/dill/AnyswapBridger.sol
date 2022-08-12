// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.1;

interface IAnycallV6Proxy {
    function executor() external view returns (address);

    function anyCall(
        address _to,
        bytes calldata _data,
        address _fallback,
        uint256 _toChainID,
        uint256 _flag
    ) external payable;

    function calcSrcFees(
        string calldata _appID,
        uint256 _toChainID,
        uint256 _dataLength
    ) external view returns (uint256);
}

contract AnyswapBridger {
    IAnycallV6Proxy public constant anyswap =
        IAnycallV6Proxy(0x273a4fFcEb31B8473D51051Ad2a2EdbB7Ac8Ce02);
    uint256 public flag = 2;
    string public appId = "0";
    address public admin;

    mapping(uint256 => address) public sidechainVaults;

    modifier onlyAdmin() {
        require(msg.sender == admin, "can only be called by admin");
        _;
    }

    constructor(address _admin) {
        require(_admin != address(0), "admin cannot be zero");
        admin = _admin;
    }

    receive() external payable {}

    function addVaultWRTChain(uint256 chainId, address vault)
        external
        onlyAdmin
    {
        sidechainVaults[chainId] = vault;
    }

    function addressToBytes(address[] calldata mainchainGauges)
        internal
        pure
        returns (bytes memory msg)
    {
        msg = abi.encode(uint256(mainchainGauges.length));
        for (uint i = 0; i < mainchainGauges.length; i++) {
            msg = abi.encode(msg, mainchainGauges[i]);
        }
    }

    function uint256ToBytes(uint256[] calldata weights)
        internal
        pure
        returns (bytes memory msg)
    {
        msg = abi.encode(uint256(weights.length));
        for (uint i = 0; i < weights.length; i++) {
            msg = abi.encode(msg, weights[i]);
        }
    }

    function bridge(
        uint256 chainId,
        uint256 amount,
        address[] calldata mainchainGauges,
        uint256[] calldata weights
    ) external {
        address vault = sidechainVaults[chainId];
        require(
            vault != address(0),
            "Vault is not registered for this chainId"
        );
        require(
            vault != address(0),
            "vault is not registerd for a given chain"
        );
        bytes memory msg = abi.encode(
            chainId,
            amount,
            addressToBytes(mainchainGauges),
            uint256ToBytes(weights)
        );
        uint256 fee = anyswap.calcSrcFees(appId, chainId, msg.length);
        require(fee <= address(this).balance, "insufficient fee");
        anyswap.anyCall{value: fee}(vault, msg, address(0), chainId, flag);
    }
}
