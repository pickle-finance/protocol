
export const JAR_ROSE_ROSE_FRAX: JarDefinition = {
        type: AssetType.JAR,
        id: "auroraJar 6c",
        contract: "0x566112Ba8Bf50218Ac5D485DcbE0eBF240707D11",
        startBlock: 64255592,
        depositToken: {
          addr: "0xeD4C231b98b474f7cAeCAdD2736e5ebC642ad707",
          name: "RoseLP ROSE/FRAX",
          link: "https://app.rose.fi/#/pools/0xeD4C231b98b474f7cAeCAdD2736e5ebC642ad707",
          components: ["rose", "frax"],
        },
        rewardTokens: ["rose"],
        enablement: AssetEnablement.ENABLED,
        chain: ChainNetwork.Aurora,
        protocol: AssetProtocol.ROSE,
        details: {
          apiKey: "ROSELP-ROSE-FRAX",
          harvestStyle: HarvestStyle.CUSTOM,
          controller: "0xdc954e7399e9ADA2661cdddb8D4C19c19E070A8E"
        },
        farm: {
          farmAddress: "",
          farmNickname: "pRoseLP ROSE/FRAX",
          farmDepositTokenName: "pRoseLP ROSE/FRAX",
        },
    };
    JAR_DEFINITIONS.push(JAR_ROSE_ROSE_FRAX);
    
export const JAR_ROSE_PAD_ROSE: JarDefinition = {
        type: AssetType.JAR,
        id: "auroraJar 6d",
        contract: "0x3F00480fB625Be95abf6c462C84Be1916baF6446",
        startBlock: 64255996,
        depositToken: {
          addr: "0xC6C3cc84EabD4643C382C988fA2830657fc70a6B",
          name: "RoseLP PAD/ROSE",
          link: "https://app.rose.fi/#/pools/0xC6C3cc84EabD4643C382C988fA2830657fc70a6B",
          components: ["pad", "rose"],
        },
        rewardTokens: ["rose"],
        enablement: AssetEnablement.ENABLED,
        chain: ChainNetwork.Aurora,
        protocol: AssetProtocol.ROSE,
        details: {
          apiKey: "ROSELP-PAD-ROSE",
          harvestStyle: HarvestStyle.CUSTOM,
          controller: "0xdc954e7399e9ADA2661cdddb8D4C19c19E070A8E"
        },
        farm: {
          farmAddress: "",
          farmNickname: "pRoseLP PAD/ROSE",
          farmDepositTokenName: "pRoseLP PAD/ROSE",
        },
    };
    JAR_DEFINITIONS.push(JAR_ROSE_PAD_ROSE);
    