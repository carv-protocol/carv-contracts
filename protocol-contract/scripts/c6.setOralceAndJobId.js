
const { ethers, getChainId} = require('hardhat')
const { 
    readConfig
} = require('./utils/helper')

const main = async () => {

    console.log("6 get arbiter list ....");

    let chainID = await getChainId();
    let accounts = await ethers.getSigners()
    let deployer = accounts[0];
    console.log("chainID is :" + chainID + " address :" + deployer.address);

    const DataConsumer__Contract = await ethers.getContractFactory('DataConsumer',deployer)
    let dataConsumerAddress = await readConfig("1config","DATACONSUMER_ADDRESS");
    let oracleAddress = await readConfig("1config","ORACLE_ADDRESS");
    let jobId = await readConfig("1config","JOB_ID");

    let dataConsumer = await DataConsumer__Contract.connect(deployer).attach(dataConsumerAddress);  
    let oracle =  oracleAddress.toLowerCase();
    await dataConsumer.setOralceAndJobId(
            oracle,jobId,{
            gasPrice: 0x02540be400,
            gasLimit: 0x7a1200
        }
    );
    
}


main();
