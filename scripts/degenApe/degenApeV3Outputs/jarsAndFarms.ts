
export const JAR_GNOSIS_SUSHI_LINK_XDAI_LP: JarDefinition = {
        type: AssetType.JAR,
        id: "gnosisJar 1a",
        contract: "0xfA09E6CE60c02eB0D6F333Fc6aA6A3595A4Acc2a",
        startBlock: 22042322,
        depositToken: {
          addr: "0xB320609F2Bf3ca98754c14Db717307c6d6794d8b",
          name: "SushiLP LINK/XDAI",
          link: "https://app.sushi.com/add/0xB320609F2Bf3ca98754c14Db717307c6d6794d8b",
          components: ["link", "xdai"],
        },
        rewardTokens: ["sushi", "gno"],
        enablement: AssetEnablement.ENABLED,
        chain: ChainNetwork.Gnosis,
        protocol: AssetProtocol.SUSHI,
        details: {
          apiKey: "SUSHILP-LINK-XDAI",
          harvestStyle: HarvestStyle.PASSIVE,
          controller: "0xe5E231De20C68AabB8D669f87971aE57E2AbF680"
        },
        farm: {
          farmAddress: NULL_ADDRESS,
          farmNickname: "pSushiLP LINK/XDAI",
          farmDepositTokenName: "pSushiLP LINK/XDAI",
        },
    };
    JAR_DEFINITIONS.push(JAR_GNOSIS_SUSHI_LINK_XDAI_LP);
    
export const JAR_GNOSIS_SUSHI_SUSHI_GNO_LP: JarDefinition = {
        type: AssetType.JAR,
        id: "gnosisJar 1a",
        contract: "0xcD59f36bfeFFC5B38FeE585e20E2E32052b679d9",
        startBlock: 22044084,
        depositToken: {
          addr: "0xF38c5b39F29600765849cA38712F302b1522C9B8",
          name: "SushiLP SUSHI/GNO",
          link: "https://app.sushi.com/add/0xF38c5b39F29600765849cA38712F302b1522C9B8",
          components: ["sushi", "gno"],
        },
        rewardTokens: ["sushi", "gno"],
        enablement: AssetEnablement.ENABLED,
        chain: ChainNetwork.Gnosis,
        protocol: AssetProtocol.SUSHI,
        details: {
          apiKey: "SUSHILP-SUSHI-GNO",
          harvestStyle: HarvestStyle.PASSIVE,
          controller: "0xe5E231De20C68AabB8D669f87971aE57E2AbF680"
        },
        farm: {
          farmAddress: NULL_ADDRESS,
          farmNickname: "pSushiLP SUSHI/GNO",
          farmDepositTokenName: "pSushiLP SUSHI/GNO",
        },
    };
    JAR_DEFINITIONS.push(JAR_GNOSIS_SUSHI_SUSHI_GNO_LP);
    
export const JAR_GNOSIS_SUSHI_USDC_XDAI_LP: JarDefinition = {
        type: AssetType.JAR,
        id: "gnosisJar 1a",
        contract: "0x59A04fB987a55Ef6a4d95B3C369eBb6dC91dcdC0",
        startBlock: 22044609,
        depositToken: {
          addr: "0xA227c72a4055A9DC949cAE24f54535fe890d3663",
          name: "SushiLP USDC/XDAI",
          link: "https://app.sushi.com/add/0xA227c72a4055A9DC949cAE24f54535fe890d3663",
          components: ["usdc", "xdai"],
        },
        rewardTokens: ["sushi", "gno"],
        enablement: AssetEnablement.ENABLED,
        chain: ChainNetwork.Gnosis,
        protocol: AssetProtocol.SUSHI,
        details: {
          apiKey: "SUSHILP-USDC-XDAI",
          harvestStyle: HarvestStyle.PASSIVE,
          controller: "0xe5E231De20C68AabB8D669f87971aE57E2AbF680"
        },
        farm: {
          farmAddress: NULL_ADDRESS,
          farmNickname: "pSushiLP USDC/XDAI",
          farmDepositTokenName: "pSushiLP USDC/XDAI",
        },
    };
    JAR_DEFINITIONS.push(JAR_GNOSIS_SUSHI_USDC_XDAI_LP);
    
export const JAR_GNOSIS_SUSHI_USDT_USDC_LP: JarDefinition = {
        type: AssetType.JAR,
        id: "gnosisJar 1b",
        contract: "0xB4dE8612Ee2AaC8646a6FeaB8CEaB04BF8a908aB",
        startBlock: 22044681,
        depositToken: {
          addr: "0x74c2EFA722010Ad7C142476F525A051084dA2C42",
          name: "SushiLP USDT/USDC",
          link: "https://app.sushi.com/add/0x74c2EFA722010Ad7C142476F525A051084dA2C42",
          components: ["usdt", "usdc"],
        },
        rewardTokens: ["sushi", "gno"],
        enablement: AssetEnablement.ENABLED,
        chain: ChainNetwork.Gnosis,
        protocol: AssetProtocol.SUSHI,
        details: {
          apiKey: "SUSHILP-USDT-USDC",
          harvestStyle: HarvestStyle.PASSIVE,
          controller: "0xe5E231De20C68AabB8D669f87971aE57E2AbF680"
        },
        farm: {
          farmAddress: NULL_ADDRESS,
          farmNickname: "pSushiLP USDT/USDC",
          farmDepositTokenName: "pSushiLP USDT/USDC",
        },
    };
    JAR_DEFINITIONS.push(JAR_GNOSIS_SUSHI_USDT_USDC_LP);
    
export const JAR_GNOSIS_SUSHI_USDT_XDAI_LP: JarDefinition = {
        type: AssetType.JAR,
        id: "gnosisJar 1c",
        contract: "0xF81eDA759b0F07A88B5D3E497090C4272C194166",
        startBlock: 22044757,
        depositToken: {
          addr: "0x6685C047EAB042297e659bFAa7423E94b4A14b9E",
          name: "SushiLP USDT/XDAI",
          link: "https://app.sushi.com/add/0x6685C047EAB042297e659bFAa7423E94b4A14b9E",
          components: ["usdt", "xdai"],
        },
        rewardTokens: ["sushi", "gno"],
        enablement: AssetEnablement.ENABLED,
        chain: ChainNetwork.Gnosis,
        protocol: AssetProtocol.SUSHI,
        details: {
          apiKey: "SUSHILP-USDT-XDAI",
          harvestStyle: HarvestStyle.PASSIVE,
          controller: "0xe5E231De20C68AabB8D669f87971aE57E2AbF680"
        },
        farm: {
          farmAddress: NULL_ADDRESS,
          farmNickname: "pSushiLP USDT/XDAI",
          farmDepositTokenName: "pSushiLP USDT/XDAI",
        },
    };
    JAR_DEFINITIONS.push(JAR_GNOSIS_SUSHI_USDT_XDAI_LP);
    
export const JAR_GNOSIS_SUSHI_WETH_GNO_LP: JarDefinition = {
        type: AssetType.JAR,
        id: "gnosisJar 1d",
        contract: "0xBC84dfF55e6847Ca4e6C2D2519aeA1539839E284",
        startBlock: 22044836,
        depositToken: {
          addr: "0x15f9EEdeEBD121FBb238a8A0caE38f4b4A07A585",
          name: "SushiLP WETH/GNO",
          link: "https://app.sushi.com/add/0x15f9EEdeEBD121FBb238a8A0caE38f4b4A07A585",
          components: ["weth", "gno"],
        },
        rewardTokens: ["sushi", "gno"],
        enablement: AssetEnablement.ENABLED,
        chain: ChainNetwork.Gnosis,
        protocol: AssetProtocol.SUSHI,
        details: {
          apiKey: "SUSHILP-WETH-GNO",
          harvestStyle: HarvestStyle.PASSIVE,
          controller: "0xe5E231De20C68AabB8D669f87971aE57E2AbF680"
        },
        farm: {
          farmAddress: NULL_ADDRESS,
          farmNickname: "pSushiLP WETH/GNO",
          farmDepositTokenName: "pSushiLP WETH/GNO",
        },
    };
    JAR_DEFINITIONS.push(JAR_GNOSIS_SUSHI_WETH_GNO_LP);
    
export const JAR_GNOSIS_SUSHI_WETH_WBTC_LP: JarDefinition = {
        type: AssetType.JAR,
        id: "gnosisJar 1e",
        contract: "0x0f11806f2D186D4a88002F89ee3Cb5aD58E383B3",
        startBlock: 22044904,
        depositToken: {
          addr: "0xe21F631f47bFB2bC53ED134E83B8cff00e0EC054",
          name: "SushiLP WETH/WBTC",
          link: "https://app.sushi.com/add/0xe21F631f47bFB2bC53ED134E83B8cff00e0EC054",
          components: ["weth", "wbtc"],
        },
        rewardTokens: ["sushi", "gno"],
        enablement: AssetEnablement.ENABLED,
        chain: ChainNetwork.Gnosis,
        protocol: AssetProtocol.SUSHI,
        details: {
          apiKey: "SUSHILP-WETH-WBTC",
          harvestStyle: HarvestStyle.PASSIVE,
          controller: "0xe5E231De20C68AabB8D669f87971aE57E2AbF680"
        },
        farm: {
          farmAddress: NULL_ADDRESS,
          farmNickname: "pSushiLP WETH/WBTC",
          farmDepositTokenName: "pSushiLP WETH/WBTC",
        },
    };
    JAR_DEFINITIONS.push(JAR_GNOSIS_SUSHI_WETH_WBTC_LP);
    
export const JAR_GNOSIS_SUSHI_WETH_XDAI_LP: JarDefinition = {
        type: AssetType.JAR,
        id: "gnosisJar 1f",
        contract: "0x648159Fd32340108762F256bB5c739Ec4E12F797",
        startBlock: 22044980,
        depositToken: {
          addr: "0x8C0C36c85192204c8d782F763fF5a30f5bA0192F",
          name: "SushiLP WETH/XDAI",
          link: "https://app.sushi.com/add/0x8C0C36c85192204c8d782F763fF5a30f5bA0192F",
          components: ["weth", "xdai"],
        },
        rewardTokens: ["sushi", "gno"],
        enablement: AssetEnablement.ENABLED,
        chain: ChainNetwork.Gnosis,
        protocol: AssetProtocol.SUSHI,
        details: {
          apiKey: "SUSHILP-WETH-XDAI",
          harvestStyle: HarvestStyle.PASSIVE,
          controller: "0xe5E231De20C68AabB8D669f87971aE57E2AbF680"
        },
        farm: {
          farmAddress: NULL_ADDRESS,
          farmNickname: "pSushiLP WETH/XDAI",
          farmDepositTokenName: "pSushiLP WETH/XDAI",
        },
    };
    JAR_DEFINITIONS.push(JAR_GNOSIS_SUSHI_WETH_XDAI_LP);
    