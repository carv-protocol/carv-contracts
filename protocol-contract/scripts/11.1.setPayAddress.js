const {
    getInitAddress,
    attachContract,
    readConfig,
    isContractTransferSuccess,
} = require('./utils/helper')


// 0x9D8D017a457123182278293422974B0B64C400DB
const main = async () => {
    let { admin } = await getInitAddress();


    let carvIDAddress = await readConfig("1config", "CARV_ID_CONTRACT_ADDRESS");
    let carvIDContract = await attachContract("CarvID", carvIDAddress, admin);

    let isSucess = await isContractTransferSuccess(

        // await carvIDContract.connect(admin).setPayAddress(admin.address)
         await carvIDContract.connect(admin).setPayAddress("0x52d297101bB41D88dd6Ab30A130E888Ca9502259")
    )
    console.log("carvIDContract setPayAddress :" ,isSucess);


}

main();

