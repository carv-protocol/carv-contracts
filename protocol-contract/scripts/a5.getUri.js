const {
    getInitAddress,
    attachContract,
    readConfig,
    isContractTransferSuccess,
} = require('./utils/helper')


const main = async () => {
 

    let { admin,user } = await getInitAddress();


    let carvIDAddress = await readConfig("1config","CARV_ID_CONTRACT_ADDRESS");
    let carvIDContract = await attachContract("CarvID",carvIDAddress,admin);

    let uri = await carvIDContract.connect(admin).tokenURI(39)
 
    console.log("xxl uri : ",uri);
  
    
}

main();

