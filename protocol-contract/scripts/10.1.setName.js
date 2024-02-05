const {
    getInitAddress,
    attachContract,
    readConfig,
    isContractTransferSuccess,
} = require('./utils/helper')

const main = async () => {
    let { admin } = await getInitAddress();


    let carvIDAddress = await readConfig("1config", "CARV_ID_CONTRACT_ADDRESS");
    let carvIDContract = await attachContract("CarvID", carvIDAddress, admin);

    let isSucess = await isContractTransferSuccess(
        await carvIDContract.connect(admin).setName721("CARV ID")
    )
    console.log("carvIDContract setName721 :" ,isSucess);


}

main();

