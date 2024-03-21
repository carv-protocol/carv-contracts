const {
    readConfig
} = require('./utils/helper')

const { ethers: hEether, upgrades } = require('hardhat');

const main = async () => {
 
    // let newOwner = "0x87d93aF94bd2a359602525D20A46d6eBc6984655"
    let soulContractAddress = await readConfig("1config","SOUL_CONTRACT_ADDRESS");
    let owner = await upgrades.erc1967.getAdminAddress(
        soulContractAddress
    );

    console.log("xxl owner is : ",owner);
}

main();

