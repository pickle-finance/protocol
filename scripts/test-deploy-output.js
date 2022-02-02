const { ethers } = require("ethers");
const { readFileSync } = require("fs");

//ABI Merged with controller/strategy/gauge proxy only with write functions
const ABI = require('../test/abis/ControllerStrategyGauge.json');

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
        Topic("0x4641257d","harvest()"),
        Topic("0xc494448e","approveStrategy(address, address)"),
        Topic("0x72cb5d97","setStrategy(address, address)"),
        Topic("0x54df7b63","whitelistHarvester(address)"),
        Topic("0xd389800f","earn()"),
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
