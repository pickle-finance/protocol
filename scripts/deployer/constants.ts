
export interface ChainAddresses {
  governance: string;
  strategist: string;
  controller: string;
  timelock: string;
  native: string;
}
enum Chains {
  ARBITRUM = "arbitrum",
  ARBITRUM_V3 = "arbitrumv3",
  OPTIMISM = "optimism",
  OPTIMISM_OLD = "optimism_old",  //old controller
  OPTIMISM_V3 = "optimismv3",   // univ3 controller
  GNOSIS = "gnosis",
  FANTOM_1 = "fantom1",
  FANTOM_2 = "fantom2",
  MATIC = "matic",
  MATIC_V3 = "maticv3",
  MAINNET = "mainnet",
}

export interface DeploymentStateObject {
  [strategyName: string]: {
    name: string;
    strategy?: string;
    jar?: string;
    want?: string;  // this is the pool address for univ3
    wantApproveTx?: string;     // !for univ3
    token0ApproveTx?: string;   // for univ3
    token1ApproveTx?: string;   // for univ3
    token0DepositTx?: string;   // for univ3
    token1DepositTx?: string;   // for univ3
    jarSet?: boolean;
    stratSet?: boolean;
    depositTx?: string;
    earnTx?: string;
    harvestTx?: string;
    rebalanceTx?: string;
  };
}

export type ConstructorArguments = (string | number)[];

export const ADDRESSES: { [key in Chains]: ChainAddresses } = {
  arbitrum: {
    governance: "0xf02CeB58d549E4b403e8F85FBBaEe4c5dfA47c01",
    strategist: "0x4023ef3aaa0669FaAf3A712626F4D8cCc3eAF2e5",
    controller: "0x55D5BCEf2BFD4921B8790525FF87919c2E26bD03",
    timelock: "0xf02CeB58d549E4b403e8F85FBBaEe4c5dfA47c01",
    native: "0x82aF49447D8a07e3bd95BD0d56f35241523fBab1",
  },
  arbitrumv3: {
    governance: "0xf02CeB58d549E4b403e8F85FBBaEe4c5dfA47c01",
    strategist: "0x4023ef3aaa0669FaAf3A712626F4D8cCc3eAF2e5",
    controller: "0xf968f18512A9BdDD9C3a166dd253B24c27a455DD",
    timelock: "0xf02CeB58d549E4b403e8F85FBBaEe4c5dfA47c01",
    native: "0x82aF49447D8a07e3bd95BD0d56f35241523fBab1",
  },
  optimism_old: {
    governance: "0x7A79e2e867d36a91Bb47e0929787305c95E793C5",
    strategist: "0x4023ef3aaa0669FaAf3A712626F4D8cCc3eAF2e5",
    controller: "0xA1D43D97Fc5F1026597c67805aA02aAe558E0FeF",
    timelock: "0x7A79e2e867d36a91Bb47e0929787305c95E793C5",
    native: "0x4200000000000000000000000000000000000006",
  },
  optimism: {
    governance: "0x7A79e2e867d36a91Bb47e0929787305c95E793C5",
    strategist: "0x4023ef3aaa0669FaAf3A712626F4D8cCc3eAF2e5",
    controller: "0xeEDeF926D3d7C9628c8620B5a018c102F413cDB7",
    timelock: "0x7A79e2e867d36a91Bb47e0929787305c95E793C5",
    native: "0x4200000000000000000000000000000000000006",
  },
  optimismv3: {
    governance: "0x7A79e2e867d36a91Bb47e0929787305c95E793C5",
    strategist: "0x4023ef3aaa0669FaAf3A712626F4D8cCc3eAF2e5",
    controller: "0xa936511d24F9488Db343AfDdccBf78AD28bd3F42",
    timelock: "0x7A79e2e867d36a91Bb47e0929787305c95E793C5",
    native: "0x4200000000000000000000000000000000000006",
  },
  gnosis: {
    governance: "0x986e64622FFB6b95B0bE00076051807433258B46",
    strategist: "0x4023ef3aaa0669FaAf3A712626F4D8cCc3eAF2e5",
    controller: "0xe5E231De20C68AabB8D669f87971aE57E2AbF680",
    timelock: "0x986e64622FFB6b95B0bE00076051807433258B46",
    native: "0xe91D153E0b41518A2Ce8Dd3D7944Fa863463a97d",
  },
  fantom1: {
    governance: "0xE4ee7EdDDBEBDA077975505d11dEcb16498264fB",
    strategist: "0x4023ef3aaa0669FaAf3A712626F4D8cCc3eAF2e5",
    controller: "0xB1698A97b497c998b2B2291bb5C48D1d6075836a",
    timelock: "0xE4ee7EdDDBEBDA077975505d11dEcb16498264fB",
    native: "0x21be370D5312f44cB42ce377BC9b8a0cEF1A4C83",
  },
  fantom2: {
    governance: "0xE4ee7EdDDBEBDA077975505d11dEcb16498264fB",
    strategist: "0x4023ef3aaa0669FaAf3A712626F4D8cCc3eAF2e5",
    controller: "0xc335740c951F45200b38C5Ca84F0A9663b51AEC6",
    timelock: "0xE4ee7EdDDBEBDA077975505d11dEcb16498264fB",
    native: "0x21be370D5312f44cB42ce377BC9b8a0cEF1A4C83",
  },
  matic: {
    governance: "0xEae55893cC8637c16CF93D43B38aa022d689Fa62",
    strategist: "0x4023ef3aaa0669FaAf3A712626F4D8cCc3eAF2e5",
    controller: "0x83074F0aB8EDD2c1508D3F657CeB5F27f6092d09",
    timelock: "0xEae55893cC8637c16CF93D43B38aa022d689Fa62",
    native: "0x0d500B1d8E8eF31E21C99d1Db9A6444d3ADf1270",
  },
  maticv3: {
    governance: "0xEae55893cC8637c16CF93D43B38aa022d689Fa62",
    strategist: "0x4023ef3aaa0669FaAf3A712626F4D8cCc3eAF2e5",
    controller: "0x90Ee5481A78A23a24a4290EEc42E8Ad0FD3B4AC3",
    timelock: "0xEae55893cC8637c16CF93D43B38aa022d689Fa62",
    native: "0x0d500B1d8E8eF31E21C99d1Db9A6444d3ADf1270",
  },
  mainnet: {
    governance: "0x9d074E37d408542FD38be78848e8814AFB38db17",
    strategist: "0x4023ef3aaa0669FaAf3A712626F4D8cCc3eAF2e5",
    controller: "0x6847259b2B3A4c17e7c43C54409810aF48bA5210",
    timelock: "0xD92c7fAa0Ca0e6AE4918f3a83d9832d9CAEAA0d3",
    native: "0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2",
  },
};

export const OBJECT_FILE_NAME: string = "deployment-state-object.json"; // deployment state object file name
export const CONTROLLERV4_CONTRACT = "src/controller-v4.sol:ControllerV4";
export const JAR_CONTRACT = "src/pickle-jar.sol:PickleJar";
