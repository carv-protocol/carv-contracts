const { upgrades } = require('hardhat');
const {
    readConfig
} = require('./utils/helper')

const main = async () => {
 
    let addressConfigs = [
        "REWARDS_CONTRACT_ADDRESS","CAMPAIGNS_CONTRACT_ADDRESS","CARV_ID_CONTRACT_ADDRESS","CAMPAIGNS_SERVICE_CONTRACT_ADDRESS"
    ]

    for(var i = 0 ;i < addressConfigs.length ;i ++ ){

        let orgAddress = await readConfig("1config",addressConfigs[i]);

        let implAddress = await upgrades.erc1967.getImplementationAddress(orgAddress);
        console.log("xxl implAddress : ",addressConfigs[i],implAddress);

    }
    
}

main();



// "REWARDS_CONTRACT_ADDRESS": "0x3a1832545c8c576A8cD6Ee055B42544Cf73FdC66",
// "CAMPAIGNS_CONTRACT_ADDRESS": "0x5B1e282FC9A27A2b722dB352da5f853Ec9991343",
// "CARV_ID_CONTRACT_ADDRESS": "0xC5F228ec6AbA02241081248859595CFDe7a46f4D",
// "CAMPAIGNS_SERVICE_CONTRACT_ADDRESS": "0x42C04bAcD288763d5f88f8F83A6C06b6e07dC331",
