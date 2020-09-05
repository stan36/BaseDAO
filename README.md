# BaseDAO

##Personal Introduction

My name is Christopher Dixon. I am a full stack web3 developer specializing in solidity, react and their surrounding technologies.
I have experience with technologies like Truffle, Remix and the OpenZeppelin SDK as well as NODE.js, Web3.js and
the MERN stack. I am the lead developer for the meToken smart contract set as well as its react based dApp StakeOnMe.com where we recently released
a 1.5 version update that provided a speed boost to the website through the use of an AWS based Express.js/ MongoDB set up that acts as both a data buffer for the front end
and a email notification server that alerts a user whenever their meToken is purchased or sold.

##Description

This contract is designed as a base contract for use in building out more complex DAOs.
It is built using two contracts from the Open Zeppelin smart-contract library:
Ownable.sol && IERC20.sol.

######This contract is built with two goals in mind:

1. The DAO should be capable of accepting and distributing both ETH and ERC20 tokens.

2. The DAO will be built to inspire future Non-Token-Based Governance type DAO's

##Time-Frame

8 hours

##Components
Truffle - Provides a framework for developing EVM based Smart-Contracts
Open-Zeppelin's Ownable.sol - Provides simple ownership logic for a smart-contract
Open-Zeppelin's IERC20.sol - provides a smart-contract with a basic interface for interacting with ERC20 type tokens
BaseDAO.sol - A Smart-contract that allows for an organization structure where organization members can vote on who is or isn't a member as well as what to do with the organization's funds

##Closing Notes
This Smart-Contract was developed as part of a dOrg activation challenge and is therefore VERY minimal.
The BaseDao was built to be expanded upon by others who wish to develop their own Non-Token-Based Governance DAOs.

In this spirit I have developed certain functions in such a way that they may be expanded on, primarily the _addMember_ function and the proposal function.
The _addMember_ function can easily be called in other ways by a contract that inherits the BaseDao's functionality while the _createProposal_ and _executeVote_
functions where designed so that any number of other _propCodes_ and _propCode logic_ could be added to the contract itself.

A Tokenomics incentive model was purposefully left out of this DOA to keep it as minimal as possible, though one could easily be added with additional logic.

In future updates to this contract I would like to implement SafeMath into its operations to ensure we do not encounter calculation overflow problems.

**To use BaseDAO.sol in your own project clone this repository and run npm install.**
