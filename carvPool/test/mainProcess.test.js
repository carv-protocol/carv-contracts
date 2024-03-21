/* External Imports */
const { ethers } = require('hardhat')
const { time } = require("@nomicfoundation/hardhat-network-helpers");

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

let deployer,alice,bob;
let totalSupply = 100000000000000;
let archerContract,cstContract,carvPoolContract;
let stakeDay = 10;
let stakeAmount = "123";

describe(`main process`, () => {

  before(`deploy contact Soul`, async () => {

    accounts = await ethers.getSigners()
    deployer = accounts[0];
    alice = accounts[1];
    bob = accounts[2];

    console.log("deployer address :",deployer.address);
    console.log("alice address :",alice.address);
    console.log("bob address :",bob.address);

    //archer
    archerContract = await deployContract(alice, "TestERC20", "Archer", "Archer", totalSupply);
   
    // cst
    cstContract = await deployUpgradeContract(deployer, "CarvStakingToken", "CarvStakingToken", "CST");

    //carv pool
    carvPoolContract = await deployUpgradeContract(deployer, "CarvPool", cstContract.address,archerContract.address);

    //add mint role
    await cstContract.connect(deployer).grantRole("0x1fbabc9a8c0a7fda7984eaff273bdabf1f28be7b76990b15a7d7e7bc1eb0dd59",carvPoolContract.address)
  
  })


  //set Staking Day
  it('set Staking Day ', async function () {

    let result = await isContractTransferSuccess(
      await carvPoolContract.setStakingDay(stakeDay)
    );

    if(result){
      result = await carvPoolContract.getStakingDay();
      assert.equal(result,stakeDay);
    }else{
      console.log("carvPoolContract.setStakingDay error ");
    }
  })

  //set stake 
  it('stake archer token', async function () {

    await archerContract.connect(alice).approve(carvPoolContract.address,stakeAmount)
    let result = await isContractTransferSuccess(
      await carvPoolContract.connect(alice).stake(stakeAmount)
    );

    if(result){
      let balance = await archerContract.balanceOf(carvPoolContract.address);
      assert.equal(stakeAmount,balance.toString());

      balance = await cstContract.balanceOf(alice.address);
      assert.equal(stakeAmount,balance.toString());

    }else{
      console.log("carvPoolContract.setStakingDay error ");
    }

  })


  it('vote To Project ', async function () {

		await time.increase(24 * 3600 * (stakeDay + 1));

    let result = await isContractTransferSuccess(
      await carvPoolContract.connect(alice).voteToProject("0x1fbabc9a8c0a7fda7984eaff273bdabf1f28be7b76990b15a7d7e7bc1eb0dd59")
    );

    if(!result){
      console.log("carvPoolContract.setStakingDay error ");
    }

  })

  //set stake 
  it('unstake voting token', async function () {

    let result = await isContractTransferSuccess(
      await carvPoolContract.connect(alice).unstake(stakeAmount)
    );

    if(result){
      let balance = await archerContract.balanceOf(carvPoolContract.address);
      assert.equal("123",balance.toString());

      balance = await cstContract.balanceOf(alice.address);
      assert.equal("0",balance.toString());

    }else{
      console.log("carvPoolContract.setStakingDay error ");
    }

  })


  //set stake 
  it('claim time is not reached', async function () {


    let result = await isContractTransferSuccess(
      await carvPoolContract.connect(alice).claim()
    );

    if(result){

      let balance = await archerContract.balanceOf(carvPoolContract.address);
      assert.equal("123",balance.toString());

    }else{
      console.log("carvPoolContract.setStakingDay error ");
    }

  })

  it('claim time is reached', async function () {

		await time.increase(24 * 3600 * (stakeDay + 1));

    let result = await isContractTransferSuccess(
      await carvPoolContract.connect(alice).claim()
    );

    if(result){

      let balance = await archerContract.balanceOf(carvPoolContract.address);
      assert.equal("0",balance.toString());

    }else{
      console.log("carvPoolContract.setStakingDay error ");
    }

  })

  it('claimTo time is reached', async function () {

    await archerContract.connect(alice).transfer(carvPoolContract.address,stakeAmount)

		await time.increase(24 * 3600 * (stakeDay + 1));

    let result = await isContractTransferSuccess(
      await carvPoolContract.connect(alice).claimTo(alice.address)
    );

    if(result){

      let balance = await archerContract.balanceOf(carvPoolContract.address);
      assert.equal("0",balance.toString());

    }else{
      console.log("carvPoolContract.setStakingDay error ");
    }

  })



})
