const {
    readConfig,
    deployUpgradeContract,
    writeConfig,
} = require('./utils/helper')
const { ethers } = require('hardhat');

const main = async () => {
 

    accounts = await ethers.getSigners()
    deployer = accounts[0];

    let archerAddress = await readConfig("1config","ARCHER_CONTRACT_ADDRESS");
    let ctsAddress = await readConfig("1config","CARV_STAKING_CONTRACT_ADDRESS");

    //carv pool
    carvPoolContract = await deployUpgradeContract(deployer, "CarvPool", ctsAddress,archerAddress);
    await writeConfig("1config","1config","CARV_POOL_CONTRACT_ADDRESS",carvPoolContract.address);


}

main();

