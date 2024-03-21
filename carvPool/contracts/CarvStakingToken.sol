// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "@openzeppelin/contracts-upgradeable/token/ERC20/ERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";


// import "hardhat/console.sol";
contract CarvStakingToken is ERC20Upgradeable,AccessControlUpgradeable{


    bytes32 public constant MINTER_BURN_ROLE = 0x1fbabc9a8c0a7fda7984eaff273bdabf1f28be7b76990b15a7d7e7bc1eb0dd59;
    
    /**
        @notice Initializes Carv Staking Token
     */
    function __CarvStakingToken_init(string memory _name,string memory _symbol) public initializer()  {


        __ERC20_init(_name,_symbol);

        __AccessControl_init();
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);

    }


    function transfer(address to, uint256 amount) public virtual override returns (bool) {
        revert("do not support");
    }

    function transferFrom(address from, address to, uint256 amount) public virtual override returns (bool) {
        revert("do not support");
    }
    
    function mint(address account,uint256 amount) external{

        require(hasRole(MINTER_BURN_ROLE,msg.sender),"invald signer"); 
        super._mint(account,amount);

    }

    
    function burn(address account, uint256 amount) external {

        require(hasRole(MINTER_BURN_ROLE,msg.sender),"do not have admin role");
        super._burn(account,amount);
    }

}
