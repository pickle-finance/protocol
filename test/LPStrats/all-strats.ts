import { doStrategyTest } from "./../strategy-test";
import { TestableStrategy, LPTestDefault } from "./../strategy-test-case";


const tests = [
    // {
    //   name: "PngAvaxPng",
    //   controller: "",
    //   snowglobeAddress: "0x621207093D2e65Bf3aC55dD8Bf0351B980A63815",
    // },
    // {
    //   name: "PngSnobPng",
    //   controller: "backup",
    //   snowglobeAddress: "0xB4db531076494432eaAA4C6fCD59fcc876af2734",
    // },
    // {
    //   name: "PngAvaxSnob",
    //   controller: "backup",
    //   snowglobeAddress: "0xF4072358C1E3d7841BD7AfDE31F61E17E8d99BE7",
    // },
    // {
    //   name: "PngAvaxVso",
    //   controller: "",
    //   snowglobeAddress: "0x888Ab4CB2279bDB1A81c49451581d7c243AffbEf",
    // },
    // {
    //   name: "PngVsoPng",
    //   controller: "",
    //   snowglobeAddress: "0x8309C64390F376fD778BDd701d54d1F8DFfe1F39",
    // },
    // {
    //   name: "PngAvaxSpore",
    //   controller: "",
    //   snowglobeAddress: "0x27f8FE86a513bAAF18B59D3dD15218Cc629640Fc",
    // },
    // {
    //   name: "PngSporePng",
    //   controller: "",
    //   snowglobeAddress: "", // 0xa39785a4E4CdDa7509751ed152a00f3D37FbFa9F
    // },
    // {
    //   name: "JoeAvaxGb",
    // },
    // {
    //   name: "PngAvaxGb",
    // },
    // {
    //   name: "PngAvaxShibx",
    // },
    // {
    //   name: "PngAvaxSpore",
    // },
    // {
    //   name: "PngAvaxBnb",
    //   controller: "",
    //   snowglobeAddress: "0x39BF214A93EC72e42bC0B9b8C07BE1af6Fe169dA",
    // },
    // {
    //   name: "PngXavaPng",
    //   controller: "",
    //   snowglobeAddress: "0xF23c55a05C9f24177FFF5934e8192461AeE4f304",
    // },
    // {
    //   name: "PngAvaxXava",
    //   controller: "",
    //   snowglobeAddress: "0x6AB8DAC517c244f53D86a155a14064E86c2dE653",
    // },
    // {
    //   name: "PngAvaxPefi",
    //   controller: "",
    //   snowglobeAddress: "0x5fb4d08bCBD444fDD5a0545fdB0C86783D186382",
    // },
    // {
    //   name: "PngPefiPng",
    //   controller: "",
    //   snowglobeAddress: "0xf5b4Ba166b8b351C0dF92BdD6bf7d46d537185fB",
    // },
    // {
    //   name: "PngAvaxSherpa",
    //   controller: "",
    //   snowglobeAddress: "0x5B8eE2c0a4f249e16f26d31636F1ed79df5405f9",
    // },
    // {
    //   name: "PngAvaxTryb",
    //   controller: "",
    //   snowglobeAddress: "0xEb1010B9CF8484fcA2650525d477DD002fa889cE",
    // },
    // {
    //   name: "PngAvaxUsdtE",
    //   controller: "",
    //   snowglobeAddress: "0x7CC8068AB5FC2D8c843C4b1A6572a1d1E742D7c8",
    // },
    // {
    //   name: "PngAvaxDaiE",
    //   controller: "",
    //   snowglobeAddress: "0x56A6e103D860FBb991eF1Afd24250562a292b2a5",
    // },
    // {
    //   name: "PngAvaxSushiE",
    //   controller: "",
    //   snowglobeAddress: "0x5cce813cd2bBbA5aEe6fddfFAde1D3976150b860",
    // },
    // {
    //   name: "PngAvaxLinkE",
    //   controller: "",
    //   snowglobeAddress: "0x08D5Cfaf58a10D306937aAa8B0d2eb40466f7461",
    // },
    // {
    //   name: "PngAvaxWbtcE",
    //   controller: "",
    //   snowglobeAddress: "0x04A3B139fcD004b2A4f957135a3f387124982133",
    // },
    // {
    //   name: "PngAvaxEthE",
    //   controller: "",
    //   snowglobeAddress: "0xfEC005280ec0870A5dB1924588aE532743CEb90F",
    // },
    // {
    //   name: "PngAvaxYfiE",
    //   controller: "",
    //   snowglobeAddress: "0x2ad520b64e6058654FE6E67bc790221772b63ecE",
    // },
    // {
    //   name: "PngAvaxUniE",
    //   controller: "",
    //   snowglobeAddress: "0xf2596c84aCf1c7350dCF6941604DEd359dD506DB",
    // },
    // {
    //   name: "PngAvaxAaveE",
    //   controller: "",
    //   snowglobeAddress: "0x7F8E7a8Bd63A113B202AE905877918Fb9cA13091",
    // },
    // {
    //   name: "PngUsdtEPng",
    //   controller: "",
    //   snowglobeAddress: "0xb3DbF3ff266a604A66dbc1783257377239792828",
    // },
    // {
    //   name: "PngDaiEPng",
    //   controller: "",
    //   snowglobeAddress: "0x45981aB8cE749466c1d2022F50e24AbBEE71d15A",
    // },
    // {
    //   name: "PngLinkEPng",
    //   controller: "",
    //   snowglobeAddress: "0x92f75Da67c5E647D86A56a5a3D6C9a25e887504A",
    // },
    // {
    //   name: "PngWbtcEPng",
    //   controller: "",
    //   snowglobeAddress: "0x857f9A61C97d175EaE9E0A8bb74CF701d45a18dc",
    // },
    // {
    //   name: "PngEthEPng",
    //   controller: "",
    //   snowglobeAddress: "0xEC7dA05C3FA5612f708378025fe1C0e1904aFbb5",
    // },
    // {
    //   name: "PngAvaxYak",
    //   controller: "",
    //   snowglobeAddress: "0x1BF90bdeb965a76Af56024EF3e70439DEa89bF3f",
    // },
    // {
    //   name: "PngYakPng",
    //   controller: "",
    //   snowglobeAddress: "0xA829397Af2AdD7C6564a74DC072b3D9095581d70",
    // },
    // {
    //   name: "PngAvaxQi",
    //   controller: "",
    //   snowglobeAddress: "0xeEc21abC6daD38A8515a7C3388E5ef962Cd960e6",
    // },
    // {
    //   name: "PngQiPng",
    //   controller: "",
    //   snowglobeAddress: "0x9EC50ee696bB1c6f8f4e2181f61ad687700005cF",
    // },
    // {
    //   name: "PngAvaxDyp",
    //   controller: "",
    //   snowglobeAddress: "0xf4a591BeaC3A4D864C3293477bBD3f86880ADa16",
    // },
    // {
    //   name: "PngAvaxWalbt",
    //   controller: "",
    //   snowglobeAddress: "0x322094FDB02677E7a993E735826c9E183fc605a6",
    // },
    // {
    //   name: "PngAvaxUsdcE",
    //   controller: "",
    //   snowglobeAddress: "0xd63359ff51BF1217730ae2C37979242B1a3f7c53",
    // },
    // {
    //   name: "PngUsdcEPng",
    //   controller: "",
    //   snowglobeAddress: "0x39259A07C7B21189BF1bC2Bd75967565b3C1F16e",
    // },
    // {
    //   name: "PngUsdcEUsdtE",
    //   controllerAddress: "",
    //   snowglobeAddress: "",
    // },
    // {
    //   name: "PngAvaxTusd",
    //   controller: "",
    //   snowglobeAddress: "0xfe1A87Cc4a2144f7eBb7d731bE80bF0e4CC6E909",
    // },
    // {
    //   name: "PngAvaxLyd",
    //   controller: "",
    //   snowglobeAddress: "0x3F2b777d055dbD4D0812f3750Ee71190431D3Fc8",
    // },
    // {
    //   name: "PngAvaxHusky",
    //   controller: "",
    //   snowglobeAddress: "0x150Bc67072c2dB7c55D83302B7dA7D930Eed1c3E",
    // },
    // {
    //   name: "PngAvaxGaj",
    //   controller: "",
    //   snowglobeAddress: "0xa3528E975ed30326e4930c8F70b01F9d9608D8b1",
    // },
    // {
    //   name: "PngAvaxAve",
    //   controller: "",
    //   snowglobeAddress: "0xD579719d3a58492D803c7d60E3565733a4ba3DEa",
    // },
    // {
    //   name: "PngAvePng",
    //   controller: "",
    //   snowglobeAddress: "0x2B30b282405C3ee946843901dDbEc1a82562a1fC",
    // },
    // {
    //   name: "PngAvaxEle",
    //   controller: "",
    //   snowglobeAddress: "0x096bAE6C45b0047eF3F1cf1f1c8a56eF0cd58cdE",
    // },
    // {
    //   name: "PngAvaxGdl",
    //   controller: "",
    //   snowglobeAddress: "0x342476c1F9436277acBC088788D0De53b8b34106",
    // },
    // {
    //   name: "PngAvaxMfi",
    //   controller: "",
    //   snowglobeAddress: "0x2F2Ba207f86b46b05a1c79e50b9f980e267719B8",
    // },
    // {
    //   name: "PngMfiPng",
    //   controller: "",
    //   snowglobeAddress: "0x51B03A4A57da8ea9FC4549d1C54f6ccd678e2892",
    // },
    // {
    //   name: "PngAvaxFrax",
    //   controller: "",
    //   snowglobeAddress: "0xD0686AC7d0CfFd00A29567D37774058452210D57",
    // },
    // {
    //   name: "PngAvaxFxs",
    //   controller: "",
    //   snowglobeAddress: "0x07E837D2ae3F2fB565ABdAa80797d47412FC3a94",
    // },
    // {
    //   name: "PngAvaxStart",
    //   controller: "",
    //   snowglobeAddress: "0x973509A4e6DfAA2B5753fC8FB4f85F861fFbA8BB",
    // },
    // {
    //   name: "PngAvaxSwap",
    //   controller: "",
    //   snowglobeAddress: "0x7Fc1954FbC383e5c477b81c0E1CFBf3846D0dE10",
    // },
    // {
    //   name: "PngAvaxTundra",
    //   controller: "",
    //   snowglobeAddress: "0x05Bba89E406792D2d73d6D4022347c3893b02a20",
    // },
    // {
    //   name: "PngAvaxYts",
    //   controller: "",
    //   snowglobeAddress: "0xee4F816ac2333A346B7B3a76579F0b5342511822",
    // },
    // {
    //   name: "PngAvaxYay",
    //   controller: "",
    //   snowglobeAddress: "0xD7601D15ce8D207Ef01f2e45c6e24Fc5A34c393f",
    // },
    // {
    //   name: "PngAvaxStorm",
    //   controller: "",
    //   snowglobeAddress: "0x86C70CE247Cd76b776748687634382a1830b3aC4",
    // },
    // {
    //   name: "PngAvaxIce",
    //   controller: "",
    //   snowglobeAddress: "0x42c3Fa6514Ac55F0f2CA4E910D897282829c0Ab2",
    // },
    // {
    //   name: "PngAvaxWow",
    //   controller: "",
    //   snowglobeAddress: "0xca26bF455974B85df3Ed9cfdbf0B620D616738BF",
    // },
    // {
    //   name: "PngAvaxTeddy",
    //   controller: "",
    //   snowglobeAddress: "0x42E1CDd48884C9027E965600B4A725a91D27255b",
    // },
    // {
    //   name: "PngAvaxMyak",
    //   controller: "",
    //   snowglobeAddress: "0xc88477DD929837B0e6Aeafeb9Dd2Dd238505E698",
    // },
    // {
    //   name: "PngAvaxApein",
    //   controller: "",
    //   snowglobeAddress: "0x192ae260676Ba79ccc57A6f4Ed692Bfe371658b9",
    // },
    // {
    //   name: "PngAvaxCnr",
    //   controller: "",
    //   snowglobeAddress: "0xEf28DbfDB08c4475f5fA07Ac2aD4B8C1cFE2938a",
    // },
    // {
    //   name: "PngAvaxCycle",
    //   controller: "",
    //   snowglobeAddress: "0x4c885E844283D9FAf10607106963768113342543",
    // },
    // {
    //   name: "PngAvaxBifi",
    //   controller: "",
    //   snowglobeAddress: "0x07e7dF7F0612B7dc6789ba402b17c7108c932d05",
    // },
    // {
    //   name: "PngAvaxRoco",
    //   controller: "",
    //   snowglobeAddress: "0x026402B96A3EBDeaE03B70E4C197D70a8f33B295",
    // },
    // {
    //   name: "PngAvaxFrax",
    //   controller: "",
    //   snowglobeAddress: "",
    // },
    // {
    //   name: "PngAvaxOrca",
    //   controller: "",
    //   snowglobeAddress: "",
    // },
    // {
    //   name: "PngAvaxAvai",
    //   controller: "",
    //   snowglobeAddress: "",
    // },
    // {
    //   name: "PngTusdDaiEMini",
    //   controller: "",
    //   snowglobeAddress: "",
    // },
    // {
    //   name: "PngAvaxMaxi",
    //   controller: "",
    //   snowglobeAddress: "",
    // },
    // {
    //   name: "PngAvaxCraft",
    //   controller: "",
    //   snowglobeAddress: "",
    // },
    // {
    //   name: "PngAvaxCra",
    //   controller: "",
    //   snowglobeAddress: "",
    // },
    // {
    //   name: "PngAvaxJewel",
    //   controller: "",
    //   snowglobeAddress: "",
    // },
    // {
    //   name: "PngAvaxgOhm",
    //   controller: "",
    //   snowglobeAddress: "",
    // },
    // {
    //   name: "PngUsdcEMim",
    //   controller: "",
    //   snowglobeAddress: "",
    // },
    //  {
    //     name: "PngAvaxAmpl",
    //     controllerAddress: "",
    //     snowglobeAddress: "",
    // }, 
    // {
    //     name: "PngAvaxCly",
    //     controller: "",
    //     snowglobeAddress: "",
    //   },      
    // {
    //   name: "PngUsdteSkill",
    //   controller: "",
    //   snowglobeAddress: "",
    // },
    // {
    //   name: "PngAvaxCook",
    //   controller: "",
    //   snowglobeAddress: "",
    // },
    //   {
    //   name: "PngAvaxHct",
    //   controllerAddress: "",
    //   snowglobeAddress: "",
    // },
    // {
    //   name: "PngAvaxImxa",
    //   controllerAddress: "",
    //   snowglobeAddress: "",
    // },
    //   {
    //   name: "PngAvaxInsur",
    //   controllerAddress: "",
    //   snowglobeAddress: "",
    // },
    // {
    //   name: "PngAvaxJoe",
    //   controllerAddress: "",
    //   snowglobeAddress: "",
    // },
    // {
    //   name: "PngAvaxKlo",
    //   controllerAddress: "",
    //   snowglobeAddress: "",
    // },
    // {
    //   name: "PngAvaxOoe",
    //   controllerAddress: "",
    //   snowglobeAddress: "",
    // },
    // {
    //   name: "PngAvaxOrbs",
    //   controllerAddress: "",
    //   snowglobeAddress: "",
    // },
    // {
    //   name: "PngAvaxSpell",
    //   controllerAddress: "",
    //   snowglobeAddress: "",
    // },
    //  {
    //   name: "PngAvaxTime",
    //   controllerAddress: "",
    //   snowglobeAddress: "",
    // },
    //  {
    //   name: "PngAvaxVee",
    //   controllerAddress: "",
    //   snowglobeAddress: "",
    // },
    // {
    //   name: "PngAvaxWethE",
    //   controllerAddress: "",
    //   snowglobeAddress: "",
    // },
    //  {
    //   name: "PngUsdcEDaiE",
    //   controllerAddress: "",
    //   snowglobeAddress: "",
    // },
    // {
    //   name: "JoeAvaxPng",
    //   controller: "",
    //   snowglobeAddress: "0x962ECf51A169090002CC88B4Bf16e447d2E13100",
    // },
    // {
    //   name: "JoeAvaxJoe",
    //   controller: "",
    //   snowglobeAddress: "0xcC757081C972D0326de42875E0DA2c54af523622",
    // },
    // {
    //   name: "JoeAvaxSnob",
    //   controller: "",
    //   snowglobeAddress: "0x8b2E1802A7E0E0c7e1EaE8A7c636058964e21047",
    // },
    // {
    //   name: "JoeAvaxXava",
    //   controller: "",
    //   snowglobeAddress: "0x0B2C4f6C54182EDeE30DFF69Be972f9E04888321",
    // },
    // {
    //   name: "JoeAvaxPefi",
    //   controller: "",
    //   snowglobeAddress: "0x68691a1e8eAAE3dFDcC300BbC0d6D3902bA06E8d",
    // },
    // {
    //   name: "JoeAvaxElk",
    //   controller: "",
    //   snowglobeAddress: "0x6440365E1c9282F50477b1F00289b3A7218E47Ef",
    // },
    // {
    //   name: "JoeAvaxVso",
    //   controller: "",
    //   snowglobeAddress: "0xFB3ba5884aD5eBD93C7CB095e4cE08B1C365c2ea",
    // },
    // {
    //   name: "JoeAvaxSherpa",
    //   controller: "",
    //   snowglobeAddress: "0x75312b14Ce830EC078D93Ac8FA667b14BEAC18E6",
    // },
    // {
    //   name: "JoeAvaxYak",
    //   controller: "",
    //   snowglobeAddress: "0x9854F6615f73e533940F90FfE8DB1eAFB424A3c7",
    // },
    // {
    //   name: "JoeUsdteJoe",
    //   controller: "",
    //   snowglobeAddress: "0xB26A7f2bCA1De2E6BFf411D2ce04ca6C3285e0E8",
    // },
    // {
    //   name: "JoeAvaxEthE",
    //   controller: "",
    //   snowglobeAddress: "0xe13E1a491eDc640b0591D70390897620f31bbF6E",
    // },
    // {
    //   name: "JoeAvaxWbtcE",
    //   controller: "",
    //   snowglobeAddress: "0x5c52587bD441A6e6916D2C2d32A84735b9Ee4ccD",
    // },
    // {
    //   name: "JoeAvaxUsdtE",
    //   controller: "",
    //   snowglobeAddress: "0xc72901E3dBE5258728B329352fC4742f4966Bc1f",
    // },
    // {
    //   name: "JoeAvaxLinkE",
    //   controller: "",
    //   snowglobeAddress: "0xfAa4f21A8Ef346370d00F1a7693FdC5D87C3e12a",
    // },
    // {
    //   name: "JoeUsdtEDaiE",
    //   controller: "",
    //   snowglobeAddress: "0xfe19f34873fC2C7ddcB8e392791b97526B4d22e0",
    // },
    // {
    //   name: "JoeWbtcEUsdtE",
    //   controller: "",
    //   snowglobeAddress: "0x6941618661205d5AAd2C880A0B123d19615916b0",
    // },
    // {
    //   name: "JoeUsdtEEthE",
    //   controller: "",
    //   snowglobeAddress: "0x67b2D2579E631512faFbB1534214eA2D3403563B",
    // },
    // {
    //   name: "JoeUsdtELinkE",
    //   controller: "",
    //   snowglobeAddress: "0x0666B3db2441A50B6a1C1d330d2f36Df18Ad5651",
    // },
    // {
    //   name: "JoeAvaxUsdcE",
    //   controller: "",
    //   snowglobeAddress: "0xf25f6f5dad18a16033d05c1f2F558119665fDEF4",
    // },
    // {
    //   name: "JoeDaiEUsdcE",
    //   controller: "",
    //   snowglobeAddress: "0x6C915564607d62B007D203c04473152bc090EE93",
    // },
    // {
    //   name: "JoeAvaxQi",
    //   controller: "",
    //   snowglobeAddress: "0x9937dD4aaaCfD77BD34a88f9282fAe36fAE364f9",
    // },
    // {
    //   name: "JoeAvaxMim",
    //   controller: "",
    //   snowglobeAddress: "0xf561EAE92039ab1540a75FDFD50ce8C6800bC078",
    // },
    // {
    //   name: "JoeAvaxTime",
    //   controller: "",
    //   snowglobeAddress: "0x3AF37B647a08D443ef08Aff8cDdeAE33bBa56779",
    // },
    // {
    //   name: "JoeAvaxFrax",
    //   controller: "",
    //   snowglobeAddress: "0x8ba8d732109A4eE78b0F8976B21FC88009280bd7",
    // },
    // {
    //   name: "JoeAvaxSyn",
    //   controller: "",
    //   snowglobeAddress: "0x810CF29576E61695BA7Fe1e4D493663185691854",
    // },
    // {
    //   name: "JoeAvaxEle",
    //   controller: "",
    //   snowglobeAddress: "0xD865B861365c777b3942122933Ff6F8aD1cD28E3",
    // },
    // {
    //   name: "JoeAvaxWet",
    //   controller: "",
    //   snowglobeAddress: "0x34B5f24Ab10A36Cf1e82ea95c9C611162D6e3f60",
    // },
    // {
    //   name: "JoeUsdtEUsdcE",
    //   controller: "",
    //   snowglobeAddress: "0xd596136ee746BaeE7ac159B3c21E71b3aeb81A68",
    // },
    // {
    //   name: "JoeAvaxSpell",
    //   controller: "",
    //   snowglobeAddress: "0xec54A22B53EE66a77C5F26F860c6913472199661",
    // },
    // {
    //   name: "JoeUsdcEMai",
    //   controller: "",
    //   snowglobeAddress: "0x81Be7fBF66cF52A5cC6AD77f32361C5F3BBDAAd8",
    // },
    // {
    //   name: "JoeAvaxAavee",
    //   controller: "",
    //   snowglobeAddress: "0xE7FfFc0D15fc238F8F1AcC40Db5B5A0240Fb116a",
    // },
    // {
    //   name: "JoeAvaxBifi",
    //   controller: "",
    //   snowglobeAddress: "0xb58fA0e89b5a32E3bEeCf6B16704cabF8471F0E1",
    // },
    // {
    //   name: "JoeAvaxBnb",
    //   controller: "",
    //   snowglobeAddress: "0xc33b19c3d166CcD844aeDC475A989F5C0FC79E43",
    // },
    // {
    //   name: "JoeAvaxChart",
    //   controller: "",
    //   snowglobeAddress: "0x916aEbEE43E2bE7ed126A21208db4092392d80AD",
    // },
    //  {
    //    name: "JoeAvaxKlo",
    //    controller: "",
    //    snowglobeAddress: "0xf6E8432EF7d85Ae1202Dc537106D3696eBB27769",
    //  },
    // {
    //   name: "JoeAvaxMai",
    //   controller: "",
    //   snowglobeAddress: "",
    // },
    // {
    //   name: "JoeAvaxMyak",
    //   controller: "",
    //   snowglobeAddress: "0xb81159B533F517f0E36978b7b8e9E8409fb9C169",
    // },
    // {
    //   name: "JoeAvaxRelay",
    //   controller: "",
    //   snowglobeAddress: "0x8C4185D7303c7865a45B46d705F40a8FAAd43Add",
    // },
    // {
    //   name: "JoeAvaxTeddy",
    //   controller: "",
    //   snowglobeAddress: "0xb357bA896818ccCd020fb3781a443E3d3f93beFf",
    // },
    // {
    //   name: "JoeAvaxTsd",
    //   controller: "",
    //   snowglobeAddress: "0xcEBFFa4C80291e80EA0684E4C8884124d6a81197",
    // },
    // {
    //   name: "JoeUsdceLinke",
    //   controller: "",
    //   snowglobeAddress: "0xc28F8a82018c0b92C903Fc2D3013381b7e6ae3d5",
    // },
    // {
    //   name: "JoeUsdceEthe",
    //   controller: "",
    //   snowglobeAddress: "0x5586630339C015dF34EAB3Ae0343D37BE89671f9",
    // },
    // {
    //   name: "JoeUsdceJoe",
    //   controller: "",
    //   snowglobeAddress: "0xDe9f979fEdf595FcfD1D09c85d194C700678cC83",
    // },
    // {
    //   name: "JoeUsdceWbtce",
    //   controller: "",
    //   snowglobeAddress: "0xAFB27fB1c5bd91A80d18A321D6dC09aDd6a94219",
    // },
    //   {
    //     name: "JoeAvaxRoco",
    //     controller: "",
    //     snowglobeAddress: "",
    //   },
    // {
    //   name:"JoeAvaxAmpl",
    //   controller: "",
    //   snowglobeAddress: "",
    // },
    // {
    //   name:"JoeAvaxOh",
    //   controller: "",
    //   snowglobeAddress: "",
    // },
    // {
    //   name: "JoeAvaxIce",
    //   controller: "",
    //   snowglobeAddress: "",
    // },
    // {
    //   name: "JoeAvaxApex",
    //   controller: "",
    //   snowglobeAddress: "",
    // },
    // {
    //   name: "JoeAvaxTractor",
    //   controller: "",
    //   snowglobeAddress: "",
    // },
    // {
    //   name: "AxialAvaxAxial",
    //   controller: "",
    //   snowglobeAddress: "",
    // },
    // {
    //   name: "AxialAA3D",
    //   controller: "",
    //   snowglobeAddress: "",
    //   slot: 51
    // },
    {
      name: "AxialAC4D",
      controllerAddress: "0xc7D536a04ECC43269B6B95aC1ce0a06E0000D095",
      slot: 51,
    },
    {
        name: "AxialAM3D",
        controller: "main",
        timelockIsStrategist: false,
        slot: 51
    },
    {
        name: "JoeAvaxEgg",
        controller: "bankerJoe",
        slot: 1,
        lp_suffix: false,
        timelockIsStrategist: true,
    },
    {
        name: "JoeAvaxPln",
        controllerAddress: "",
        snowglobeAddress: "",
    },

];

describe("All LP test", function() {
    for (const test of tests) {
        let Test: TestableStrategy = { ...LPTestDefault, ...test };
        doStrategyTest(Test);
    }
});
