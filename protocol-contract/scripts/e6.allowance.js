const {
    getInitAddress,
    attachContract,
    readConfig,
    isContractTransferSuccess,
} = require('./utils/helper')


const main = async () => {
 



    let { admin ,partern} = await getInitAddress();

    let usdtAddress = await readConfig("1config","USDT_CONTRACT_ADDRESS");
    let usdtContract = await attachContract("TestERC20",usdtAddress,admin);

    let amount = await usdtContract.allowance(admin.address,partern.address);

    console.log("approve from %s to %s allowance %s ",admin.address,partern.address,amount);

    
}

main();

