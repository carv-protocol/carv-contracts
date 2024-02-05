const { ethers, getChainId, upgrades, network } = require('hardhat')
const { utils } = require('ethers')
const chai = require('chai')
const { solidity } = require('ethereum-waffle')
const { expect, assert } = chai

const {
    deployContract,
    deployUpgradeContract,
    isContractTransferSuccess
} = require('../scripts/utils/helper')

chai.use(solidity)

/*
Note:
step1: `npx hardhat node` to start a local node
step2  `./tee --SIM=true` to start in SIM mod, and get TEE Addr from /tee/info
step3: `npx hardhat run scripts/dev1.deployToLocalNode.js --network localhost` 
in a new terminal, to deploy test contracts
*/
async function main() {
    let campaignsContract, usdtContract, rewardsContract, carvIDContract, campaignsServiceContract;
    let deployer, partner, user
    const campaign_id = "bd0078f7-4a48-5764-92bf-353ccbcea6e2"
    const amount = 200
    const num_limited = 10
    let totalSupply = 100000000000000

    let chainID = await getChainId();
    let accounts = await ethers.getSigners()
    deployer = accounts[0];
    partner = accounts[1];
    user = accounts[2];
    console.log("chainID is :" + chainID);
    console.log("deployer   :" + deployer.address);
    console.log("partner    :" + partner.address);
    console.log("user       :" + user.address);

    const teeAddr = "0xC47562F85F9217368BE2Bb958C4121a382778bAa"

    //Deploy Contracts
    usdtContract = await deployContract(partner, "TestERC20", "USDT", "USDT", totalSupply);
    rewardsContract = await deployUpgradeContract(deployer, "Rewards", "v0.0.1");
    campaignsContract = await deployUpgradeContract(deployer, "Campaigns", "v0.0.1", rewardsContract.address);
    carvIDContract = await deployUpgradeContract(deployer, "CarvID", "v0.0.1", "CarvID", "CarvID");
    campaignsServiceContract = await deployUpgradeContract(
        deployer, "CampaignsService", "v0.0.1",
        rewardsContract.address,
        campaignsContract.address
    );
    await rewardsContract.set_service_address(campaignsServiceContract.address);
    await campaignsContract.set_service_address(campaignsServiceContract.address);
    await campaignsServiceContract.add_tee_role(teeAddr);
    await carvIDContract.add_tee_role(teeAddr);

    // Init Campaign
    let requirementsJson = {
        "and": [
            {
                "type": "quest",
                "args": {
                    "desc": "Twitter Verification",
                    "expected_value": 1,
                    "user_value": 0,
                    "user_authorized": false,
                    "quest_id": "1ff00deb-c5b5-52c7-a57a-4a6a509c84c8",
                    "quest_type": "auth_twitter_verification",
                    "quest_properties": {
                    }
                }
            },
            {
                "type": "quest",
                "args": {
                    "desc": "Steam Verification",
                    "expected_value": 1,
                    "user_value": 0,
                    "user_authorized": false,
                    "quest_id": "1ff00deb-c5b5-52c7-a57a-4a6a509c84c9",
                    "quest_type": "auth_steam_verification",
                    "quest_properties": {
                    }
                }
            },
            {
                "type": "quest",
                "args": {
                    "desc": "Steam Play Hours",
                    "expected_value": 1,
                    "user_value": 0,
                    "user_authorized": false,
                    "quest_id": "1ff00deb-c5b5-52c7-a57a-4a6a509c84c0",
                    "quest_type": "steam_playtime",
                    "quest_properties": {
                        "game_id": "12345"
                    }
                }
            }
        ]
    }

    let campaign_info = {
        campaign_id: campaign_id,
        creator: partner.address,
        campaign_type: 0,
        url: "http://ipfs",
        reward_contract: usdtContract.address,
        reward_total_amount: amount,
        reward_count: num_limited,
        status: 0,
        start_time: 1693386809888,
        end_time: 1695386809888,
        requirements: JSON.stringify(requirementsJson),
    }

    let reward_info = {
        campaign_id: campaign_id,
        user_address: deployer.address,
        reward_amount: amount,
        contract_address: usdtContract.address,
        contract_type: 1
    }

    var isSuccess = await isContractTransferSuccess(
        await usdtContract.connect(partner).approve(rewardsContract.address, amount)
    )

    isSuccess = await isContractTransferSuccess(
        await campaignsContract.connect(partner).submit_campaign(reward_info, campaign_info)
    )

    if (isSuccess) {
        let campaign_return = await campaignsContract.get_campaign_by_id(campaign_id);
        assert.equal(campaign_return, campaign_return)

        let rewardBalance = await usdtContract.balanceOf(rewardsContract.address)
        assert.equal(rewardBalance.toString(), amount.toString())
    }

    isSuccess = await isContractTransferSuccess(
        await campaignsServiceContract.connect(deployer).approve_campaign(campaign_id)
    )

    if (isSuccess) {
        let campaign_return = await campaignsContract.get_campaign_by_id(campaign_id);
        assert.equal(campaign_return.status, 1)
    }

    // Init User
    let user_info = {
        token_id: 1,
        user_profile_path: "",
        profile_version: 0
    }

    // Mint ERC7231 for user
    isSuccess = await isContractTransferSuccess(
        await carvIDContract.connect(user).mint()
    )
    if (isSuccess) {
        mint_return = await carvIDContract.get_user_by_address(user.address)
        console.log(mint_return);
    }

    if (isSuccess) {
        user_return = await carvIDContract.get_user_by_address(user.address)
        assert.equal(user_info.token_id, user_return.token_id)
        assert.equal(user_info.user_profile_path, user_return.user_profile_path)
        assert.equal(user_info.profile_version, user_return.profile_version)
    }

    // Test sign message
    var tmp = "Hello World"
    var signature = await deployer.signMessage(tmp);
    console.log("deployer signature: " + signature)

    // Transfer ether to TEE as gas
    await deployer.sendTransaction({
        to: teeAddr,
        value: ethers.utils.parseEther("1.0"),
    });
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main().catch((error) => {
    console.error(error);
    process.exitCode = 1;
});