
const { 
    readConfig
} = require('./utils/helper')

const { ethers, upgrades,getChainId } = require('hardhat'); 

const main = async () => {

    console.log("20 upgrade ....");

    let chainID = await getChainId();
    let accounts = await ethers.getSigners()
    let deployer = accounts[0];
    console.log("chainID is :" + chainID + " address :" + deployer.address);

    const dataConsumer__Contract = await ethers.getContractFactory('DataConsumer',deployer)

    let dataConsumerAddress = await readConfig("1config","DATACONSUMER_ADDRESS");
    console.log("dataConsumer Address :",dataConsumerAddress);

    await upgrades.upgradeProxy(
        dataConsumerAddress, 
        dataConsumer__Contract,{
            from:accounts[0].address,
            gasPrice: 0x02540be400 * 1.1,
            gasLimit: 0x7a1200 * 1.1
        },        
    );
    
    console.log('Bridge upgraded');

}

main();
