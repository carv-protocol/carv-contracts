const {
    getInitAddress,
    deployUpgradeContract,
    readConfig,
    writeConfig,
} = require('./utils/helper')


const main = async () => {
 

    let { admin } = await getInitAddress();
    
    carvIDContract = await deployUpgradeContract(admin,"CarvID","v0.0.1","CarvID","CARV-ID");
    await writeConfig("1config","1config","CARV_ID_CONTRACT_ADDRESS",carvIDContract.address);

    console.log("admin Address :" ,admin.address);
    console.log("Rewards  Address :" ,carvIDContract.address);
    
}

main();

