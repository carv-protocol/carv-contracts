const {
    getInitAddress,
    attachContract,
    readConfig,
    isContractTransferSuccess,
} = require('./utils/helper')


const main = async () => {
 


    const amount = 100000
    let { admin ,partern} = await getInitAddress();

    let usdtAddress = await readConfig("1config","USDT_CONTRACT_ADDRESS");
    let usdtContract = await attachContract("TestERC20",usdtAddress,admin);

    let carvIDAddress = await readConfig("1config","CARV_ID_CONTRACT_ADDRESS");
    

    let isSucess = await isContractTransferSuccess(
        await usdtContract.connect(partern).approve(carvIDAddress,amount)
    )

    console.log("approve to reward contract is %s - %s ",carvIDAddress,isSucess);

    
}

main();

