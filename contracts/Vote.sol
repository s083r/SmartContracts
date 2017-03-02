pragma solidity ^0.4.8;

import {ERC20Interface as Asset} from "./ERC20Interface.sol";

contract Vote {

  //defines the poll
  struct Poll {
    address owner;
    bytes32 title;
    uint votelimit;
    uint optionsCount;
    uint deadline;
    bool status;
    uint numVotes;
    uint ipfsHashesCount;
    mapping(address => uint) memberOption;
    mapping(uint => string) ipfsHashes;
    mapping(bytes32 => uint) options;
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

  // event tracking of all votes
  event NewVote(uint _choice);
 
    // Something went wrong.
    event Error(bytes32 message);

    // User deposited into current period.
    event Deposit(address indexed who, uint indexed amount);

    // Shares withdrawn by a shareholder.
    event WithdrawShares(address indexed who, uint amount);
   
  // declare an polls array called polls
  mapping(uint => Poll) public polls;
  uint pollsCount;

  //initiator function that stores the necessary poll information
  function NewPoll(bytes32[16] _options, bytes32 _title, uint _votelimit, uint _count, uint _deadline) returns (uint) {
    polls[pollsCount] = Poll(msg.sender,_title,_votelimit,_count,_deadline,true,0,0);
    for(uint i = 0; i < _count-1; i++) {
      polls[pollsCount].options[_options[i]] = 0;
       polls[pollsCount].optionsId[i] = _options[i];
       polls[pollsCount].optionsCount++;
    }
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
           uint choice = p.memberOption[msg.sender];
           p.options[p.optionsId[choice]] -= _amount;
        }
        shares[msg.sender] -= _amount;

        WithdrawShares(msg.sender, _amount);
        return true;
    }


  //function for user vote. input is a string choice
  function vote(uint _pollId, uint _choice) returns (bool) {
    Poll p = polls[_pollId]; 
    if (msg.sender != p.owner || p.status != true) {
      return false;
    }

    p.options[p.optionsId[_choice]] += shares[msg.sender];
    p.memberOption[msg.sender] = _choice;
    memberPolls[msg.sender].push(_pollId);
    NewVote(_choice);

    // if votelimit reached, end poll
    if (p.votelimit > 0) {
      if (p.options[p.optionsId[_choice]] >= p.votelimit) {
        endPoll(_pollId);
      }
    }
    return true;
  }

  //when time or vote limit is reached, set the poll status to false
  function endPoll(uint _pollId) returns (bool) {
    Poll p = polls[_pollId];
    if (msg.sender != p.owner) {
      return false;
    }
    p.status = false;
    return true;
  }
}
