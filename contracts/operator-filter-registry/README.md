# Operator Filter Registry

## **Note on Grace Period**

Starting **January 2nd, 2023**, Opensea will begin validating creator fee enforcement for new collections on all supported EVM chains. After January 2nd, 2023, if OpenSea is unable to validate enforcement, OpenSea will make creator fees **optional** for that collection. Older collections will continue to have their fees enforced on OpenSea, **including on Ethereum Mainnet** (previously, enforcement was already required on Ethereum Mainnet).

You may read more on [OpenSea's Twitter](https://twitter.com/opensea/status/1600913295300792321).

## Introduction

This repository contains a number of tools to help token contracts manage the operators allowed to transfer tokens on behalf of users - including the smart contracts and delegates of marketplaces that do not respect creator earnings.

This is not a foolproof approach - but it makes bypassing creator earnings less liquid and easy at scale.

## How it works

Token smart contracts may register themselves (or be registered by their "owner") with the `OperatorFilterRegistry`. Token contracts or their "owner"s may then curate lists of operators (specific account addresses) and codehashes (smart contracts deployed with the same code) that should not be allowed to transfer tokens on behalf of users.

## Creator Earnings Enforcement

OpenSea will enforce creator earnings for smart contracts that make best efforts to filter transfers from operators known to not respect creator earnings.

This repository facilitates that process by providing smart contracts that interface with the registry automatically, including automatically subscribing to OpenSea's list of filtered operators.

When filtering operators, use of this registry is not required, nor is it required for a token contract to "subscribe" to OpenSea's list within this registry. Subscriptions can be changed or removed at any time. Filtered operators and codehashes may likewise be added or removed at any time.

Contract owners may implement their own filtering outside of this registry, or they may use this registry to curate their own lists of filtered operators. However, there are certain contracts that are filtered by the default subscription, and must be filtered in order to be eligible for creator earnings enforcement on OpenSea.

## Note on [EIP-2981](https://eips.ethereum.org/EIPS/eip-2981)

Implementing EIP-2981 is not sufficient for a token to be eligible for creator earnings on OpenSea.

While sometimes described as "on-chain," EIP-2981 only provides a method to determine what the appropriate creator earnings should be for a sale. EIP-2981 does not provide any mechanism of on-chain enforcement of those earnings.

## Filtered addresses


Ownership of this list [has been transferred](https://etherscan.io/tx/0xf15e8ac08a333b2e4f884250ace94baccf7ba8908c119736d9cc8f063183a496/advanced#eventlog) to the [Creator Ownership Research Institute](https://corinstitute.co/) to administer. You may read more on [OpenSea's Twitter](https://twitter.com/opensea/status/1600913295300792321).

Entries in this list are added according to the following criteria:

-   If the application most commonly used to interface with the contract gives buyers and sellers the ability to bypass creator earnings when a similar transaction for the same item would require creator earnings payment on OpenSea.io
-   If the contract is facilitating the evasion of on-chain creator earnings enforcement measures. For example, the contract uses a wrapper contract to bypass earnings enforcement.

<table>
<tr>
<th>Name</th>
<th>Address</th>
<th>Network</th>
</tr>

<tr>
<td>Blur.io ExecutionDelegate</td>
<td >
0x00000000000111AbE46ff893f3B2fdF1F759a8A8
</td>
<td >
Ethereum Mainnet
</td>
</tr>

<tr>
<td>LooksRare TransferManagerERC721</td>
<td>0xf42aa99F011A1fA7CDA90E5E98b277E306BcA83e</td>
<td>Ethereum Mainnet</td>
</tr>

<tr>
<td>LooksRare TransferManagerERC1155</td>
<td>0xFED24eC7E22f573c2e08AEF55aA6797Ca2b3A051</td>
<td>Ethereum Mainnet</td>
</tr>

<tr>
<td>SudoSwap LSSVMPairEnumerableERC20</td>
<td>0xD42638863462d2F21bb7D4275d7637eE5d5541eB</td>
<td>Ethereum Mainnet</td>
</tr>

<tr>
<td>SudoSwap LSSVMPairEnumerableETH</td>
<td>0x08CE97807A81896E85841d74FB7E7B065ab3ef05</td>
<td>Ethereum Mainnet</td>
</tr>

<tr>
<td>SudoSwap LSSVMPairMissingEnumerableERC20</td>
<td>0x92de3a1511EF22AbCf3526c302159882a4755B22</td>
<td>Ethereum Mainnet</td>
</tr>

<tr>
<td>SudoSwap LSSVMPairMissingEnumerableETH</td>
<td>0xCd80C916B1194beB48aBF007D0b79a7238436D56</td>
<td>Ethereum Mainnet</td>
</tr>

<tr>
<td>SudoSwap LSSVMPairFactory</td>
<td>0xb16c1342E617A5B6E4b631EB114483FDB289c0A4</td>
<td>Ethereum Mainnet</td>
</tr>

<tr>
<td>NFTX NFTXMarketplaceZap</td>
<td>0x0fc584529a2aefa997697fafacba5831fac0c22d</td>
<td>Ethereum Mainnet</td>
</tr>

</table>

## Deployments

<table>
<tr>
<th>Network</th>
<th>CORI Subscription TimelockController</th>
<th>OperatorFilterRegistry</th>
<th>CORI Curated Subscription Address</th>
</tr>

<tr><td>Ethereum</td>
<td>

0x178AD648e66815E1B01791eBBdbF7b2D7C5B1626

</td>
<td rowspan="20">

[0x000000000000AAeB6D7670E522A718067333cd4E](https://etherscan.io/address/0x000000000000AAeB6D7670E522A718067333cd4E#code)

</td><td rowspan="20">

0x3cc6CddA760b79bAfa08dF41ECFA224f810dCeB6

</td></tr>

<tr>
<td>Polygon</td>

<td>
0x87bCD4735CbCF9CE98ea2822fBf3F05F2ce10f96
</td>
<td></td>
<td></td>
</tr>

<tr><td>Goerli</td><td rowspan="20">0xe3A6CD067a1193b903143C36dA00557c9d95C41e</td></tr>
<tr><td>Mumbai</td></tr>
<tr><td>Optimism</td></tr>
<tr><td>Optimism Goerli</td></tr>
<tr><td>Arbitrum One</td></tr>
<tr><td>Arbitrum Nova</td></tr>
<tr><td>Arbitrum Goerli</td></tr>
<tr><td>Avalanche</td></tr>
<tr><td>Avalanche Fuji</td></tr>
<tr><td>Klaytn</td></tr>
<tr><td>Baobab</td></tr>
<tr><td>BSC</td></tr>
<tr><td>BSC Testnet</td></tr>
<tr><td>Gnosis</td></tr>

</table>

To mitigate abuse of the CORI curated subscription of filtered operators and codehashes, the CORI curated subscription is owned by a `TimelockController`, which is in turn owned by a multi-signature wallet. Any update to CORI's list of filtered operators must be approved by at least two members of the Creator Ownership Research Institute, and is then subject to a minimum 24-hour delay before being executed. During this time, updates may be reviewed and revoked. 

## Usage

Token contracts that wish to manage lists of filtered operators and restrict transfers from them may integrate with the registry easily with tokens using the [`OperatorFilterer`](src/OperatorFilterer.sol) and [`DefaultOperatorFilterer`](src/DefaultOperatorFilterer.sol) contracts. These contracts provide modifiers (`onlyAllowedOperator` and `onlyAllowedOperatorApproval`) which can be used on the token's transfer methods to restrict transfers from or approvals of filtered operators.

See the [ExampleERC721](src/example/ExampleERC721.sol) and [ExampleERC1155](src/example/ExampleERC1155.sol) contracts for basic implementations that inherit the `DefaultOperatorFilterer`.

## Getting Started with Foundry

This package can be installed into a [Foundry](https://github.com/foundry-rs/foundry#installation) project with the following command

```bash
forge install ProjectOpenSea/operator-filter-registry
```

With default remappings provided by `forge remappings`, the default operator filterer can be imported into your project with the following statement

```solidity
import "operator-filter-registry/DefaultOperatorFilterer.sol";
```

See NPM section below for further details.

## Getting started with NPM

This package can be found on NPM to integrate with tools like hardhat.

### Installing

with npm

```bash
npm i operator-filter-registry
```

with yarn

```bash
yarn add operator-filter-registry
```

### Default usage

Add to your smart contract in the import section:

```solidity
import "operator-filter-registry/src/DefaultOperatorFilterer.sol";
```

Next extend from `DefaultOperatorFilterer`

```
contract MyNft is
  DefaultOperatorFilterer,
  // remaining inheritance here
{
```

Finally, override the ERC721 transfer and approval methods (modifiers are overridable as needed)

```
    function setApprovalForAll(address operator, bool approved) public override onlyAllowedOperatorApproval(operator) {
        super.setApprovalForAll(operator, approved);
    }

    function approve(address operator, uint256 tokenId) public override onlyAllowedOperatorApproval(operator) {
        super.approve(operator, tokenId);
    }

    function transferFrom(address from, address to, uint256 tokenId) public override onlyAllowedOperator(from) {
        super.transferFrom(from, to, tokenId);
    }

    function safeTransferFrom(address from, address to, uint256 tokenId) public override onlyAllowedOperator(from) {
        super.safeTransferFrom(from, to, tokenId);
    }

    function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory data)
        public
        override
        onlyAllowedOperator(from)
    {
        super.safeTransferFrom(from, to, tokenId, data);
    }
```

# Smart Contracts

## `OperatorFilterRegistry`

`OperatorFilterRegistry` lets a smart contract or its [EIP-173 `Owner`](https://eips.ethereum.org/EIPS/eip-173) register a list of addresses and code hashes to deny when `isOperatorBlocked` is called.

It also supports "subscriptions," which allow a contract to delegate its operator filtering to another contract. This is useful for contracts that want to allow users to delegate their operator filtering to a trusted third party, who can continuously update the list of filtered operators and code hashes. Subscriptions may be cancelled at any time by the subscriber or its `Owner`.

### updateOperator(address registrant, address operator, bool filtered)

This method will toggle filtering for an operator for a given registrant. If `filtered` is `true`, `isOperatorAllowed` will return `false`. If `filtered` is `false`, `isOperatorAllowed` will return `true`. This can filter known addresses.

### updateCodeHash(address registrant, bytes32 codeHash, bool filtered)

This method will toggle filtering on code hashes of operators given registrant. If an operator's `EXTCODEHASH` matches a filtered code hash, `isOperatorAllowed` will return `true`. Otherwise, `isOperatorAllowed` will return `false`. This can filter smart contract operators with different addresses but the same code.

## `OperatorFilterer`

This smart contract is meant to be inherited by token contracts so they can use the following:

-   `onlyAllowedOperator` modifier for `transferFrom` and `safeTransferFrom` methods.
-   `onlyAllowedOperatorApproval` modifier for `approve` and `setApprovalForAll` methods.

On construction, it takes three parameters:

-   `address registry`: the address of the `OperatorFilterRegistry` contract
-   `address subscriptionOrRegistrantToCopy`: the address of the registrant the contract will either subscribe to, or do a one-time copy of that registrant's filters. If the zero address is provided, no subscription or copies will be made.
-   `bool subscribe`: if true, subscribes to the previous address if it was not the zero address. If false, copies existing filtered addresses and codeHashes without subscribing to future updates.

Please note that if your token contract does not provide an owner with [EIP-173](https://eips.ethereum.org/EIPS/eip-173), it must provide administration methods on the contract itself to interact with the registry otherwise the subscription will be locked to the options set during construction.

### `onlyAllowedOperator(address operator)`

This modifier will revert if the `operator` or its code hash is filtered by the `OperatorFilterRegistry` contract.

## `DefaultOperatorFilterer`

This smart contract extends `OperatorFilterer` and automatically configures the token contract that inherits it to subscribe to OpenSea's list of filtered operators and code hashes. This subscription can be updated at any time by the owner by calling `updateSubscription` on the `OperatorFilterRegistry` contract.

Please note that if your token contract does not provide an owner with [EIP-173](https://eips.ethereum.org/EIPS/eip-173), it must provide administration methods on the contract itself to interact with the registry otherwise the subscription will be locked to the options set during construction.

## `OwnedRegistrant`

This `Ownable` smart contract is meant as a simple utility to enable subscription addresses that can easily be transferred to a new owner for administration. For example: an EOA curates a list of filtered operators and code hashes, and then transfers ownership of the `OwnedRegistrant` to a multisig wallet.

# Validation

When the first token is minted on an NFT smart contract, OpenSea checks if the filtered operators on that network (Ethereum Mainnet, Goerli, Polygon, etc.) are allowed to transfer the token. If they are, OpenSea will mark the collection as ineligible for creator earnings. Otherwise, OpenSea will enforce creator earnings on the collection.

If at a later point, OpenSea detects orders being fulfilled by filtered operators, OpenSea will mark the collection as ineligible for creator earnings going forward.

The included [validation test](test/validation/Validation.t.sol) runs the same checks that OpenSea does when first creating a collection page, and can be extended with custom setup for your token contract.

The test can be configured to test against deployed contracts on a network fork with a `.env` file following the [sample.env](sample.env). You may need to supply a custom [`[rpc_endpoints]`](https://book.getfoundry.sh/reference/config/testing#rpc_endpoints) in the `foundry.toml` file for forking to work properly.

To run only the validation tests, run

```bash
forge test --match-contract ValidationTest -vvv
```

See the [Foundry project page](https://github.com/foundry-rs/foundry#installation) for Foundry installation instructions.

# Audit

The contracts in this repository have been audited by [OpenZeppelin](https://openzeppelin.com/). You may read the final audit report [here](audit/OpenSea%20Operator%20Filteer%20Audit%20Report.pdf).

# License

[MIT](LICENSE) Copyright 2022 Ozone Networks, Inc.
