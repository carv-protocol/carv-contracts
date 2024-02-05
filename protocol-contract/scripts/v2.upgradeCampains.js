const {
    verifyByContractName
} = require('./utils/helper')

// https://testnet.opbnbscan.com/address/0xEeaECdcF0Ef7eD1F83f8082853A68c6daB92Af2F?tab=Contract&p=1
const main = async () => {
 
    await verifyByContractName("Campaigns");
}

main();

// https://opbnbscan.com/address/0x4A895E4861465555a2E353e4cE801ACd5AdE15d4?tab=Contract&p=1