const {
    getInitAddress,
    attachContract,
    readConfig,
} = require('./utils/helper')

const main = async () => {
    let { admin, tee } = await getInitAddress();


    let carvIDAddress = await readConfig("1config", "CARV_ID_CONTRACT_ADDRESS");
    let carvIDContract = await attachContract("CarvID", carvIDAddress, admin);

    let isHas = await carvIDContract.hasRole(admin.address,"0x19BAa72643aa11b28cb6251fd7596201778EaD9A");

    console.log("is has role : ",isHas);
}

main();

