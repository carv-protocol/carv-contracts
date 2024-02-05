const { ethers, getChainId} = require('hardhat')
const { utils } = require('ethers')
const { 
    writeConfig 
} = require('./utils/helper')

const main = async () => {


    let chainID = await getChainId();
    //let chainID = 0;
    let accounts = await ethers.getSigners()
    let deployer = accounts[0];
    console.log("chainID is :" + chainID + " address :" + deployer.address);

    let totalSupply = utils.parseEther("1000000000");
    const LINK__Contract = await ethers.getContractFactory('ERC677',deployer)

    LINK = await LINK__Contract.connect(deployer).deploy(
        deployer.address,
        totalSupply,
        "Arch",
        "Arch",
        {
            gasPrice: 0x02540be400,
            gasLimit: 0x7a1200
        }
    );
    await writeConfig("1config","1config","LINK_ADDRESS",LINK.address);
    console.log("link address : ",LINK.address);
   
}



main();
