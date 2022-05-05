// SPDX-License-Identifier: Apache-2.0
pragma solidity 0.8.11;

import "./@openzeppelin/contracts/proxy/ERC1967/ERC1967Proxy.sol";

/**
 * @title CarvAchievementsProxy
 * @author Carv
 * @custom:security-contact security@carv.io
 */
contract CarvAchievementsProxy is ERC1967Proxy {
    constructor(address _logic) ERC1967Proxy(_logic, "") {}

    function implementation() external view returns (address) {
        return _implementation();
    }
}
