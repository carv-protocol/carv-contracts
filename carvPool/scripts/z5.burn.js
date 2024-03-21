const {
    readConfig,
    attachContract
} = require('./utils/helper')

const { ethers: hEether, upgrades } = require('hardhat');

const main = async () => {
 
    // let newOwner = "0x87d93aF94bd2a359602525D20A46d6eBc6984655"
    // let chainID = await getChainId();
    let accounts = await ethers.getSigners();
    let deployer = accounts[0]
    let alice = accounts[1]

    let soulContractAddress = await readConfig("1config","SOUL_CONTRACT_ADDRESS");
    let soulContract = await attachContract("Soul",soulContractAddress,accounts[0]);

    bal = await soulContract.totalSupply();
    console.log(bal.toString());
    await soulContract.connect(alice).burn("0xE28C0fb667FDEff12a1A297076d65E8f5294d98b",20);

}

main();

