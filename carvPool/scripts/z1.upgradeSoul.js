const {
    upgradeByContractName,
   //forceUpgradeByContractName
} = require('./utils/helper')

const main = async () => {
 
    await upgradeByContractName("Soul");
    // await forceUpgradeByContractName("Soul");
}

main();

