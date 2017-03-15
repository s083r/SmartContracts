pragma solidity ^0.4.8;

import {ERC20Interface as Asset} from "./ERC20Interface.sol";
import "./Managed.sol";

contract Vote is Managed {

  //defines the poll
  struct Poll {
    address owner;
    bytes32 title;
    bytes32 description;
    uint votelimit;
    uint optionsCount;
    uint deadline;
    bool status;
    uint ipfsHashesCount;
    mapping(address => uint) memberOption;
    mapping(uint => bytes32) ipfsHashes;
    mapping(uint => uint) options;
    mapping(uint => bytes32) optionsId;
  }

    // ERC20 token that acts as shares.
    Asset public sharesContract;

   function Vote(Asset _sharesContract) {
     sharesContract = _sharesContract;
   }

// Shares deposited by shareholder.
    mapping(address => uint) public shares;

// Polls ids member took part
    mapping(address => uint[]) memberPolls;

  // event tracking new Polls
    event New_Poll(uint _pollId);

  // event tracking of all votes
  event NewVote(uint _choice);
 
    // Something went wrong.
    event Error(bytes32 message);

    // User deposited into current period.
    event Deposit(address indexed who, uint indexed amount);

    // Shares withdrawn by a shareholder.
    event WithdrawShares(address indexed who, uint amount);
   
  // declare an polls mapping called polls
  mapping(uint => Poll) public polls;
  // Polls counter for mapping 
  uint public pollsCount;

  //initiator function that stores the necessary poll information
  function NewPoll(bytes32[16] _options, bytes32 _title, bytes32 _description, uint _votelimit, uint _count, uint _deadline) returns (uint) {
    polls[pollsCount] = Poll(msg.sender,_title,_description,_votelimit,0,_deadline,true,0);
    for(uint i = 1; i < _count+1; i++) {
      polls[pollsCount].options[i] = 0;
       polls[pollsCount].optionsId[i] = _options[i-1];
       polls[pollsCount].optionsCount++;
    }
    New_Poll(pollsCount);
    return pollsCount++; 
  }

  function getPollTitles() returns (bytes32[] result) {
    result = new bytes32[](pollsCount);
    for(uint i = 0; i<pollsCount; i++)
    {
      result[i] = polls[i].title;
    }
    return (result); 
  }

  function getMemberPolls() returns (uint[]) {  
    return memberPolls[msg.sender];
  }

  function getMemberVotesForPoll(uint _id) returns (uint result) {
    Poll p = polls[_id];
    result = p.memberOption[msg.sender];
    return (result); 
  }

  function getOptionsForPoll(uint _id) returns (bytes32[] result) {
    Poll p = polls[_id];
    result = new bytes32[](p.optionsCount);
    for(uint i = 0; i < p.optionsCount; i++)
    {
      result[i] = p.optionsId[i+1];
    }
    return result;
  }

  function getOptionsVotesForPoll(uint _id) returns (uint[] result) {
    Poll p = polls[_id];
    result = new uint[](p.optionsCount);
    for(uint i = 0; i < p.optionsCount; i++)
    {
      result[i] = p.options[i+1];
    }
    return result;
  }

  /**
     * Deposit shares and prove possession.
     * Amount should be less than or equal to current allowance value.
     *
     * Proof should be repeated for each active period. To prove possesion without
     * depositing more shares, specify 0 amount.
     *
     * @param _amount amount of shares to deposit, or 0 to just prove.
     *
     * @return success.
     */
    function deposit(uint _amount) returns(bool) {
        return depositFor(msg.sender, _amount);
    }

   /**
     * Deposit own shares and prove possession for arbitrary shareholder.
     * Amount should be less than or equal to caller current allowance value.
     *
     * Proof should be repeated for each active period. To prove possesion without
     * depositing more shares, specify 0 amount.
     *
     * This function meant to be used by some backend application to prove shares possesion
     * of arbitrary shareholders.
     *
     * @param _address to deposit and prove for.
     * @param _amount amount of shares to deposit, or 0 to just prove.
     *
     * @return success.
     */
    function depositFor(address _address, uint _amount) returns(bool) {
        if (_amount != 0 && !sharesContract.transferFrom(msg.sender, this, _amount)) {
            Error("Shares transfer failed");
            return false;
        }

        shares[_address] += _amount;

        Deposit(_address, _amount);
        return true;
    }

    /**
     * Returns shares amount deposited by a particular shareholder.
     *
     * @param _address shareholder address.
     *
     * @return shares amount.
     */
    function depositBalance(address _address) constant returns(uint) {
        return shares[_address];
    }

 /**
     * Withdraw shares from the contract, updating the possesion proof in active period.
     *
     * @param _amount amount of shares to withdraw.
     *
     * @return success.
     */
    function withdrawShares(uint _amount) returns(bool) {
        // Provide latest possesion proof.
        deposit(0);
        if (_amount > shares[msg.sender]) {
            Error("Insufficient balance");
            return false;
        }
        for(uint i=0;i<memberPolls[msg.sender].length;i++){
           Poll p = polls[memberPolls[msg.sender][i]];
           if(p.status) {
             uint choice = p.memberOption[msg.sender];
             p.options[choice] -= _amount;
           }
        }
        shares[msg.sender] -= _amount;

        WithdrawShares(msg.sender, _amount);
        return true;
    }

    modifier onlyCreator(uint _id) {
        Poll p = polls[_id];
        if(p.owner == msg.sender || this == msg.sender)
        {
          _;
        }
    }

    function addIpfsHashToPoll(uint _id, bytes32 _hash) onlyCreator(_id) returns(bool) {
        Poll p = polls[_id];
        if(p.ipfsHashesCount < 5) {
          p.ipfsHashes[p.ipfsHashesCount++] = _hash;
          return true;
        }
        return false;
    }

    function getIpfsHashesFromPoll(uint _id) returns (bytes32[] result) {
        Poll p = polls[_id];
        result = new bytes32[](p.ipfsHashesCount);
        for(uint i = 0; i < p.ipfsHashesCount; i++)
        {
           result[i] = p.ipfsHashes[i];
        }
        return result;
    }


  //function for user vote. input is a string choice
  function vote(uint _pollId, uint _choice) returns (bool) {
    Poll p = polls[_pollId]; 
    if (_choice == 0 || p.status != true || shares[msg.sender] == 0 || p.memberOption[msg.sender] != 0) {
      return false;
    }

    p.options[_choice] += shares[msg.sender];
    p.memberOption[msg.sender] = _choice;
    memberPolls[msg.sender].push(_pollId);
    NewVote(_choice);

    // if votelimit reached, end poll
    if (p.votelimit > 0 || p.deadline <= now) {
      if (p.options[_choice] >= p.votelimit) {
        endPoll(_pollId);
      }
    }
    return true;
  }

  //when time or vote limit is reached, set the poll status to false
  function endPoll(uint _pollId) internal returns (bool) {
    Poll p = polls[_pollId];
    p.status = false;
    return true;
  }
}
