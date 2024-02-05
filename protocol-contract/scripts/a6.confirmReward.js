const {
    getInitAddress,
    attachContract,
    readConfig,
    isContractTransferSuccess,
    getTestData
} = require('./utils/helper')

const main = async () => {
 

    let { admin,user,tee } = await getInitAddress();
    let { campaign_id } = await getTestData()

    let campaingsServiceAddress = await readConfig("1config","CAMPAIGNS_SERVICE_CONTRACT_ADDRESS");
    let campaignsServiceContract = await attachContract("CampaignsService",campaingsServiceAddress,admin);

    isSucess = await isContractTransferSuccess(
      await campaignsServiceContract.connect(tee).confirm_reward(user.address,campaign_id)
    )
  
    if(isSucess){
        console.log("approve campaign is OK");

        let rewardAddress = await readConfig("1config","REWARDS_CONTRACT_ADDRESS");
        let rewardContract = await attachContract("Rewards",rewardAddress,admin);
        let ret_exit = await rewardContract.is_reward_confirmed(user.address,campaign_id);
        console.log("reward is confirmed : ",ret_exit);
    }else{
      console.log("confirm_reward error ");
    }


}

main();

