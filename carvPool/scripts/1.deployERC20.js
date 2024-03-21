const {
    deployContract,
    writeConfig,
} = require('./utils/helper')
const { ethers } = require('hardhat');


const main = async () => {
 
    let totalSupply = 100000000000000;
    accounts = await ethers.getSigners()
    deployer = accounts[0];

    //archer
    archerContract = await deployContract(deployer, "TestERC20", "Archer", "Archer", totalSupply);
    await writeConfig("1config","1config","ARCHER_CONTRACT_ADDRESS",archerContract.address);


}

main();

