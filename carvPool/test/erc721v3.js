/* External Imports */
const { ethers, getChainId, upgrades, network } = require('hardhat')

const chai = require('chai')
const { solidity } = require('ethereum-waffle')
const { expect, assert } = chai

const namehash = require('eth-ens-namehash');
const {
  deployContract,
  deployUpgradeContract,
  isContractTransferSuccess
} = require('../scripts/utils/helper')

const { utils } = require('ethers')
chai.use(solidity)

let soulContract,domain,types,deployer,alice,bob;

describe(`main process`, () => {

  before(`deploy contact Soul`, async () => {

    accounts = await ethers.getSigners()
    deployer = accounts[0];
    alice = accounts[1];
    bob = accounts[2];

    console.log("deployer address :",deployer.address);
    console.log("alice address :",alice.address);
    console.log("bob address :",bob.address);
    //0.soul
    soulContract = await deployUpgradeContract(deployer, "Soul", "Soul", "Soul");

    domain = {
      name: "Soul",
      version: "1",
      chainId: 5611, 
      verifyingContract: soulContract.address 
    }  

    console.log("xxl : --------- ",soulContract.address );

    // date 20231123
    types = {
      MintData: [
          { name: "account", type: "address" },
          { name: "amount", type: "uint256" },
          { name: "ymd", type: "uint256" },
      ]
    }

  })

  // 1. 只能通过carv 方法获得，且carv方法是EIP712 owner签名方法
  it('mint from erc712 ', async function () {


    // let testHash = "0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470";
    let signature = "0x9521ed2de2ab7da994f6f84afbd4b56c7e9701effed928b66390a178600d067944f9be4207ff11a5091df5676f7863b393347c8c6806a4a98d48acd88dbe547b1c"

    // let mintData = {
    //   account:"0xe28c0fb667fdeff12a1a297076d65e8f5294d98b",
    //   amount:20,
    //   ymd:20231225
    // }

    let mintData = {
      account:"0xe28c0fb667fdeff12a1a297076d65e8f5294d98b",
      amount:20,
      ymd:20231226
    }


    let reAddress = await soulContract.connect(deployer).mintSoul(mintData,signature)
    console.log("address is : ",reAddress);
  
  })


})
