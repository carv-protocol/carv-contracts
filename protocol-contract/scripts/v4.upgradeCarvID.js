const {
    verifyByContractName
} = require('./utils/helper')

// https://testnet.opbnbscan.com/address/0xBdf48A5DB21Db74aCd813c8B103F6Dd136fA83f1?tab=Contract&p=1
const main = async () => {
 
    await verifyByContractName("CarvID");
}

main();

// https://opbnbscan.com/address/0xE5D37dE090eF555A2200E528091061C3FB45416B?tab=Contract&p=1