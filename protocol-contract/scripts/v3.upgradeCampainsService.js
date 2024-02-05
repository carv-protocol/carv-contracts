const {
    verifyByContractName
} = require('./utils/helper')

// https://testnet.opbnbscan.com/address/0x535632E816Ad23E58C01F4431684B2A8FF37E1fA?tab=Contract&p=1
const main = async () => {
 
    await verifyByContractName("CampaignsService");
}

main();

// https://opbnbscan.com/address/0x18b46dd9CA2d9D02146A2018B3A8BBD3Db69fbc2?tab=Contract&p=1