const {
    upgradeByContractName
} = require('./utils/helper')

const main = async () => {
 
    await upgradeByContractName("CampaignsService");
}

main();
