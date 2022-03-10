
export const JAR_TRI_ROSE_NEAR: JarDefinition = {
  type: AssetType.JAR,
  id: "auroraJar 1s",
  contract: "0xFb56aecFb7eF86c524E70E090B15CD4a643BBEc5",
  startBlock: 64156232,
  depositToken: {
    addr: "0xbe753E99D0dBd12FB39edF9b884eBF3B1B09f26C",
    name: "TriLP ROSE/NEAR",
    link: "https://www.trisolaris.io/#/add/0xbe753E99D0dBd12FB39edF9b884eBF3B1B09f26C",
    components: ["rose", "near"],
  },
  rewardTokens: ["tri"],
  enablement: AssetEnablement.ENABLED,
  chain: ChainNetwork.Aurora,
  protocol: AssetProtocol.TRI,
  details: {
    apiKey: "TRILP-ROSE-NEAR",
    harvestStyle: HarvestStyle.CUSTOM,
    controller: "0xdc954e7399e9ADA2661cdddb8D4C19c19E070A8E"
  },
  farm: {
    farmAddress: "",
    farmNickname: "pTriLP ROSE/NEAR",
    farmDepositTokenName: "pTriLP ROSE/NEAR",
  },
};
JAR_DEFINITIONS.push(JAR_TRI_ROSE_NEAR);

export const JAR_TRISOLARIS_RUSD_NEAR: JarDefinition = {
  type: AssetType.JAR,
  id: "auroraJar 1t",
  contract: "0x471a605E4E2Eca369065da90110685d073CBFf1D",
  startBlock: 64156815,
  depositToken: {
    addr: "0xbC0e71aE3Ef51ae62103E003A9Be2ffDe8421700",
    name: "TrisolarisLP RUSD/NEAR",
    link: "https://www.trisolaris.io/#/add/0xbC0e71aE3Ef51ae62103E003A9Be2ffDe8421700",
    components: ["rusd", "near"],
  },
  rewardTokens: ["tri"],
  enablement: AssetEnablement.ENABLED,
  chain: ChainNetwork.Aurora,
  protocol: AssetProtocol.TRISOLARIS,
  details: {
    apiKey: "TRISOLARISLP-RUSD-NEAR",
    harvestStyle: HarvestStyle.CUSTOM,
    controller: "0xdc954e7399e9ADA2661cdddb8D4C19c19E070A8E"
  },
  farm: {
    farmAddress: "",
    farmNickname: "pTrisolarisLP RUSD/NEAR",
    farmDepositTokenName: "pTrisolarisLP RUSD/NEAR",
  },
};
JAR_DEFINITIONS.push(JAR_TRISOLARIS_RUSD_NEAR);

export const JAR_TRISOLARIS_LINEAR_NEAR: JarDefinition = {
  type: AssetType.JAR,
  id: "auroraJar 1t",
  contract: "0x52C7Bc8a7F8dFF855ed4a8cEF6196c36D00E5cAA",
  startBlock: 64157710,
  depositToken: {
    addr: "0xbceA13f9125b0E3B66e979FedBCbf7A4AfBa6fd1",
    name: "TrisolarisLP LINEAR/NEAR",
    link: "https://www.trisolaris.io/#/add/0xbceA13f9125b0E3B66e979FedBCbf7A4AfBa6fd1",
    components: ["linear", "near"],
  },
  rewardTokens: ["tri"],
  enablement: AssetEnablement.ENABLED,
  chain: ChainNetwork.Aurora,
  protocol: AssetProtocol.TRISOLARIS,
  details: {
    apiKey: "TRISOLARISLP-LINEAR-NEAR",
    harvestStyle: HarvestStyle.CUSTOM,
    controller: "0xdc954e7399e9ADA2661cdddb8D4C19c19E070A8E"
  },
  farm: {
    farmAddress: "",
    farmNickname: "pTrisolarisLP LINEAR/NEAR",
    farmDepositTokenName: "pTrisolarisLP LINEAR/NEAR",
  },
};
JAR_DEFINITIONS.push(JAR_TRISOLARIS_LINEAR_NEAR);

export const JAR_TRISOLARIS_SOLACE_NEAR: JarDefinition = {
  type: AssetType.JAR,
  id: "auroraJar 1u",
  contract: "0x0EA5D709851ae7A6856677b880b8c56e87e7877B",
  startBlock: 64160109,
  depositToken: {
    addr: "0xdDAdf88b007B95fEb42DDbd110034C9a8e9746F2",
    name: "TrisolarisLP SOLACE/NEAR",
    link: "https://www.trisolaris.io/#/add/0xdDAdf88b007B95fEb42DDbd110034C9a8e9746F2",
    components: ["solace", "near"],
  },
  rewardTokens: ["trisolaris"],
  enablement: AssetEnablement.ENABLED,
  chain: ChainNetwork.Aurora,
  protocol: AssetProtocol.TRISOLARIS,
  details: {
    apiKey: "TRISOLARISLP-SOLACE-NEAR",
    harvestStyle: HarvestStyle.CUSTOM,
    controller: "0xdc954e7399e9ADA2661cdddb8D4C19c19E070A8E"
  },
  farm: {
    farmAddress: "",
    farmNickname: "pTrisolarisLP SOLACE/NEAR",
    farmDepositTokenName: "pTrisolarisLP SOLACE/NEAR",
  },
};
JAR_DEFINITIONS.push(JAR_TRISOLARIS_SOLACE_NEAR);

export const JAR_TRISOLARIS_XNL_AURORA: JarDefinition = {
  type: AssetType.JAR,
  id: "auroraJar 1u",
  contract: "0x81B33CE33fFCA20B1082657c9fE280Ff4dF7b180",
  startBlock: 64172013,
  depositToken: {
    addr: "0xb419ff9221039Bdca7bb92A131DD9CF7DEb9b8e5",
    name: "TrisolarisLP XNL/AURORA",
    link: "https://www.trisolaris.io/#/add/0xb419ff9221039Bdca7bb92A131DD9CF7DEb9b8e5",
    components: ["xnl", "aurora"],
  },
  rewardTokens: ["trisolaris"],
  enablement: AssetEnablement.ENABLED,
  chain: ChainNetwork.Aurora,
  protocol: AssetProtocol.TRISOLARIS,
  details: {
    apiKey: "TRISOLARISLP-XNL-AURORA",
    harvestStyle: HarvestStyle.CUSTOM,
    controller: "0xdc954e7399e9ADA2661cdddb8D4C19c19E070A8E"
  },
  farm: {
    farmAddress: "",
    farmNickname: "pTrisolarisLP XNL/AURORA",
    farmDepositTokenName: "pTrisolarisLP XNL/AURORA",
  },
};
JAR_DEFINITIONS.push(JAR_TRISOLARIS_XNL_AURORA);

export const JAR_TRISOLARIS_BBT_NEAR: JarDefinition = {
  type: AssetType.JAR,
  id: "auroraJar undefined",
  contract: "0xA3342A7CB3fc1Fb8de3Fb7ef5d4A30e0e56C36CD",
  startBlock: 64174797,
  depositToken: {
    addr: "0xadAbA7E2bf88Bd10ACb782302A568294566236dC",
    name: "TrisolarisLP BBT/NEAR",
    link: "https://www.trisolaris.io/#/add/0xadAbA7E2bf88Bd10ACb782302A568294566236dC",
    components: ["bbt", "near"],
  },
  rewardTokens: ["trisolaris"],
  enablement: AssetEnablement.ENABLED,
  chain: ChainNetwork.Aurora,
  protocol: AssetProtocol.TRISOLARIS,
  details: {
    apiKey: "TRISOLARISLP-BBT-NEAR",
    harvestStyle: HarvestStyle.CUSTOM,
    controller: "0xdc954e7399e9ADA2661cdddb8D4C19c19E070A8E"
  },
  farm: {
    farmAddress: "",
    farmNickname: "pTrisolarisLP BBT/NEAR",
    farmDepositTokenName: "pTrisolarisLP BBT/NEAR",
  },
};
JAR_DEFINITIONS.push(JAR_TRISOLARIS_BBT_NEAR);


export const JAR_TRISOLARIS_GBA_USDT: JarDefinition = {
        type: AssetType.JAR,
        id: "auroraJar 1v",
        contract: "0xCf84A5B0Ba6EE93AE6608A4C9C64705F3a9227b6",
        startBlock: 64179265,
        depositToken: {
          addr: "0x7B273238C6DD0453C160f305df35c350a123E505",
          name: "TrisolarisLP GBA/USDT",
          link: "https://www.trisolaris.io/#/add/0x7B273238C6DD0453C160f305df35c350a123E505",
          components: ["gba", "usdt"],
        },
        rewardTokens: ["trisolaris"],
        enablement: AssetEnablement.ENABLED,
        chain: ChainNetwork.Aurora,
        protocol: AssetProtocol.TRISOLARIS,
        details: {
          apiKey: "TRISOLARISLP-GBA-USDT",
          harvestStyle: HarvestStyle.CUSTOM,
          controller: "0xdc954e7399e9ADA2661cdddb8D4C19c19E070A8E"
        },
        farm: {
          farmAddress: "",
          farmNickname: "pTrisolarisLP GBA/USDT",
          farmDepositTokenName: "pTrisolarisLP GBA/USDT",
        },
    };
    JAR_DEFINITIONS.push(JAR_TRISOLARIS_GBA_USDT);
    
export const JAR_TRISOLARIS_USDC_SHITZU: JarDefinition = {
        type: AssetType.JAR,
        id: "auroraJar 1w",
        contract: "0x7977844f44BFb9d33302FC4A99bB0247BA13478c",
        startBlock: 64179676,
        depositToken: {
          addr: "0x5E74D85311fe2409c341Ce49Ce432BB950D221DE",
          name: "TrisolarisLP USDC/SHITZU",
          link: "https://www.trisolaris.io/#/add/0x5E74D85311fe2409c341Ce49Ce432BB950D221DE",
          components: ["usdc", "shitzu"],
        },
        rewardTokens: ["trisolaris"],
        enablement: AssetEnablement.ENABLED,
        chain: ChainNetwork.Aurora,
        protocol: AssetProtocol.TRISOLARIS,
        details: {
          apiKey: "TRISOLARISLP-USDC-SHITZU",
          harvestStyle: HarvestStyle.CUSTOM,
          controller: "0xdc954e7399e9ADA2661cdddb8D4C19c19E070A8E"
        },
        farm: {
          farmAddress: "",
          farmNickname: "pTrisolarisLP USDC/SHITZU",
          farmDepositTokenName: "pTrisolarisLP USDC/SHITZU",
        },
    };
    JAR_DEFINITIONS.push(JAR_TRISOLARIS_USDC_SHITZU);
    
export const JAR_NEARPAD_MODA_PAD: JarDefinition = {
        type: AssetType.JAR,
        id: "auroraJar 3g",
        contract: "0x03C648B58683b389c336D08d1214041B69135430",
        startBlock: 64186807,
        depositToken: {
          addr: "0xC8F45738e2900fCaB9B72EA624F48aE2c222e248",
          name: "NearpadLP MODA/PAD",
          link: "https://pad.fi/dex/add/0xC8F45738e2900fCaB9B72EA624F48aE2c222e248",
          components: ["moda", "pad"],
        },
        rewardTokens: ["pad"],
        enablement: AssetEnablement.ENABLED,
        chain: ChainNetwork.Aurora,
        protocol: AssetProtocol.NEARPAD,
        details: {
          apiKey: "NEARPADLP-MODA-PAD",
          harvestStyle: HarvestStyle.CUSTOM,
          controller: "0xdc954e7399e9ADA2661cdddb8D4C19c19E070A8E"
        },
        farm: {
          farmAddress: "",
          farmNickname: "pNearpadLP MODA/PAD",
          farmDepositTokenName: "pNearpadLP MODA/PAD",
        },
    };
    JAR_DEFINITIONS.push(JAR_NEARPAD_MODA_PAD);
    
export const JAR_NEARPAD_DAI_PAD: JarDefinition = {
        type: AssetType.JAR,
        id: "auroraJar 3h",
        contract: "0x384d0a6Bb447A916a42b664C06D5F1E711e8014f",
        startBlock: 64189372,
        depositToken: {
          addr: "0xaf3f197Ce82bf524dAb0e9563089d443cB950048",
          name: "NearpadLP DAI/PAD",
          link: "https://pad.fi/dex/add/0xaf3f197Ce82bf524dAb0e9563089d443cB950048",
          components: ["dai", "pad"],
        },
        rewardTokens: ["pad"],
        enablement: AssetEnablement.ENABLED,
        chain: ChainNetwork.Aurora,
        protocol: AssetProtocol.NEARPAD,
        details: {
          apiKey: "NEARPADLP-DAI-PAD",
          harvestStyle: HarvestStyle.CUSTOM,
          controller: "0xdc954e7399e9ADA2661cdddb8D4C19c19E070A8E"
        },
        farm: {
          farmAddress: "",
          farmNickname: "pNearpadLP DAI/PAD",
          farmDepositTokenName: "pNearpadLP DAI/PAD",
        },
    };
    JAR_DEFINITIONS.push(JAR_NEARPAD_DAI_PAD);
    
export const JAR_NEARPAD_PAD_AURORA: JarDefinition = {
        type: AssetType.JAR,
        id: "auroraJar 3i",
        contract: "0x655552A4c0138dc92a997A16B7a3C10373DfC6a0",
        startBlock: 64189815,
        depositToken: {
          addr: "0xFE28a27a95e51BB2604aBD65375411A059371616",
          name: "NearpadLP PAD/AURORA",
          link: "https://pad.fi/dex/add/0xFE28a27a95e51BB2604aBD65375411A059371616",
          components: ["pad", "aurora"],
        },
        rewardTokens: ["pad"],
        enablement: AssetEnablement.ENABLED,
        chain: ChainNetwork.Aurora,
        protocol: AssetProtocol.NEARPAD,
        details: {
          apiKey: "NEARPADLP-PAD-AURORA",
          harvestStyle: HarvestStyle.CUSTOM,
          controller: "0xdc954e7399e9ADA2661cdddb8D4C19c19E070A8E"
        },
        farm: {
          farmAddress: "",
          farmNickname: "pNearpadLP PAD/AURORA",
          farmDepositTokenName: "pNearpadLP PAD/AURORA",
        },
    };
    JAR_DEFINITIONS.push(JAR_NEARPAD_PAD_AURORA);
    
export const JAR_NEARPAD_PAD_ROSE: JarDefinition = {
        type: AssetType.JAR,
        id: "auroraJar 3j",
        contract: "0x4d3a0c9CECF85d34E08b834BeA096bAA58bBB4b8",
        startBlock: 64190315,
        depositToken: {
          addr: "0xC6C3cc84EabD4643C382C988fA2830657fc70a6B",
          name: "NearpadLP PAD/ROSE",
          link: "https://pad.fi/dex/add/0xC6C3cc84EabD4643C382C988fA2830657fc70a6B",
          components: ["pad", "rose"],
        },
        rewardTokens: ["pad"],
        enablement: AssetEnablement.ENABLED,
        chain: ChainNetwork.Aurora,
        protocol: AssetProtocol.NEARPAD,
        details: {
          apiKey: "NEARPADLP-PAD-ROSE",
          harvestStyle: HarvestStyle.CUSTOM,
          controller: "0xdc954e7399e9ADA2661cdddb8D4C19c19E070A8E"
        },
        farm: {
          farmAddress: "",
          farmNickname: "pNearpadLP PAD/ROSE",
          farmDepositTokenName: "pNearpadLP PAD/ROSE",
        },
    };
    JAR_DEFINITIONS.push(JAR_NEARPAD_PAD_ROSE);
    
export const JAR_NEARPAD_NEAR_ETH: JarDefinition = {
        type: AssetType.JAR,
        id: "auroraJar 3k",
        contract: "0x2c8051621f793609aFe5f2B43E8e0b90000Be637",
        startBlock: 64190817,
        depositToken: {
          addr: "0x24886811d2d5E362FF69109aed0A6EE3EeEeC00B",
          name: "NearpadLP NEAR/ETH",
          link: "https://pad.fi/dex/add/0x24886811d2d5E362FF69109aed0A6EE3EeEeC00B",
          components: ["near", "eth"],
        },
        rewardTokens: ["pad"],
        enablement: AssetEnablement.ENABLED,
        chain: ChainNetwork.Aurora,
        protocol: AssetProtocol.NEARPAD,
        details: {
          apiKey: "NEARPADLP-NEAR-ETH",
          harvestStyle: HarvestStyle.CUSTOM,
          controller: "0xdc954e7399e9ADA2661cdddb8D4C19c19E070A8E"
        },
        farm: {
          farmAddress: "",
          farmNickname: "pNearpadLP NEAR/ETH",
          farmDepositTokenName: "pNearpadLP NEAR/ETH",
        },
    };
    JAR_DEFINITIONS.push(JAR_NEARPAD_NEAR_ETH);
    
export const JAR_NEARPAD_NEAR_FRAX: JarDefinition = {
        type: AssetType.JAR,
        id: "auroraJar 3l",
        contract: "0x8AAfB1fEDbFc327c02b2E6ac0163F377B9f37C35",
        startBlock: 64191263,
        depositToken: {
          addr: "0xac187A18f9DaB50506fc8111aa7E86F5F55DefE9",
          name: "NearpadLP NEAR/FRAX",
          link: "https://pad.fi/dex/add/0xac187A18f9DaB50506fc8111aa7E86F5F55DefE9",
          components: ["near", "frax"],
        },
        rewardTokens: ["pad"],
        enablement: AssetEnablement.ENABLED,
        chain: ChainNetwork.Aurora,
        protocol: AssetProtocol.NEARPAD,
        details: {
          apiKey: "NEARPADLP-NEAR-FRAX",
          harvestStyle: HarvestStyle.CUSTOM,
          controller: "0xdc954e7399e9ADA2661cdddb8D4C19c19E070A8E"
        },
        farm: {
          farmAddress: "",
          farmNickname: "pNearpadLP NEAR/FRAX",
          farmDepositTokenName: "pNearpadLP NEAR/FRAX",
        },
    };
    JAR_DEFINITIONS.push(JAR_NEARPAD_NEAR_FRAX);
    
export const JAR_NEARPAD_PAD_TRI: JarDefinition = {
        type: AssetType.JAR,
        id: "auroraJar 3m",
        contract: "0x94da4471aa1fc15053E2A1c5991136A895CD66fB",
        startBlock: 64191709,
        depositToken: {
          addr: "0x50F63D48a52397C1a469Ccd057905CC8d2609B85",
          name: "NearpadLP PAD/TRI",
          link: "https://pad.fi/dex/add/0x50F63D48a52397C1a469Ccd057905CC8d2609B85",
          components: ["pad", "tri"],
        },
        rewardTokens: ["pad"],
        enablement: AssetEnablement.ENABLED,
        chain: ChainNetwork.Aurora,
        protocol: AssetProtocol.NEARPAD,
        details: {
          apiKey: "NEARPADLP-PAD-TRI",
          harvestStyle: HarvestStyle.CUSTOM,
          controller: "0xdc954e7399e9ADA2661cdddb8D4C19c19E070A8E"
        },
        farm: {
          farmAddress: "",
          farmNickname: "pNearpadLP PAD/TRI",
          farmDepositTokenName: "pNearpadLP PAD/TRI",
        },
    };
    JAR_DEFINITIONS.push(JAR_NEARPAD_PAD_TRI);
    
export const JAR_WANNASWAP_WANNAX_STNEAR: JarDefinition = {
        type: AssetType.JAR,
        id: "auroraJar 2o",
        contract: "0x9f8FD72D1B49A9eff1601a38eA540c0bcE7E6Feb",
        startBlock: 64261713,
        depositToken: {
          addr: "0xE22606659ec950E0328Aa96c7f616aDC4907cBe3",
          name: "WannaswapLP WANNAX/STNEAR",
          link: "https://wannaswap.finance/exchange/add/0xE22606659ec950E0328Aa96c7f616aDC4907cBe3",
          components: ["wannax", "stnear"],
        },
        rewardTokens: ["wanna"],
        enablement: AssetEnablement.ENABLED,
        chain: ChainNetwork.Aurora,
        protocol: AssetProtocol.WANNASWAP,
        details: {
          apiKey: "WANNASWAPLP-WANNAX-STNEAR",
          harvestStyle: HarvestStyle.CUSTOM,
          controller: "0xdc954e7399e9ADA2661cdddb8D4C19c19E070A8E"
        },
        farm: {
          farmAddress: "",
          farmNickname: "pWannaswapLP WANNAX/STNEAR",
          farmDepositTokenName: "pWannaswapLP WANNAX/STNEAR",
        },
    };
    JAR_DEFINITIONS.push(JAR_WANNASWAP_WANNAX_STNEAR);
    
export const JAR_WANNASWAP_WANNAX_STNEAR: JarDefinition = {
        type: AssetType.JAR,
        id: "auroraJar 2o",
        contract: "0x527F243112Cc6DE5A9879c93c2091C23E9a3afa5",
        startBlock: 64263363,
        depositToken: {
          addr: "0xE22606659ec950E0328Aa96c7f616aDC4907cBe3",
          name: "WannaswapLP WANNAX/STNEAR",
          link: "https://wannaswap.finance/exchange/add/0xE22606659ec950E0328Aa96c7f616aDC4907cBe3",
          components: ["wannax", "stnear"],
        },
        rewardTokens: ["wanna"],
        enablement: AssetEnablement.ENABLED,
        chain: ChainNetwork.Aurora,
        protocol: AssetProtocol.WANNASWAP,
        details: {
          apiKey: "WANNASWAPLP-WANNAX-STNEAR",
          harvestStyle: HarvestStyle.CUSTOM,
          controller: "0xdc954e7399e9ADA2661cdddb8D4C19c19E070A8E"
        },
        farm: {
          farmAddress: "",
          farmNickname: "pWannaswapLP WANNAX/STNEAR",
          farmDepositTokenName: "pWannaswapLP WANNAX/STNEAR",
        },
    };
    JAR_DEFINITIONS.push(JAR_WANNASWAP_WANNAX_STNEAR);
    
export const JAR_AURORA_TRISOLARIS_NEAR_USDT_LP: JarDefinition = {
        type: AssetType.JAR,
        id: "auroraJar 1ab",
        contract: "0x372d3dBE547f220311Ac996998B18eB287251644",
        startBlock: 64899522,
        depositToken: {
          addr: "0x03B666f3488a7992b2385B12dF7f35156d7b29cD",
          name: "TrisolarisLP NEAR/USDT",
          link: "https://www.trisolaris.io/#/pool0x03B666f3488a7992b2385B12dF7f35156d7b29cD",
          components: ["near", "usdt"],
        },
        rewardTokens: ["tri"],
        enablement: AssetEnablement.ENABLED,
        chain: ChainNetwork.Aurora,
        protocol: AssetProtocol.TRISOLARIS,
        details: {
          apiKey: "TRISOLARISLP-NEAR-USDT",
          harvestStyle: HarvestStyle.PASSIVE,
          controller: "0xdc954e7399e9ADA2661cdddb8D4C19c19E070A8E"
        },
        farm: {
          farmAddress: NULL_ADDRESS,
          farmNickname: "pTrisolarisLP NEAR/USDT",
          farmDepositTokenName: "pTrisolarisLP NEAR/USDT",
        },
    };
    JAR_DEFINITIONS.push(JAR_AURORA_TRISOLARIS_NEAR_USDT);
    