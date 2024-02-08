const {
    getInitAddress,
    attachContract,
    readConfig,
    isContractTransferSuccess,
} = require('./utils/helper')

const main = async () => {
    let { admin, tee2 } = await getInitAddress();

    let campaignsServiceAddress = await readConfig("1config", "CARV_PROTOCAL_SERVICE_CONTRACT_ADDRESS");
    let campaignsServiceContract = await attachContract("CarvProtocalService", campaignsServiceAddress, admin);

    let isSucess = await isContractTransferSuccess(
        await campaignsServiceContract.add_tee_role(admin.address)
    )

    console.log("add tee role is ",isSucess);
   
    
}

main();

