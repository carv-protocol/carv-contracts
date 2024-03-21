const {
    deployUpgradeContract,
    writeConfig,
} = require('./utils/helper')
const { ethers } = require('hardhat');

const main = async () => {
 

    accounts = await ethers.getSigners()
    deployer = accounts[0];

    cstContract = await deployUpgradeContract(deployer, "CarvStakingToken", "CarvStakingToken", "CST");

    await writeConfig("1config","1config","CARV_STAKING_CONTRACT_ADDRESS",cstContract.address);


}

main();

