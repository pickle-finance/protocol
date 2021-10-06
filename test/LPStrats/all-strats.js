const {doLPStrategyTest} = require("../lp-strategy-test");

const globeABI = [{"type":"constructor","stateMutability":"nonpayable","inputs":[{"type":"address","name":"_token","internalType":"address"},{"type":"address","name":"_governance","internalType":"address"},{"type":"address","name":"_timelock","internalType":"address"},{"type":"address","name":"_controller","internalType":"address"}]},{"type":"event","name":"Approval","inputs":[{"type":"address","name":"owner","internalType":"address","indexed":true},{"type":"address","name":"spender","internalType":"address","indexed":true},{"type":"uint256","name":"value","internalType":"uint256","indexed":false}],"anonymous":false},{"type":"event","name":"Transfer","inputs":[{"type":"address","name":"from","internalType":"address","indexed":true},{"type":"address","name":"to","internalType":"address","indexed":true},{"type":"uint256","name":"value","internalType":"uint256","indexed":false}],"anonymous":false},{"type":"function","stateMutability":"view","outputs":[{"type":"uint256","name":"","internalType":"uint256"}],"name":"allowance","inputs":[{"type":"address","name":"owner","internalType":"address"},{"type":"address","name":"spender","internalType":"address"}]},{"type":"function","stateMutability":"nonpayable","outputs":[{"type":"bool","name":"","internalType":"bool"}],"name":"approve","inputs":[{"type":"address","name":"spender","internalType":"address"},{"type":"uint256","name":"amount","internalType":"uint256"}]},{"type":"function","stateMutability":"view","outputs":[{"type":"uint256","name":"","internalType":"uint256"}],"name":"available","inputs":[]},{"type":"function","stateMutability":"view","outputs":[{"type":"uint256","name":"","internalType":"uint256"}],"name":"balance","inputs":[]},{"type":"function","stateMutability":"view","outputs":[{"type":"uint256","name":"","internalType":"uint256"}],"name":"balanceOf","inputs":[{"type":"address","name":"account","internalType":"address"}]},{"type":"function","stateMutability":"view","outputs":[{"type":"address","name":"","internalType":"address"}],"name":"controller","inputs":[]},{"type":"function","stateMutability":"view","outputs":[{"type":"uint8","name":"","internalType":"uint8"}],"name":"decimals","inputs":[]},{"type":"function","stateMutability":"nonpayable","outputs":[{"type":"bool","name":"","internalType":"bool"}],"name":"decreaseAllowance","inputs":[{"type":"address","name":"spender","internalType":"address"},{"type":"uint256","name":"subtractedValue","internalType":"uint256"}]},{"type":"function","stateMutability":"nonpayable","outputs":[],"name":"deposit","inputs":[{"type":"uint256","name":"_amount","internalType":"uint256"}]},{"type":"function","stateMutability":"nonpayable","outputs":[],"name":"depositAll","inputs":[]},{"type":"function","stateMutability":"nonpayable","outputs":[],"name":"earn","inputs":[]},{"type":"function","stateMutability":"view","outputs":[{"type":"uint256","name":"","internalType":"uint256"}],"name":"getRatio","inputs":[]},{"type":"function","stateMutability":"view","outputs":[{"type":"address","name":"","internalType":"address"}],"name":"governance","inputs":[]},{"type":"function","stateMutability":"nonpayable","outputs":[],"name":"harvest","inputs":[{"type":"address","name":"reserve","internalType":"address"},{"type":"uint256","name":"amount","internalType":"uint256"}]},{"type":"function","stateMutability":"nonpayable","outputs":[{"type":"bool","name":"","internalType":"bool"}],"name":"increaseAllowance","inputs":[{"type":"address","name":"spender","internalType":"address"},{"type":"uint256","name":"addedValue","internalType":"uint256"}]},{"type":"function","stateMutability":"view","outputs":[{"type":"uint256","name":"","internalType":"uint256"}],"name":"max","inputs":[]},{"type":"function","stateMutability":"view","outputs":[{"type":"uint256","name":"","internalType":"uint256"}],"name":"min","inputs":[]},{"type":"function","stateMutability":"view","outputs":[{"type":"string","name":"","internalType":"string"}],"name":"name","inputs":[]},{"type":"function","stateMutability":"nonpayable","outputs":[],"name":"setController","inputs":[{"type":"address","name":"_controller","internalType":"address"}]},{"type":"function","stateMutability":"nonpayable","outputs":[],"name":"setGovernance","inputs":[{"type":"address","name":"_governance","internalType":"address"}]},{"type":"function","stateMutability":"nonpayable","outputs":[],"name":"setMin","inputs":[{"type":"uint256","name":"_min","internalType":"uint256"}]},{"type":"function","stateMutability":"nonpayable","outputs":[],"name":"setTimelock","inputs":[{"type":"address","name":"_timelock","internalType":"address"}]},{"type":"function","stateMutability":"view","outputs":[{"type":"string","name":"","internalType":"string"}],"name":"symbol","inputs":[]},{"type":"function","stateMutability":"view","outputs":[{"type":"address","name":"","internalType":"address"}],"name":"timelock","inputs":[]},{"type":"function","stateMutability":"view","outputs":[{"type":"address","name":"","internalType":"contract IERC20"}],"name":"token","inputs":[]},{"type":"function","stateMutability":"view","outputs":[{"type":"uint256","name":"","internalType":"uint256"}],"name":"totalSupply","inputs":[]},{"type":"function","stateMutability":"nonpayable","outputs":[{"type":"bool","name":"","internalType":"bool"}],"name":"transfer","inputs":[{"type":"address","name":"recipient","internalType":"address"},{"type":"uint256","name":"amount","internalType":"uint256"}]},{"type":"function","stateMutability":"nonpayable","outputs":[{"type":"bool","name":"","internalType":"bool"}],"name":"transferFrom","inputs":[{"type":"address","name":"sender","internalType":"address"},{"type":"address","name":"recipient","internalType":"address"},{"type":"uint256","name":"amount","internalType":"uint256"}]},{"type":"function","stateMutability":"nonpayable","outputs":[],"name":"withdraw","inputs":[{"type":"uint256","name":"_shares","internalType":"uint256"}]},{"type":"function","stateMutability":"nonpayable","outputs":[],"name":"withdrawAll","inputs":[]}];
const stratABI = 'StrategyBenqiDai';  


const tests = [    
    {
        name: "PngAaveePng",
        assetAddr: "0x0025CEBD8289BBE0a51a5c85464Da68cBc2ec0c4",
        snowglobeAddr: "0xFd9ACEc0F413cA05d5AD5b962F3B4De40018AD87",
        strategyAddr: "",
        txnAmt: "25000000000000000000000"
    },
    {
        name:"PngAvaxAavee",
        assetAddr: "0x5944f135e4F1E3fA2E5550d4B5170783868cc4fE",
        snowglobeAddr: "0xa04fCcE7955312709c838982ad0E297375002C32",
        strategyAddr: "",
        txnAmt: "25000000000000000000000"
    },
    {
        name:"PngAvaxApein",
        assetAddr: "0x8dEd946a4B891D81A8C662e07D49E4dAee7Ab7d3",
        snowglobeAddr: "0xac102f66A1670508DFA5753Fcbbba80E0648a0c7",
        strategyAddr: "",
        txnAmt: "25000000000000000000000"
    },
      {
        name:"PngAvaxAve",
        assetAddr: "0x62a2F206CC78BAbAC9Db4dbC0c9923D4FdDef047",
        snowglobeAddr: "0x94183DD08FFAa595e43B104804d55eE95492C8cB",
        strategyAddr: "",
        txnAmt: "25000000000000000000000"
    },
    {
        name:"PngAvaxBifi",
        assetAddr: "0xAaCE68f9C8506610929D76a0729c7C24603641fC",
        snowglobeAddr: "0x4E258f7ec60234bb6f3Ea7eCFf5931901182Bd6E",
        strategyAddr: "",
        txnAmt: "25000000000000000000000"
    },
    {
        name:"PngAvaxBnb",
        assetAddr: "0xF776Ef63c2E7A81d03e2c67673fd5dcf53231A3f",
        snowglobeAddr: "0x21CCa1672E95996413046077B8cf1E52F080A165",
        strategyAddr: "",
        txnAmt: "25000000000000000000000"
    },
    {
        name:"PngAvaxCnr",
        assetAddr: "0xC04dE3796716ae5A6788b75DC0d4a1ecE06092d9",
        snowglobeAddr: "0xd43035F5Ef932E1335A664c707d85c54C924667e",
        strategyAddr: "",
        txnAmt: "25000000000000000000000"
    },
    {
        name:"PngAvaxCycle",
        assetAddr: "0x51486D916A273bEA3AE1303fCa20A76B17bE1ECD",
        snowglobeAddr: "0x45cd033361E9fEF750AAea96DbC360B342F4b4a2",
        strategyAddr: "",
        txnAmt: "25000000000000000000000"
    },
    {
        name:"PngAvaxCnr",
        assetAddr: "0x51486D916A273bEA3AE1303fCa20A76B17bE1ECD",
        snowglobeAddr: "0x42ff9473a5AEa00dE39355e0288c7A151EB00B6e",
        strategyAddr: "",
        txnAmt: "25000000000000000000000"
    },


    {
        name:"PngWbtcePng",
        assetAddr: "0xf277e270bc7664E6EBba19620530b83883748a13",
        snowglobeAddr: "0xEeEA1e815f12d344b5035a33da4bc383365F5Fee",
        strategyAddr: "",
        txnAmt: "25000000000000000000000"
    },
    {
        name:"PngYfiePng",
        assetAddr: "0x32Db611163CB2243E43d61D7721EBAa0226e8e08",
        snowglobeAddr: "0x269Ed6B2040f965D9600D0859F36951cB9F01460",
        strategyAddr: "",
        txnAmt: "25000000000000000000000"
    },
    {
        name:"PngYfiPng",
        assetAddr: "0xa465e953F9f2a00b2C1C5805560207B66A570093",
        snowglobeAddr: "0xc7D0E29b616B29aC6fF4FD5f37c8Da826D16DB0D",
        strategyAddr: "",
        txnAmt: "25000000000000000000000"
    }
];

for (const test of tests) {
    describe(test.name, async () => {
        doLPStrategyTest(test.name, test.assetAddr, test.snowglobeAddr, test.strategyAddr, globeABI, stratABI, test.txnAmt);
    });
}
