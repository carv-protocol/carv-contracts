
const { ethers, getChainId} = require('hardhat')
const { readConfig} = require('./helper')

const main = async () => {

    let chainID = await getChainId();
    let accounts = await ethers.getSigners()
    let deployer = accounts[0];
    console.log("chainID is :" + chainID + " address :" + deployer.address);

    const DataConsumer__Contract = await ethers.getContractFactory('DataConsumer',deployer)
    let dataConsumerAddress = await readConfig("1","DATACONSUMER_ADDRESS");

    let dataConsumer = await DataConsumer__Contract.connect(deployer).attach(dataConsumerAddress);  
    let res = await dataConsumer.requestFromScore(
        90,
        "b1c4ef736f60f4a16bc0c72a3d90d6f0620873f3e2056774bb39b0876af90aa6771e5b2a4db3d81f37bc65f11b40128b9253093fbe88e9cef2e5d455eb798cbb"
    );

    console.log("xxl res",res);

}


main();
