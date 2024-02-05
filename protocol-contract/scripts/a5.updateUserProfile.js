const {
    getInitAddress,
    attachContract,
    readConfig,
    isContractTransferSuccess,
    getTestData
} = require('./utils/helper')

const { ethers } = require('hardhat')

const main = async () => {
 

    let { admin,user,tee } = await getInitAddress();
    let {multi_user_ids,new_user_profile,new_profile_verison} = await getTestData();

    let carvIDAddress = await readConfig("1config","CARV_ID_CONTRACT_ADDRESS");
    let carvIDContract = await attachContract("CarvID",carvIDAddress,admin);

    // 
    const dataHash = ethers.utils.keccak256(
        ethers.utils.toUtf8Bytes(JSON.stringify(multi_user_ids))
    );
    const dataHashBin = ethers.utils.arrayify(dataHash);
    const ethHash = ethers.utils.hashMessage(dataHashBin);

    // const wallet = new ethers.Wallet(process.env.PK);
    const signature = await tee.signMessage(dataHashBin);

    let userIDS = new Array();
    multi_user_ids.forEach(
      (MultiUserIDObj) => {
        userIDS.push(MultiUserIDObj.userID)
      }
    )

    let isSucess = await isContractTransferSuccess(
     await carvIDContract.connect(tee).update_user_profile(
      user.address,tee.address,new_user_profile,new_profile_verison,ethHash,userIDS,signature)
    )

    if(isSucess){

      let return_profile = await carvIDContract.get_user_by_address(user.address);
      console.log(return_profile);

    }else{
      console.log("update_user_profile error ");
    }




    
}

main();

