
const { ethers, getChainId} = require('hardhat')
const { 
    readConfig,isTxSuccess
} = require('./utils/helper')

const main = async () => {

    console.log("4 set Fulfillment Permission ");

    let chainID = await getChainId();
    let accounts = await ethers.getSigners()
    let deployer = accounts[0];
    console.log("chainID is :" + chainID + " address :" + deployer.address);

    const ORACLE__Contract = await ethers.getContractFactory('Operator',deployer)
    let oracleAddress = await readConfig("1config","ORACLE_ADDRESS");

    oracle = await ORACLE__Contract.connect(deployer).attach(oracleAddress);
    console.log("oracle address : " + oracle.address);

    let accountAddress = await readConfig("1config","ACCOUNT_ADDRESS");
    let resultObj = await oracle.setAuthorizedSenders([accountAddress],
        {
            gasPrice: 0x02540be400,
            gasLimit: 0x7a1200
        });
    
    let isOK = await isTxSuccess(resultObj)
    console.log("set Fulfillment Permission : ",isOK);
}



main();
