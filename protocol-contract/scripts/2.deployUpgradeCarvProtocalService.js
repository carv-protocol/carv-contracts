const {
    getInitAddress,
    deployUpgradeContract,
    readConfig,
    writeConfig,
} = require('./utils/helper')

const main = async () => {
 

    let { admin } = await getInitAddress();

    let usdtAddress = await readConfig("1config", "USDT_CONTRACT_ADDRESS");
    let carvProtocalServiceContract = await deployUpgradeContract(admin,"CarvProtocalService",usdtAddress);


    await writeConfig("1config","1config","CARV_PROTOCAL_SERVICE_CONTRACT_ADDRESS",carvProtocalServiceContract.address);

    console.log("Deployer Address :" ,admin.address);
    console.log("CarvProtocalService  Address :" ,carvProtocalServiceContract.address);
    
}

main();

