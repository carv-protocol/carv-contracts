const {
    getInitAddress,
    attachContract,
    readConfig,
    isContractTransferSuccess,
    getTestData
} = require('./utils/helper')

const main = async () => {
 

    let { admin,user } = await getInitAddress();
    let { campaign_id} = await getTestData()

    let campaingsServiceAddress = await readConfig("1config","CAMPAIGNS_SERVICE_CONTRACT_ADDRESS");
    let campaignsServiceContract = await attachContract("CampaignsService",campaingsServiceAddress,admin);


    let isSucess = await isContractTransferSuccess(
      await campaignsServiceContract.connect(user).claim_reward(user.address,campaign_id)
    )
    if(isSucess){

      let usdtAddress = await readConfig("1config","USDT_CONTRACT_ADDRESS");
      let usdtContract = await attachContract("TestERC20",usdtAddress,admin);
      let userBalance = await usdtContract.balanceOf(user.address)

      console.log("user balance is : ",userBalance.toString());

    }else{
      console.log("user claim error ");
    }


}

main();

