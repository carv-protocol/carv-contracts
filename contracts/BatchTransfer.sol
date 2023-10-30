// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.0;

import "./@openzeppelin/contracts/access/AccessControl.sol";
import "./@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract BatchTransfer is AccessControl {
    bytes32 public constant TRANSFER_ROLE = keccak256("TRANSFER_ROLE");

    event BatchTransferCompleted(address indexed operator, uint totalAmount);
    event RemainingETHTransferred(address indexed operator, uint remainingAmount);

    constructor () {
        _setupRole(DEFAULT_ADMIN_ROLE, _msgSender());
    }

    function batchTransferETH(address[] memory _to, uint[] memory _values) public payable onlyRole(TRANSFER_ROLE) {
        require(_to.length == _values.length, "Mismatched transfer inputs");
        uint total = 0;
        for (uint i = 0; i < _values.length; i++) {
            total += _values[i];
        }
        require(msg.value >= total, "Sent ETH is less than the total required");
        for (uint i = 0; i < _to.length; i++) {
            payable(_to[i]).transfer(_values[i]);
        }
        emit BatchTransferCompleted(msg.sender, total);

        // Transfer back the remaining ETH to the caller
        if (msg.value > total) {
            uint remainingAmount = msg.value - total;
            payable(msg.sender).transfer(remainingAmount);
            emit RemainingETHTransferred(msg.sender, remainingAmount);
        }
    }

    function batchTransferTokenFrom(address owner, address _tokenAddress, address[] memory _to, uint[] memory _values) public onlyRole(TRANSFER_ROLE) {
        require(_to.length == _values.length, "Mismatched transfer inputs");
        IERC20 token = IERC20(_tokenAddress);
        uint total = 0;
        for (uint i = 0; i < _to.length; i++) {
            require(token.transferFrom(owner, _to[i], _values[i]), "Transfer failed");
            total += _values[i];
        }
        emit BatchTransferCompleted(owner, total);
    }

    function grantTransferRole(address account) public onlyRole(DEFAULT_ADMIN_ROLE) {
        grantRole(TRANSFER_ROLE, account);
    }

    function revokeTransferRole(address account) public onlyRole(DEFAULT_ADMIN_ROLE) {
        revokeRole(TRANSFER_ROLE, account);
    }
}
