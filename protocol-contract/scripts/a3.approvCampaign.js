const {
    getInitAddress,
    attachContract,
    readConfig,
    isContractTransferSuccess,
    getTestData
} = require('./utils/helper')


const main = async () => {
 

    let { admin } = await getInitAddress();
    let { campaign_id } = await getTestData()

    let campaingsServiceAddress = await readConfig("1config","CAMPAIGNS_SERVICE_CONTRACT_ADDRESS");
    let campaignsServiceContract = await attachContract("Campaigns",campaingsServiceAddress,admin);

    isSucess = await isContractTransferSuccess(
        await campaignsServiceContract.connect(admin).approve_campaign(campaign_id)
    )
  
    if(isSucess){
        console.log("approve campaign is OK");
    }


    
}

main();

