
const { ethers, getChainId} = require('hardhat')
const { 
    readConfig
} = require('./utils/helper')
const main = async () => {


    let chainID = await getChainId();
    let accounts = await ethers.getSigners()
    let deployer = accounts[0];
    console.log("chainID is :" + chainID + " address :" + deployer.address);

    const LINKInterface__Contract = await ethers.getContractFactory('LinkInterface',deployer)

    let linkInterfaceAddress = await readConfig("1config","LINK_INTERFACE_ADDRESS");
    const LINKInterface = await LINKInterface__Contract.connect(deployer).attach(linkInterfaceAddress);
    console.log("LINKInterface address :", LINKInterface.address);

    let linkAddress = await LINKInterface.getAddress();
    console.log("link Address ",linkAddress);

}



main();
