// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.1;

interface IAnycallV6Proxy {
    function executor() external view returns (address);

    function anyCall(
        address _to,
        bytes calldata _data,
        address _fallback,
        uint256 _toChainID,
        uint256 _flags
    ) external payable;

    function calcSrcFees(
        string calldata _appID,
        uint256 _toChainID,
        uint256 _dataLength
    ) external view returns (uint256);
}

contract AnySwapBridger {
    IAnycallV6Proxy public anyCallProxy =
        IAnycallV6Proxy(0x273a4fFcEb31B8473D51051Ad2a2EdbB7Ac8Ce02);
    uint256 public flags = 2;
    string public appId = "0";
    address public admin;

    struct SideChain {
        uint256 chainId;
        bool active;
    }

    mapping(address => SideChain) public sideChainGauges;
    mapping(uint256 => address) public sideChainVaultAddresses;

    modifier onlyAdmin() {
        require(admin == msg.sender, "only called by Admin");
        _;
    }

    function _updateAdmin(address _admin) internal {
        require(_admin != address(0), "admin cannot be zero");
        admin = _admin;
    }

    constructor(address _admin) {
        _updateAdmin(_admin);
    }

    function changeAdmin(address _admin) external onlyAdmin {
        _updateAdmin(_admin);
    }

    function setAnyswapFeeMode(uint8 _flags) external onlyAdmin {
        require(_flags < 3, "invalid value");
        require(_flags != flags);
        flags = uint256(_flags);
        emit UpdateFlag(_flags);
    }

    function setAnySwapCallProxy(address _anyswap) external onlyAdmin {
        require(_anyswap != address(0), "cannot set to zero address");
        anyCallProxy = IAnycallV6Proxy(_anyswap);
        emit UpdateAnyswap(_anyswap);
    }

    function updateAppId(string calldata _appId) external onlyAdmin {
        require(bytes(_appId).length > 0, "cannot be blank string");
        appId = _appId;
    }

    function registerGauge(address _gauge, uint256 _chainId)
        external
        onlyAdmin
    {
        SideChain memory sideChainGauge = sideChainGauges[_gauge];
        require(!sideChainGauge.active, "is already active");
        sideChainGauge.active = true;
        sideChainGauge.chainId = _chainId;
        sideChainGauges[_gauge] = sideChainGauge;
        emit SideChainGaugeEnabled(_gauge, _chainId);
    }

    function deregister(address _gauge) external onlyAdmin {
        delete sideChainGauges[_gauge];
        emit SideChainGaugeDisabled(_gauge);
    }

    function registerChainWithVault(uint256 _chainId, address _vault)
        external
        onlyAdmin
    {
        sideChainVaultAddresses[_chainId] = _vault;
        emit UpdateVaultWithChainID(_chainId, _vault);
    }

    receive() external payable {
        // React to receiving ether
    }

    // TODO: should we handle fee calculation
    function bridge(uint256 amount) external {
        address _gauge = msg.sender;
        SideChain memory sidechain = sideChainGauges[_gauge];
        require(sidechain.active, "sidechain is invalid");
        address sidechainVault = sideChainVaultAddresses[sidechain.chainId];
        bytes memory data = abi.encode(_gauge, amount);
        // uint256 fee = anyCallProxy.calcSrcFees(
        //     appId,
        //     sidechain.chainId,
        //     data.length
        // );
        // require(fee <= address(this).balance, "cannot initiate a transaction");
        anyCallProxy.anyCall{value: 300000000000000}(
            sidechainVault,
            data,
            address(this),
            sidechain.chainId,
            flags
        );
    }

    event UpdateAnyswap(address newAnyswapProxy);
    event UpdateFlag(uint256 newFlag);
    event UpdateVaultWithChainID(uint256 chainId, address vault);

    event SideChainGaugeEnabled(
        address indexed mainChainGauge,
        uint256 chainId
    );
    event SideChainGaugeDisabled(address indexed mainChainGauge);
}
