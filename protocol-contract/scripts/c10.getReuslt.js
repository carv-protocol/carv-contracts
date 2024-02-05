
const { ethers, getChainId} = require('hardhat')
const { 
    readConfig,
    hex2a
} = require('./utils/helper')
const { utils} = require('ethers')

const EthCrypto = require('eth-crypto');

const main = async () => {

    console.log("7 request Ethereum Post ....");

    let chainID = await getChainId();
    let accounts = await ethers.getSigners()
    let deployer = accounts[0];
    console.log("chainID is :" + chainID + " address :" + deployer.address);

    const DataConsumer__Contract = await ethers.getContractFactory('DataConsumer',deployer)
    let dataConsumerAddress = await readConfig("1config","DATACONSUMER_ADDRESS");
    let dataConsumer = await DataConsumer__Contract.connect(deployer).attach(dataConsumerAddress);
    console.log("dataConsumer is :" + dataConsumerAddress);

    let result = await dataConsumer.getReuslt();
    let encryptedString = getReusltString(result);
    console.log("data from contract :",encryptedString);
 
    let privateKey = "0xa6392433fe30f2bf8564228240eddd41c7ad12ab5332438254054896790ceebe"
    const encryptedObject = EthCrypto.cipher.parse(encryptedString)
    
    const decrypted = await EthCrypto.decryptWithPrivateKey(
        privateKey,
        encryptedObject
    );
    console.log("raw data is : ",decrypted);



















    ////////



    // ///---///
    // let privateKey = "0xa6392433fe30f2bf8564228240eddd41c7ad12ab5332438254054896790ceebe"

    // const publicKey = EthCrypto.publicKeyByPrivateKey(privateKey);
    // console.log("xxl publicKey : ",publicKey);

    // // we have to stringify the payload before we can encrypt it
    // const encrypted = await EthCrypto.encryptWithPublicKey(
    //     publicKey, // by encrypting with bobs publicKey, only bob can decrypt the payload with his privateKey
    //     JSON.stringify({
    //         "data":"xuxinlai@gmail.com"
    //     }) 
    // );

    // console.log("xxl encrypted ",encrypted);
    // const encryptedString = EthCrypto.cipher.stringify(encrypted);
    // console.log("xxl encryptedString ",encryptedString);

    // // we parse the string into the object again
    // const encryptedObject = EthCrypto.cipher.parse(encryptedString);

    // const decrypted = await EthCrypto.decryptWithPrivateKey(
    //     privateKey,
    //     encryptedObject
    // );

    // //console.log("xxl result ",decrypted);
    // const decryptedPayload = JSON.parse(decrypted);
    // console.log(decryptedPayload);

    // ///---///
    // let address = await dataConsumer.calculateAddress("0x" + publicKey);
    // console.log("call consume address : ",address);

    // ///---///



}


function getReusltString(rawHex){

    let rawString = hex2a(rawHex);
    let jsonObj = rawString.split(":");
    return jsonObj[1].replace("}","").replace("\"","")

}

main();
