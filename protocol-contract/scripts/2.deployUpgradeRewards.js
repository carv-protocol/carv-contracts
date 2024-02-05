const {
    getInitAddress,
    deployUpgradeContract,
    writeConfig,
} = require('./utils/helper')

const main = async () => {
 

    let { admin } = await getInitAddress();

    let rewardsContract = await deployUpgradeContract(admin,"Rewards","v0.0.1");
    await writeConfig("1config","1config","REWARDS_CONTRACT_ADDRESS",rewardsContract.address);

    console.log("Deployer Address :" ,admin.address);
    console.log("Rewards  Address :" ,rewardsContract.address);
    
}

main();

