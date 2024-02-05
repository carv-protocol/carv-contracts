const {
    getInitAddress,
    attachContract,
    readConfig,
} = require('./utils/helper')

const main = async () => {
    let { admin, tee2 } = await getInitAddress();

    let campaignsServiceAddress = await readConfig("1config", "CAMPAIGNS_SERVICE_CONTRACT_ADDRESS");
    let campaignsServiceContract = await attachContract("CampaignsService", campaignsServiceAddress, admin);

    await campaignsServiceContract.add_tee_role(admin.address);
    //await campaignsServiceContract.add_tee_role(tee2.address);

    let carvIDAddress = await readConfig("1config", "CARV_ID_CONTRACT_ADDRESS");
    let carvIDContract = await attachContract("CarvID", carvIDAddress, admin);

    // await carvIDContract.add_tee_role(admin.address);
    // await carvIDContract.add_tee_role(tee2.address);
    // change the tee address 
    // await carvIDContract.add_tee_role(tee.address);

    // 0x676A37eC9DC13f95133Fa86dBC053370a9417d8B
    // 0x19BAa72643aa11b28cb6251fd7596201778EaD9A
    // await carvIDContract.add_tee_role("0x19BAa72643aa11b28cb6251fd7596201778EaD9A");
    // await campaignsServiceContract.add_tee_role("0x19BAa72643aa11b28cb6251fd7596201778EaD9A");

    // change the tee address 
    // await carvIDContract.add_tee_role(tee.address);

    // 0x676A37eC9DC13f95133Fa86dBC053370a9417d8B
    // await carvIDContract.add_tee_role("0x676A37eC9DC13f95133Fa86dBC053370a9417d8B");
    
}

main();

