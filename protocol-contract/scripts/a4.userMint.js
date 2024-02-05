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

    isSucess = await isContractTransferSuccess(
        await carvIDContract.connect(admin).mint(user.address,"https://test/data.com")
    )
  

    
}

main();

