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

    let payAddress =  await carvIDContract.connect(admin).getPayAddress()

    console.log("carvIDContract getPayAddress :" ,payAddress);


}

main();

