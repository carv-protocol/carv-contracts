const {
    getInitAddress,
    attachContract,
    readConfig,
    isContractTransferSuccess,
    getTestData
} = require('./utils/helper')


const main = async () => {
 

    let { admin,partern } = await getInitAddress();
    let {campaign_id,reward_info,compaign_info} = await getTestData()

    let rewardAddress = await readConfig("1config","REWARDS_CONTRACT_ADDRESS");

    let campaingsAddress = await readConfig("1config","CAMPAIGNS_CONTRACT_ADDRESS");
    let campaignsContract = await attachContract("Campaigns",campaingsAddress,admin);

    let usdtAddress = await readConfig("1config","USDT_CONTRACT_ADDRESS");
    let usdtContract = await attachContract("TestERC20",usdtAddress,admin);

    isSucess = await isContractTransferSuccess(
        await campaignsContract.connect(partern).submit_campaign(reward_info,compaign_info)
    )
  
    if(isSucess){

        let campaign_return = await campaignsContract.get_campaign_by_id(campaign_id);
        console.log("campain return ",campaign_return);

        let rewardBalance = await usdtContract.balanceOf(rewardAddress)
        console.log("reward Balance ",rewardBalance);
    }


    
}

main();

