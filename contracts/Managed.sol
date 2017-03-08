pragma solidity ^0.4.8;

import "./Configurable.sol";
import "./Shareable.sol";

contract Managed is Configurable, Shareable {

  enum Operations {createLOC,editLOC,addLOC,removeLOC,editMint,changeReq}
  mapping (bytes32 => Transaction) public txs;
  uint adminCount;
  event userCreate(address key);
  event userUpdate(address key);

  struct Transaction {
    address to;
    bytes data;
    Operations op;
  }

  function setMemberHash(address key, bytes32 _hash1, bytes14 _hash2) onlyAuthorized() returns(bool) {
     if (userIndex[uint(key)] == uint(0x0)) { // Make sure that the key being submitted isn't already CBE.
      members[userCount] = Member(key,0,0,false);
      userIndex[uint(key)] = userCount;
      userCount++;
     }
     members[userIndex[uint(key)]].hash1 = _hash1;
     members[userIndex[uint(key)]].hash2 = _hash2;
     userUpdate(key);
     return true;
  }

  function setOwnHash(bytes32 _hash1, bytes14 _hash2) returns(bool) {
     if (userIndex[uint(msg.sender)] == uint(0x0)) { // Make sure that the key being submitted isn't already CBE.
      members[userCount] = Member(msg.sender,0,0,false);
      userIndex[uint(msg.sender)] = userCount;
      userCount++;
     }
     members[userIndex[uint(msg.sender)]].hash1 = _hash1;
     members[userIndex[uint(msg.sender)]].hash2 = _hash2;
     userUpdate(msg.sender);
     return true;
  }

  function getMembers() constant returns(address[] result)
  {
    result = new address[](userCount-1);
    for(uint i = 0; i<userCount-1; i++)
    {
      result[i] = address(members[i+1].memberAddr);
    }
    return (result);
  }

  function Managed() {
    members[userCount] = Member(msg.sender,0,0,true);
    userIndex[uint(msg.sender)] = userCount;
    userCount++;
    adminCount++;
    required = 1;
  }

  function getTxsType(bytes32 _hash) returns (uint) {
    return uint(txs[_hash].op);
  }

  function getTxsData(bytes32 _hash) constant returns(bytes) {
    return txs[_hash].data;
  }

  function setRequired(uint _required) execute(Operations.changeReq) {
    if(_required > 1 && _required < adminCount) {
      required = _required; 
    }
  }

  modifier onlyAuthorized() {
      if (isAuthorized(msg.sender)) {
          _;
      }
  }

  modifier execute(Operations _type) {
   if (required > 1) {
   if (this != msg.sender) {
      bytes32 _r = sha3(msg.data,"signature");
      txs[_r].data = msg.data;
      txs[_r].op = _type;
      txs[_r].to = this;
      confirm(_r);
    } 
    else {
     _;
    }
  }
  else {
     _;
  }
 }

  function confirm(bytes32 _h) onlymanyowners(_h) returns (bool) {
     if (txs[_h].to != 0) {
      if(!txs[_h].to.call(txs[_h].data)) {
        throw;
      }
      delete txs[_h];
      return true;
      }
  }
  
  function isAuthorized(address key) returns(bool) {
      if(isOwner(key) || this == key) {
        return true;
      }
      return false;
  } 
 
  function addKey(address key) execute(Operations.createLOC) {
    if (userIndex[uint(key)] == uint(0x0)) { // Make sure that the key being submitted isn't already CBE.
      members[userCount] = Member(key,0,0,true);        
      userIndex[uint(key)] = userCount;
      userUpdate(key);
      userCount++;
      adminCount++;
      if(adminCount > 1)
       {
         required++;
       }
    }
  }

  function revokeKey(address key) execute(Operations.createLOC) {
    if (userIndex[uint(key)] != uint(0x0)) { // Make sure that the key being submitted isn't already CBE.
      remove(userIndex[uint(key)]);
      delete userIndex[uint(key)];
      userUpdate(key);
      userCount--;
      adminCount--;
      if(adminCount >= 1)
       {
         required--;
       }
    }
  }

   function remove(uint index) internal {
        if (index > userCount) return;

        for (uint i = index; i<userCount-1; i++){
            members[i] = members[i+1];
        }
        delete members[userCount-1];
    }


}
