pragma solidity ^0.6.0;
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
/**
@title BaseDao
@author Christopher Dixon
This contract is designed as a base contract for use in building out more complex DAOs.
It is built using two contracts from the Open Zeppelin smart-contract library:
  Ownable.sol && IERC20.sol.

This contract is built with two goals in mind:

1. The DAO should be capable of accepting and distributing both ETH and ERC20 tokens.

2. The DAO will be built to inspire future Non-Token-Based Governance type DAO's

@dev  All function calls are currently implement without side effects
**/
contract BaseDAO is Ownable {

    uint256 public memberCount; //a count of all members
    uint256 public tokenID; //a count of all whitelisted tokens used to assign a token contracts ID
    uint256 public threshold; //a number reperesenting the percentage threshold for how many members need to vote to trigger executeVote


    Proposal[] public proposals; //an array of Proposal structs that stores proposal information

  mapping(address => bool) public members; //a mapping that tracks if an address is a member
  mapping(uint256 => address) public TokenWhitelist; //a mapping used to track the addresses of whitelisted tokens
  mapping(string => uint256) public getHash;
/**
CONTRACT EVENTS
**/
  event NewProposal(uint256 propCode, string voteHash);
  event NewMember(address newMember);
  event MembershipRevoked(address revokedMember);
  event TokenWhitelisted(address newWhitelist);
  event Voted(address voter, bool);

/**
A struct for storing an individual proposals parameters
**/
  struct  Proposal {
         address payable Address;
         uint PropCode;
         uint Amount;
         uint TokenNumber;
         string voteHash;
         bool executed;
         bool proposalPassed;
         Vote[] votes;
         mapping (address => bool) voted;
     }

/**
A struct for a specific users vote information
**/
     struct Vote {
             bool inSupport;
             address voter;
     }

/**
@notice the modifier onlyMember requires that the function caller must be a member of the DAO to all a function
**/
     modifier onlyMember() {
       require(members[msg.sender], "You are not a member of this DAO");
       _;
     }

/**
@notice The constructor function is triggered when a smart-contract is deployed.
        The constructor function can ONLY be called once.
@param _threshold is a number 1-100 used to signify what percentage of the DAO's members need to vote before the executeVote function is fired
@dev the constructor function automatically adds the contracts deployer as a DAO member
**/
     constructor (uint256 _threshold) public {
       addMember(msg.sender);
       threshold = _threshold;
     }


/**
@notice _checkIfMember allows a front end interface to check if a user is a member so it can render the front end UI accordingly
@param _member is the address in question
**/
     function _checkIfMember(address _member) public view returns(bool) {
        return members[_member];
      }

/**
@notice addMember is an onlyOwner function that allows the owner of this contract to add a new member to the DAO
@param _newMem is the address of the new member
@dev this function is designed so that the person deploying a contract can add members immediately after deployment before ownership of the DAO is transfered to the DAO itself.
@dev the DAO MUST be set as the owner for a membership vote to work
**/
     function addMember(address _newMem) public onlyOwner {
       memberCount++;
       members[_newMem] = true;
       emit NewMember(_newMem);
     }

/**
@notice addNewToken is an onlyOwner function that allows for a new ERC20 token contract to be added to the whitelist of token contracts that a DAO can interact with
@param _contract is the address of the ERC20 contract being added to the whitelist of useable tokens
@dev this function is designed so that the person deploying a contract can add token contracts immediately after deployment before ownership of the DAO is transfered to the DAO itself.
@dev the DAO MUST be set as the owner for a "Add Token" vote to work
**/
      function addNewToken(address _contract) public onlyOwner {
          tokenID++;
          TokenWhitelist[tokenID] = _contract;
          emit TokenWhitelisted(_contract);
      }


/**
@notice percent is an internal function used to calculate the ratio between a given numerator && denominator
@param _numerator is the numerator of the equation
@param _denominator is the denominator of the equation
@param _precision is a precision point to ensure that decimals dont trail outside what the EVM can handle
**/
       function _percent(uint _numerator, uint _denominator, uint _precision) internal pure returns(uint quotient) {
           // caution, check safe-to-multiply here
              uint numerator  = _numerator * 10 ** (_precision+1);
           // with rounding of last digit
              uint _quotient =  ((numerator / _denominator) + 5) / 10;
                return ( _quotient);
        }


/**
@notice _checkThreshold is an internal function used by a vote counts to see if enough of the community has voted
@param _numOfvotes is the total number of votes a proposal has received
@param _numOfmem is the total number of members in the DAO
@notice this function returns a bool
            -true if the threshold is met
            -false if the threshold is not met
**/
        function _checkThreshold(uint _numOfvotes, uint _numOfmem) internal view returns(bool) {
              uint percOfMemVoted = _percent(_numOfvotes, _numOfmem, 2 );
                 if(percOfMemVoted >= threshold) {
                    return true;
                } else {
                    return false;
              }
          }


/**
**@notice Proposal Codes are used to fire specific code. each number represents a different action
**This list can be expanded as needed to facilitate other vote types
*** the following are is a list of prop codes and their actions
** 1. Funding Proposal: this allows the DAO to transfer ETH or ERC20 tokens in accordance with a vote
** 2. Add Member: This allows the community to vote on whether or not a new address becomes a member
** 3. Remove Member: This allows the community to vote on whether or not to revoke an addresses membership
** 4. Add Token: This allows the community to vote on whether or not a new token address should be whitelisted for use

@param _address is the address of either a funding recipient, a proposed new member/a member to be removed, or the address of a token to be whitelisted
@param _propCode is the number used to determine which type of action is being voted on(see prop codes above)
@param _amount this is the number amount for a funding proposal
              -If this is a membership or whiteist proposal set to zero
@param _tokenNumber is used to tell the execute vote function which type of funds to distribute
              -ETH is type zero while ERC20s are numbered in accordance with order added
              -set to zero if this is a membership or token whitelist vote
@param _voteHash is an associated IPFS hash where additional information on a vote can be stored and retrieved by a dApp
*/
      function createProposal(
          address payable _address,
          uint _propCode,
          uint _amount,
          uint _tokenNumber,
          string memory _voteHash
        )
        public
        {
           uint ProposalID = proposals.length;
           ProposalID++;
           Proposal storage p = proposals[ProposalID];
           p.Address = _address;
           p.PropCode = _propCode;
           p.TokenNumber = _tokenNumber;
           p.voteHash = _voteHash;
           getHash[_voteHash] = ProposalID;
           p.Amount = _amount;
           p.executed = false;
           p.proposalPassed = false;
           emit NewProposal(_propCode, _voteHash);
         }

/**
@notice the vote function allows a DAO member to vote on proposals made to the DAO
@param _ProposalID is the number ID associated with the particular proposal the user wishes to vote on
@param  supportsProposal is a bool value(true or false) representing whether or not a member supports a proposal
                -true if they do support the proposal
                -false if they do not support the proposal
@dev this function will trigger the _checkThreshold function which determines if enough members have voted to
          fire the executeVote function.
**/
      function vote(
          uint _ProposalID,
          bool supportsProposal
      )
          public
          onlyMember
      {
          Proposal storage p = proposals[_ProposalID];
          require(p.voted[msg.sender] != true);
          uint voteID = p.votes.length;
          voteID++;
          p.votes[voteID] = Vote({inSupport: supportsProposal, voter: msg.sender});
          p.voted[msg.sender] = true;
          emit Voted(msg.sender, supportsProposal);
          bool met = false;
           //checks if enough members have voted
           met = _checkThreshold(voteID, memberCount);
           //if the threshold is met, count the votes
          if(met) {
            executeVote(_ProposalID);
          }
       }

/**
@notice the executeVote function is an internal function triggered when enough DAO members have voted on a
        proposal(set by the threshold parameter). The executeVote function tallies the number of yea and nay votes
        and then compares them. If yea votes outweigh nay votes than the function uses the PropCode to fufill the proposal
**/
      function executeVote(uint _ProposalID) internal {
              Proposal storage p = proposals[_ProposalID];
                   // sets p equal to the specific proposalNumber
              require(!p.executed, "This proposal has already been executed");
              uint yea = 0;
              uint nay = 0;


              //this for loop cycles through each members vote and adds its value to the yea or nay tally
          for (uint i = 0; i <  p.votes.length; ++i) {
              Vote storage v = p.votes[i];
              if (v.inSupport) {
                yea++;
                   } else {
                 nay++;
                   }
               }
                  //check if the yea votes outway the nay votes
                   if (yea > nay ) {
                       // Proposal passed; execute the transaction
                     if(p.PropCode == 1) { //this is a funding proposal
                       if(p.TokenNumber == 0) { //proposal is for ETH
                         require(address(this).balance >= p.Amount, "The DAO doesnt have enough ETH");
                         p.Address.transfer(p.Amount);//transfers the appropriate amount of ETH
                       } else { //proposal is for a ERC20 token
                          address tokenAdd = TokenWhitelist[p.TokenNumber];
                          IERC20 token = IERC20(tokenAdd); //sets the contract as a usable IERC20 token object
                          require(token.balanceOf(address(this)) >= p.Amount, "The DAO doesnt have enough of this token");
                          token.transfer(p.Address, p.Amount); //transfers the amount of appropriate amount of the selected ERC20 token
                       }
                     }
                     if(p.PropCode == 2) { //proposal to add a new member
                       addMember(p.Address);
                     }
                     if(p.PropCode == 3) { //proposal to revoke a membership
                        members[p.Address] = false;
                        memberCount--;
                        emit MembershipRevoked(p.Address);
                     }
                     if(p.PropCode == 4) { //proposal to whitelist new ERC20 token type
                       addNewToken(p.Address);
                     }
                     /**
                     Additional proposal code logic could be added here to give the DAO more functionality
                     **/

                     ///mark the proposal as executed and passed
                     p.executed = true;
                     p.proposalPassed = true;

                 } else {
                       // mark the proposal as executed and failed
                    p.executed = true;
                    p.proposalPassed = false;
                 }

            }


}
