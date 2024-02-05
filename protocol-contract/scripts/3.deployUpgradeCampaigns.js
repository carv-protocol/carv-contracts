const {
    getInitAddress,
    deployUpgradeContract,
    readConfig,
    writeConfig,
} = require('./utils/helper')


const main = async () => {
 

    let { admin } = await getInitAddress();
    
    let rewardAddress = await readConfig("1config","REWARDS_CONTRACT_ADDRESS");
    campaignsContract = await deployUpgradeContract(admin,"Campaigns","v0.0.1",rewardAddress);

    await writeConfig("1config","1config","CAMPAIGNS_CONTRACT_ADDRESS",campaignsContract.address);

    console.log("admin Address :" ,admin.address);
    // console.log("Rewards  Address :" ,campaignsContract.address);
    
}

main();

