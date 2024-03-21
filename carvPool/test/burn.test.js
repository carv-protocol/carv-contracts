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

    // console.log("deployer address :",deployer.address);
    // console.log("alice address :",alice.address);
    // console.log("bob address :",bob.address);
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
  it('burn from erc712 ', async function () {
      // console.log("address is : ",reAddress);  

      await soulContract.connect(deployer).testMint(alice.address,10)

      let bal = await soulContract.balanceOf(alice.address);
      expect(bal.toString()).equal(10 + "")

      bal = await soulContract.totalSupply();
      expect(bal.toString()).equal(10 + "")

      //
      await soulContract.connect(deployer).burn(alice.address,10)

      bal = await soulContract.balanceOf(alice.address);
      expect(bal.toString()).equal(0 + "")

      bal = await soulContract.totalSupply();
      expect(bal.toString()).equal(0 + "")



  })




})
