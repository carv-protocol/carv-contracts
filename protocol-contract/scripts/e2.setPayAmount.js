const {
    getInitAddress,
    attachContract,
    readConfig,
    isContractTransferSuccess,
} = require('./utils/helper')


const main = async () => {
 

    let { admin,user } = await getInitAddress();


    let carvIDAddress = await readConfig("1config","CARV_ID_CONTRACT_ADDRESS");
    let carvIDContract = await attachContract("CarvID",carvIDAddress,admin);
    let amount = "2220900000000000";

    isSucess = await isContractTransferSuccess(
        await carvIDContract.connect(admin).setPayAmount(amount)
    )

    console.log("carvID setPayAmounts is ",isSucess);


    
}

main();

