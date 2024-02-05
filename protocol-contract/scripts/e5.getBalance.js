const {
    getInitAddress,
    attachContract,
    readConfig,
    isContractTransferSuccess,
} = require('./utils/helper')


const main = async () => {
 

    let { partern } = await getInitAddress();


    let carvIDAddress = await readConfig("1config","CARV_ID_CONTRACT_ADDRESS");
    let carvIDContract = await attachContract("CarvID",carvIDAddress,partern);

    let balance  = await carvIDContract.connect(partern).balanceOf(partern.address);
  
    console.log("approve to reward mint is %s - %s ",carvIDAddress,balance);

    
}

main();

