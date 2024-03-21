const {
    readConfig
} = require('./utils/helper')

const { ethers: hEether, upgrades } = require('hardhat');

const main = async () => {
 
    let newOwner = "0x87d93aF94bd2a359602525D20A46d6eBc6984655"
    let accounts = await ethers.getSigners();
    let deployer = accounts[0]
    // let soulContractAddress = await readConfig("1config","SOUL_CONTRACT_ADDRESS");
    await upgrades.admin.transferProxyAdminOwnership(
        newOwner,
        deployer
    );

    // let result = await upgrades.admin.transferProxyAdminOwnership(addr2.address,addr1);
}

main();

