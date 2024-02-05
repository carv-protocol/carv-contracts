
const { ethers, getChainId,upgrades} = require('hardhat')
const { 
    writeConfig
} = require('./utils/helper')


const main = async () => {

    console.log("5 deploy data consumer ....");

    let chainID = await getChainId();
    let accounts = await ethers.getSigners()
    let deployer = accounts[0];
    console.log("chainID is :" + chainID + " address :" + deployer.address);
    const DataConsumer__Contract = await ethers.getContractFactory('DataConsumer',deployer)

    const dataConsumer = await upgrades.deployProxy(
        DataConsumer__Contract, 
        ["v1.0.0"], 
        { initializer: '__DataConsumer_init' },
        {
            gasPrice: 0x02540be400,
            gasLimit: 0x7a1200
        }
    );
    console.log("dataConsumer address : " + dataConsumer.address);    
    await writeConfig("1config","1config","DATACONSUMER_ADDRESS",dataConsumer.address);

}



main();
