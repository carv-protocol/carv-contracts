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
    let usdtAddress = await readConfig("1config","USDT_CONTRACT_ADDRESS");

    isSucess = await isContractTransferSuccess(
        await carvIDContract.connect(admin).setPayAddress(usdtAddress)
    )
  

    console.log("carvID setPayAddress is ",isSucess);


    
}

main();

