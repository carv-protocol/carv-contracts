
const { ethers, getChainId} = require('hardhat')
const { 
    writeConfig,
    readConfig
} = require('./utils/helper')

const main = async () => {


    let chainID = await getChainId();
    let accounts = await ethers.getSigners()
    let deployer = accounts[0];
    console.log("chainID is :" + chainID + " address :" + deployer.address);

    const ORACLE__Contract = await ethers.getContractFactory('Operator',deployer)

    let linkAddress = await readConfig("1config","LINK_ADDRESS");
    console.log("link address is : " + linkAddress);

    oracle = await ORACLE__Contract.connect(deployer).deploy(
        linkAddress,
        deployer.address,
        {
            gasPrice: 0x02540be400,
            gasLimit: 0x7a1200
        }
    );

    console.log("oracle address : " + oracle.address);
    await writeConfig("1config","1config","ORACLE_ADDRESS",oracle.address);
    
}



main();
