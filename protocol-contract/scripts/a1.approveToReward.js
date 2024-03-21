const {
    getInitAddress,
    attachContract,
    readConfig,
    isContractTransferSuccess
} = require('./utils/helper')


const main = async () => {

    const amount = 200000000000
    let { admin ,partern} = await getInitAddress();

    let usdtAddress = await readConfig("1config","USDT_CONTRACT_ADDRESS");
    let usdtContract = await attachContract("TestERC20",usdtAddress,admin);

    let serviceAddress = await readConfig("1config","CARV_PROTOCAL_SERVICE_CONTRACT_ADDRESS");
   
    // partern
    let isSucess = await isContractTransferSuccess(
        await usdtContract.connect(admin).approve(serviceAddress,amount)
    )

    console.log("approve to reward contract is %s - %s ",serviceAddress,isSucess);
    
}

main();

// "USDT_CONTRACT_ADDRESS": "0x5c7CaDb3c84505D79EBfb2C594Bc6b15B9570f10",
// "REWARDS_CONTRACT_ADDRESS": "0xc3782a727B6177B5FE4d37c74f99184246F588a4",
// "CAMPAIGNS_CONTRACT_ADDRESS": "0xdCDB5c66B5838535C828c8F4D6AaFfAc1dc27F0D",
// "CARV_ID_CONTRACT_ADDRESS": "0xD58F9a908FB4f5Cc37704f1773729B1198F693C3",
// "CAMPAIGNS_SERVICE_CONTRACT_ADDRESS": "0x34B3F2378c2f42248ea0499f0b8B5613274a9c51"