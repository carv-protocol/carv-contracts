const {
    getInitAddress,
    attachContract,
    readConfig,
} = require('./utils/helper')


const main = async () => {
 
    /////

    let { admin } = await getInitAddress();
    
    let campaignsServiceAddress = await readConfig("1config","CAMPAIGNS_SERVICE_CONTRACT_ADDRESS");

    // 1.reward
    let rewardAddress = await readConfig("1config","REWARDS_CONTRACT_ADDRESS");
    let rewardContract = await attachContract("Rewards",rewardAddress,admin);
    await rewardContract.set_service_address(campaignsServiceAddress);
 
    // 2.campaings
    let campaingsAddress = await readConfig("1config","CAMPAIGNS_CONTRACT_ADDRESS");
    let campaingsContract = await attachContract("Campaigns",campaingsAddress,admin);
    await campaingsContract.set_service_address(campaignsServiceAddress);

    // // 3.carv id
    // let carvIDAddress = await readConfig("1config","CARV_ID_CONTRACT_ADDRESS");
    // let carvIDContract = await attachContract("CarvID",carvIDAddress,admin);
    // await carvIDContract.set_service_address(campaignsServiceAddress);
    
}

main();

