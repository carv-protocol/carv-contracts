const {
    readConfig,
    isContractTransferSuccess,
    attachContract
} = require('./utils/helper')

const main = async () => {
 
    accounts = await ethers.getSigners()
    deployer = accounts[0];
    

    let ctsAddress = await readConfig("1config","CARV_STAKING_CONTRACT_ADDRESS");
    let carvPoolAddress = await readConfig("1config","CARV_POOL_CONTRACT_ADDRESS");    

    let cstContract = await attachContract("CarvStakingToken",ctsAddress,deployer);

    let result = await isContractTransferSuccess(
        await cstContract.connect(deployer).grantRole(
            "0x1fbabc9a8c0a7fda7984eaff273bdabf1f28be7b76990b15a7d7e7bc1eb0dd59",
            carvPoolAddress
        )
    )

    console.log("grantRole :",result);
}

main();

