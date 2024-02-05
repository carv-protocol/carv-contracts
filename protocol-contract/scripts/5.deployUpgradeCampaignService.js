const {
    getInitAddress,
    deployUpgradeContract,
    readConfig,
    writeConfig,
} = require('./utils/helper')


const main = async () => {
 

    let { admin } = await getInitAddress();
    
    let rewardAddress = await readConfig("1config","REWARDS_CONTRACT_ADDRESS");
    let campainsAddress = await readConfig("1config","CAMPAIGNS_CONTRACT_ADDRESS");

    let campaignsServiceContract = await deployUpgradeContract(
        admin,"CampaignsService","v0.0.1",
        rewardAddress,
        campainsAddress
    );

    await writeConfig("1config","1config","CAMPAIGNS_SERVICE_CONTRACT_ADDRESS",campaignsServiceContract.address);

    console.log("admin Address :" ,admin.address);
    console.log("Rewards  Address :" ,campaignsServiceContract.address);
    
}

main();

