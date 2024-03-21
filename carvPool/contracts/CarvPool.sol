// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "@openzeppelin/contracts-upgradeable/token/ERC20/ERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";

import "./interface/IToken.sol";
import "hardhat/console.sol";

contract CarvPool is AccessControlUpgradeable{


    address private carvStakingToken;
    address private archerToken;
    uint256 private stakingDay;

    struct StakingData{
        uint256 timestamp;
        uint256 amount;
    }

    mapping(
        address => StakingData[]
    )  addressStakingMap;
    
    event Stake(
        address from,
        uint256 amount
    );

    event Unstake(
        address from,
        uint256 timestamp,
        uint256 amount
    );

    event VoteToProject(
        address from,
        bytes32 projectHash,
        uint256 amount
    );

    modifier only_admin() {
        _only_admin();
        _;
    }

    function _only_admin() private view {
        require(
            hasRole(DEFAULT_ADMIN_ROLE, msg.sender),
            "sender doesn't have admin role"
        );
    }

    function __CarvPool_init(address _carvStakingToken,address _archerToken) public initializer()  {

        __AccessControl_init();
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);

        carvStakingToken = _carvStakingToken;
        archerToken = _archerToken;

    }

    function setStakingDay(uint256 _stakingDay) external only_admin{

        stakingDay = _stakingDay;
    }

    function getStakingDay() external view returns(uint256){

        return stakingDay;
    }

    function stake(uint256 _stakingAmount) external{

        //check balance
        require(IToken(archerToken).balanceOf(msg.sender) > _stakingAmount,"do not have enough token");

        //transfer to carvPool contract
        IToken(archerToken).transferFrom(msg.sender,address(this),_stakingAmount);

        //mint carv voting token
        IToken(carvStakingToken).mint(msg.sender,_stakingAmount);

        //event Sake Info
        emit Stake(msg.sender,_stakingAmount);
    }

    //
    function unstake(uint256 _unstakingAmount) external{

        //check balance
        require(IToken(carvStakingToken).balanceOf(msg.sender) >= _unstakingAmount,"do not have voting token");

        //burn carv voting token
        IToken(carvStakingToken).burn(msg.sender,_unstakingAmount);
        uint256 currentTimestamp = block.timestamp;
        
        StakingData memory stakingData;

        stakingData.timestamp= currentTimestamp;
        stakingData.amount= _unstakingAmount;
        addressStakingMap[msg.sender].push(stakingData);

        //event unstaking list
        emit Unstake(msg.sender,currentTimestamp,_unstakingAmount);

    }

    function claim() external{
        claimTo(msg.sender); 
    }

    function claimTo(address _to) public{

        StakingData[] memory dayList = addressStakingMap[_to];
        // StakingData[] memory newDayList;
        uint256 len = dayList.length;
        uint i = 0;

        for(i = 0 ; i < len ; i ++ ){

            uint256 statingDay = dayList[i].timestamp + stakingDay * 24 * 3600;
            if(statingDay <= block.timestamp){
                // transfer to carvPool contract
                IToken(archerToken).transfer(_to,dayList[i].amount);
            }else{
                addressStakingMap[_to].push(dayList[i]);
            }
            
        }

        // addressStakingMap[_to] = dayList;

    }

    function voteToProject(bytes32 _projectHash) external {

        //check balance
        uint carvVotkingBalance = IToken(carvStakingToken).balanceOf(msg.sender);
        require(carvVotkingBalance > 0 ,"do not have voting token");

        emit VoteToProject(msg.sender,_projectHash,carvVotkingBalance);

    }

}
