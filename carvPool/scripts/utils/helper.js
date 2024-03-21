const { ethers: hEether, upgrades } = require('hardhat');
const fs = require('fs')
const path = require('path')
const axios = require('axios').default;
require('dotenv').config();
const { execSync } = require('child_process')
const { utils } = require('ethers')
const log4js = require('log4js');
log4js.configure({
    appenders: { out: { type: "file", filename: "logs/out.log" } },
    categories: { default: { appenders: ["out"], level: "info" } }
});

const namehash = require('eth-ens-namehash');

const logger = log4js.getLogger();
let cmd = "", showInfo = "", result = "", no = 0;

const writeConfig = async (fromFile, toFile, key, value) => {

    let fromFullFile = path.resolve(getConfigPath(), './' + fromFile + '.json')
    let contentText = fs.readFileSync(fromFullFile, 'utf-8');
    let data = JSON.parse(contentText);
    data[key] = value;

    let toFullFile = path.resolve(getConfigPath(), './' + toFile + '.json')
    fs.writeFileSync(toFullFile, JSON.stringify(data, null, 4), { encoding: 'utf8' }, err => { })

}

const readConfig = async (fromFile, key) => {

    let fromFullFile = path.resolve(getConfigPath(), './' + fromFile + '.json')
    let contentText = fs.readFileSync(fromFullFile, 'utf-8');
    let data = JSON.parse(contentText);
    return data[key];

}

function sleep(ms) {

    return new Promise(resolve => setTimeout(resolve, ms));
}

const getConfigPath = () => {
    //return "scripts/config"
    return path.resolve(__dirname, '.') + "/config"
}

const isTxSuccess = async (resultObj) => {

    let repObj = await resultObj.wait();
    console.log(repObj);
    return repObj.status == 1 ? true : false

}


function hex2a(hexx) {
    var hex = hexx.toString();//force conversion
    var str = '';
    for (var i = 0; i < hex.length; i += 2)
        str += String.fromCharCode(parseInt(hex.substr(i, 2), 16));
    return str;
}

const gasPrice = "20000000000"
const gasLimit = 0x7a1200
const fixLen = 16
async function deployContract(account, contractName, ...args) {

    const contractFactory = await ethers.getContractFactory(contractName, account)
    const contract = await contractFactory.connect(account).deploy(
        ...args,
        { gasPrice, gasLimit }
    );

    // console.log(contractName.padEnd(fixLen, ' ') + " address is : ", contract.address);
    console.log(contractName + " address is : ", contract.address);
    return contract

}

async function deployUpgradeContract(account, contractName, ...args) {

    const contractFactory = await ethers.getContractFactory(contractName, account)

    const intContractName = "__" + contractName + "_init"
    const contract = await upgrades.deployProxy(
        contractFactory,
        args,
        { initializer: intContractName }
    );

    // console.log(contractName.padEnd(fixLen, ' ') + " address is : ", contract.address);
    console.log(contractName + " address is : ", contract.address);

    return contract

}


async function isContractTransferSuccess(txObj) {

    let repObj = await txObj.wait();
    console.log("repObj : ",repObj.gasUsed);
    if (repObj.status == 1) {
        return true
    }
    return false;

}

async function getImplAddress(proxyAddress){

    try{
        console.log("getImplAddress 1 ",proxyAddress);
        // const currentImplAddress = await upgrades.erc1967.getImplementationAddress(proxyAddress);
        const currentImplAddress = await upgrades.erc1967.getImplementationAddress(proxyAddress);
        return currentImplAddress;
    }catch(e){
        console.log("xxl getImplAddress ",e);
    }

}


async function attachContract(contractName,contractAddress,account){

    const contractFactory = await ethers.getContractFactory(contractName, account)
    let contract = await contractFactory.connect(account).attach(contractAddress); 

    console.log(contractName + " address is : ", contract.address);

    return contract;

}
let nameConfigMap ={
    "Soul":"SOUL_CONTRACT_ADDRESS"
}


async function upgradeByContractName(contractName){


    accounts = await ethers.getSigners()
    admin = accounts[0];
    // let rewardsContract = await deployUpgradeContract(admin,contractName,"v0.0.1");
    let contractAddress = await readConfig("1config",nameConfigMap[contractName]);
    let updObj = await upgradeContract(contractName,contractAddress,admin);
    let rep = await updObj.deployTransaction.wait();
  
    console.log(rep);
    if(rep.status == 1){
        console.log(contractName + " upgrade is OK");
    }else{
        console.log(contractName + " upgrade is failed");
    }


}

async function upgradeContract(contractName,contractAddress,account){


    const contractFactory = await ethers.getContractFactory(contractName,account)

    console.log("xxl upgradeContract",account.address,contractAddress);
    return await upgrades.upgradeProxy(
        contractAddress, 
        contractFactory,{
            from:account.address,
            gasPrice: gasPrice * 1.1,
            gasLimit: gasLimit * 1.1
        },
    );

}

  
async function forceUpgradeByContractName(contractName){


    accounts = await ethers.getSigners()
    admin = accounts[0];

    // let rewardsContract = await deployUpgradeContract(admin,contractName,"v0.0.1");
    let contractAddress = await readConfig("1config",nameConfigMap[contractName]);
    await forceImportContract(contractName,contractAddress,admin);

}


async function forceImportContract(contractName,contractAddress,account){

    const contractFactory = await hEether.getContractFactory(contractName,account)

    let updObj = await upgrades.forceImport(
        contractAddress, 
        contractFactory,{
            from:account.address,
            gasPrice: gasPrice * 1.1,
            gasLimit: gasLimit * 1.1
        },
    );

    console.log("xxl updObj ",updObj);
    let rep = await updObj.deployTransaction.wait();
  
    if(rep.status == 1){
        console.log(contractName + " forceImportContract is OK");
    }else{
        console.log(contractName + " forceImportContract is failed");
    }

}

module.exports = {
    writeConfig,
    readConfig,
    sleep,

    isTxSuccess,
    hex2a,

    deployContract,
    deployUpgradeContract,
    isContractTransferSuccess,

    getImplAddress,
    attachContract,
    upgradeContract,
    upgradeByContractName,
    forceUpgradeByContractName
}