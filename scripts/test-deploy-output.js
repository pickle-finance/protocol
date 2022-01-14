const { ethers } = require("ethers");
const { readFileSync } = require("fs");

//ABI Merged with controller/strategy/gauge proxy only with write functions
const ABI = [{"inputs":[],"name":"governance","outputs":[{"internalType":"address","name":"","type":"address"}],"stateMutability":"view","type":"function"},{"inputs":[],"name":"harvest","outputs":[],"stateMutability":"nonpayable","type":"function"},{"inputs":[{"internalType":"address","name":"_controller","type":"address"}],"name":"setController","outputs":[],"stateMutability":"nonpayable","type":"function"},{"inputs":[{"internalType":"address","name":"_feeDistributor","type":"address"}],"name":"setFeeDistributor","outputs":[],"stateMutability":"nonpayable","type":"function"},{"inputs":[{"internalType":"uint256","name":"_keep","type":"uint256"}],"name":"setKeep","outputs":[],"stateMutability":"nonpayable","type":"function"},{"inputs":[{"internalType":"uint256","name":"_performanceDevFee","type":"uint256"}],"name":"setPerformanceDevFee","outputs":[],"stateMutability":"nonpayable","type":"function"},{"inputs":[{"internalType":"uint256","name":"_performanceTreasuryFee","type":"uint256"}],"name":"setPerformanceTreasuryFee","outputs":[],"stateMutability":"nonpayable","type":"function"},{"inputs":[{"internalType":"uint256","name":"_share","type":"uint256"}],"name":"setRevenueShare","outputs":[],"stateMutability":"nonpayable","type":"function"},{"inputs":[{"internalType":"address","name":"_strategist","type":"address"}],"name":"setStrategist","outputs":[],"stateMutability":"nonpayable","type":"function"},{"inputs":[{"internalType":"uint256","name":"_withdrawalDevFundFee","type":"uint256"}],"name":"setWithdrawalDevFundFee","outputs":[],"stateMutability":"nonpayable","type":"function"},{"inputs":[{"internalType":"uint256","name":"_withdrawalTreasuryFee","type":"uint256"}],"name":"setWithdrawalTreasuryFee","outputs":[],"stateMutability":"nonpayable","type":"function"},{"inputs":[{"internalType":"address","name":"_harvester","type":"address"}],"name":"whitelistHarvester","outputs":[],"stateMutability":"nonpayable","type":"function"},{"inputs":[{"internalType":"uint256","name":"_amount","type":"uint256"}],"name":"withdraw","outputs":[],"stateMutability":"nonpayable","type":"function"},{"inputs":[{"internalType":"contractIERC20","name":"_asset","type":"address"}],"name":"withdraw","outputs":[{"internalType":"uint256","name":"balance","type":"uint256"}],"stateMutability":"nonpayable","type":"function"},{"inputs":[],"name":"withdrawAll","outputs":[{"internalType":"uint256","name":"balance","type":"uint256"}],"stateMutability":"nonpayable","type":"function"},{"inputs":[{"internalType":"uint256","name":"_amount","type":"uint256"}],"name":"withdrawForSwap","outputs":[{"internalType":"uint256","name":"balance","type":"uint256"}],"stateMutability":"nonpayable","type":"function"},{"inputs":[{"internalType":"address","name":"_converter","type":"address"}],"name":"approveGlobeConverter","outputs":[],"stateMutability":"nonpayable","type":"function"},{"inputs":[{"internalType":"address","name":"_token","type":"address"},{"internalType":"address","name":"_strategy","type":"address"}],"name":"approveStrategy","outputs":[],"stateMutability":"nonpayable","type":"function"},{"inputs":[{"internalType":"address","name":"_token","type":"address"},{"internalType":"uint256","name":"_amount","type":"uint256"}],"name":"earn","outputs":[],"stateMutability":"nonpayable","type":"function"},{"inputs":[{"internalType":"address","name":"_strategy","type":"address"},{"internalType":"address","name":"_token","type":"address"}],"name":"inCaseStrategyTokenGetStuck","outputs":[],"stateMutability":"nonpayable","type":"function"},{"inputs":[{"internalType":"address","name":"_token","type":"address"},{"internalType":"uint256","name":"_amount","type":"uint256"}],"name":"inCaseTokensGetStuck","outputs":[],"stateMutability":"nonpayable","type":"function"},{"inputs":[{"internalType":"address","name":"_token","type":"address"},{"internalType":"address","name":"_strategy","type":"address"}],"name":"revokeStrategy","outputs":[],"stateMutability":"nonpayable","type":"function"},{"inputs":[{"internalType":"uint256","name":"_convenienceFee","type":"uint256"}],"name":"setConvenienceFee","outputs":[],"stateMutability":"nonpayable","type":"function"},{"inputs":[{"internalType":"address","name":"_devfund","type":"address"}],"name":"setDevFund","outputs":[],"stateMutability":"nonpayable","type":"function"},{"inputs":[{"internalType":"address","name":"_token","type":"address"},{"internalType":"address","name":"_globe","type":"address"}],"name":"setGlobe","outputs":[],"stateMutability":"nonpayable","type":"function"},{"inputs":[{"internalType":"address","name":"_onesplit","type":"address"}],"name":"setOneSplit","outputs":[],"stateMutability":"nonpayable","type":"function"},{"inputs":[{"internalType":"uint256","name":"_split","type":"uint256"}],"name":"setSplit","outputs":[],"stateMutability":"nonpayable","type":"function"},{"inputs":[{"internalType":"address","name":"_token","type":"address"},{"internalType":"address","name":"_strategy","type":"address"}],"name":"setStrategy","outputs":[],"stateMutability":"nonpayable","type":"function"},{"inputs":[{"internalType":"address","name":"_timelock","type":"address"}],"name":"setTimelock","outputs":[],"stateMutability":"nonpayable","type":"function"},{"inputs":[{"internalType":"address","name":"_treasury","type":"address"}],"name":"setTreasury","outputs":[],"stateMutability":"nonpayable","type":"function"},{"inputs":[{"internalType":"address","name":"_fromGlobe","type":"address"},{"internalType":"address","name":"_toGlobe","type":"address"},{"internalType":"uint256","name":"_fromGlobeAmount","type":"uint256"},{"internalType":"uint256","name":"_toGlobeMinAmount","type":"uint256"},{"internalType":"addresspayable[]","name":"_targets","type":"address[]"},{"internalType":"bytes[]","name":"_data","type":"bytes[]"}],"name":"swapExactGlobeForGlobe","outputs":[{"internalType":"uint256","name":"","type":"uint256"}],"stateMutability":"nonpayable","type":"function"},{"inputs":[{"internalType":"address","name":"_token","type":"address"},{"internalType":"uint256","name":"_amount","type":"uint256"}],"name":"withdraw","outputs":[],"stateMutability":"nonpayable","type":"function"},{"inputs":[{"internalType":"address","name":"_token","type":"address"}],"name":"withdrawAll","outputs":[],"stateMutability":"nonpayable","type":"function"},{"inputs":[{"internalType":"address","name":"_strategy","type":"address"},{"internalType":"address","name":"_token","type":"address"},{"internalType":"uint256","name":"parts","type":"uint256"}],"name":"yearn","outputs":[],"stateMutability":"nonpayable","type":"function"},{"inputs":[],"name":"acceptGovernance","outputs":[],"stateMutability":"nonpayable","type":"function"},{"inputs":[],"name":"acceptStrategist","outputs":[],"stateMutability":"nonpayable","type":"function"},{"inputs":[{"internalType":"address","name":"_deployer","type":"address"}],"name":"addDeployer","outputs":[],"stateMutability":"nonpayable","type":"function"},{"inputs":[{"internalType":"address","name":"_token","type":"address"}],"name":"addGauge","outputs":[],"stateMutability":"nonpayable","type":"function"},{"inputs":[],"name":"collect","outputs":[],"stateMutability":"nonpayable","type":"function"},{"inputs":[],"name":"deposit","outputs":[],"stateMutability":"nonpayable","type":"function"},{"inputs":[{"internalType":"address","name":"_token","type":"address"}],"name":"deprecateGauge","outputs":[],"stateMutability":"nonpayable","type":"function"},{"inputs":[{"internalType":"uint256","name":"_start","type":"uint256"},{"internalType":"uint256","name":"_end","type":"uint256"}],"name":"distribute","outputs":[],"stateMutability":"nonpayable","type":"function"},{"inputs":[{"internalType":"address","name":"_gauge","type":"address"},{"internalType":"address","name":"_token","type":"address"}],"name":"migrateGauge","outputs":[],"stateMutability":"nonpayable","type":"function"},{"inputs":[{"internalType":"address","name":"_owner","type":"address"}],"name":"poke","outputs":[],"stateMutability":"nonpayable","type":"function"},{"inputs":[],"name":"preDistribute","outputs":[],"stateMutability":"nonpayable","type":"function"},{"inputs":[{"internalType":"address","name":"_deployer","type":"address"}],"name":"removeDeployer","outputs":[],"stateMutability":"nonpayable","type":"function"},{"inputs":[{"internalType":"address","name":"_token","type":"address"}],"name":"renewGauge","outputs":[],"stateMutability":"nonpayable","type":"function"},{"inputs":[],"name":"reset","outputs":[],"stateMutability":"nonpayable","type":"function"},{"inputs":[{"internalType":"address","name":"_governance","type":"address"}],"name":"setGovernance","outputs":[],"stateMutability":"nonpayable","type":"function"},{"inputs":[{"internalType":"uint256","name":"_pid","type":"uint256"}],"name":"setPID","outputs":[],"stateMutability":"nonpayable","type":"function"},{"inputs":[{"internalType":"address[]","name":"_tokenVote","type":"address[]"},{"internalType":"uint256[]","name":"_weights","type":"uint256[]"}],"name":"vote","outputs":[],"stateMutability":"nonpayable","type":"function"}];

function Topic(hash, functionFragment){
    return {
        hash,
        functionFragment
    };
}

async function testDeployJson() {
    //list of valid topics
    const validTopics = [
        Topic("0x30ed9dff","setGlobe(address, address)"),
        Topic("0xc494448e","approveStrategy(address, address)"),
        Topic("0x72cb5d97","setStrategy(address, address)"),
        Topic("0x54df7b63","whitelistHarvester(address)"),
        Topic("0x9da882ac","addGauge(address)"),
    ];

    const deployFile = JSON.parse(readFileSync("./deploy.json",{
        encoding: "utf-8"
    }));

    const genericInterface = new ethers.utils.Interface(ABI);

    console.log("Validating deploy.json: ");
    try {
        for(const strIndex in deployFile){
            const data = deployFile[strIndex].data;
            const targets = deployFile[strIndex].targets;
    
            if(data.length !== targets.length){
                throw new Error("Invalid File Format");
            }
    
            for(let i = 0; i < data.length;i++){
                const hash = data[i].slice(0,10);
    
                const topic = validTopics.find(o => o.hash === hash);
                if(!topic){
                    throw new Error("Topic Hash not Approved for: "+data[i]);
                }
    
                const decodedData = genericInterface.decodeFunctionData(topic.functionFragment,data[i]);
                const target = targets[i];
    
                console.log(`\nTarget: ${target} with data:\n Topic: ${topic.functionFragment} = ${decodedData}`);
            }
        }
    } catch (error) {
        console.error("Error Found Validating deploy.json, file format not recognized.");
        console.error(error);
    }
}


testDeployJson();