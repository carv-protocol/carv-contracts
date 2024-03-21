const {
    getInitAddress,
    attachContract,
    readConfig,
    isContractTransferSuccess,
} = require('./utils/helper')

const main = async () => {

    let exAddress = "0x19BAa72643aa11b28cb6251fd7596201778EaD9A";
    let { admin, tee2 } = await getInitAddress();

    let campaignsServiceAddress = await readConfig("1config", "CARV_PROTOCAL_SERVICE_CONTRACT_ADDRESS");
    let campaignsServiceContract = await attachContract("CarvProtocalService", campaignsServiceAddress, admin);

    // await campaignsServiceContract.add_tee_role(admin.address)
    let isSucess = await isContractTransferSuccess(
        
        await campaignsServiceContract.add_tee_role(exAddress)
    )

    console.log("add tee role is ",isSucess);
   
    
}

main();

