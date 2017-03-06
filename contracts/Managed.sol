pragma solidity ^0.4.8;

import "./Configurable.sol";
import "./Shareable.sol";

contract Managed is Configurable, Shareable {

  enum Operations {createLOC,editLOC,addLOC,removeLOC,editMint,changeReq}
  mapping (bytes32 => Transaction) public txs;
  mapping (uint => string) memberHashes;
  uint public numAuthorizedKeys = 1;
  event userUpdate(address key);

  struct Transaction {
    address to;
    bytes data;
    Operations op;
  }

  function setMemberHash(address key, string _hash) onlyAuthorized() returns(bool) {
     memberHashes[ownerIndex[uint(key)]] = _hash;
     return true;
  }

  function setOwnHash(string _hash) returns(bool) {
     memberHashes[ownerIndex[uint(msg.sender)]] = _hash;
     return true;
  }

  function getMemberHash(address key) constant returns(string) {
     return memberHashes[ownerIndex[uint(key)]];
  }

  function getMembers() constant returns(address[] result)
  {
    result = new address[](numAuthorizedKeys-1);
    for(uint i = 0; i<numAuthorizedKeys-1; i++)
    {
      result[i] = address(owners[i+1]);
    }
    return (result);
  }

  function Managed() {
    address owner  = msg.sender;
    owners[numAuthorizedKeys] = uint(owner);
    ownerIndex[uint(owner)] = numAuthorizedKeys;
    numAuthorizedKeys++;
    required = 1;
  }

  function getTxsType(bytes32 _hash) returns (uint) {
    return uint(txs[_hash].op);
  }

  function getTxsData(bytes32 _hash) constant returns(bytes) {
    return txs[_hash].data;
  }

  function setRequired(uint _required) execute(Operations.changeReq) {
    if(_required > 1 && _required < numAuthorizedKeys) {
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
      if(ownerIndex[uint(key)] != uint(0x0) || this == key) {
        return true;
      }
      return false;
  } 
 
  function addKey(address key) execute(Operations.createLOC) {
    if (ownerIndex[uint(key)] == uint(0x0)) { // Make sure that the key being submitted isn't already CBE.
      owners[numAuthorizedKeys] = uint(key);        
      ownerIndex[uint(key)] = numAuthorizedKeys;
      userUpdate(key);
      numAuthorizedKeys++;
      if(numAuthorizedKeys > 2)
       {
         required++;
       }
    }
  }

  function revokeKey(address key) execute(Operations.createLOC) {
    if (ownerIndex[uint(key)] != uint(0x0)) { // Make sure that the key being submitted isn't already CBE.
      remove(ownerIndex[uint(key)]);
      delete ownerIndex[uint(key)];
      userUpdate(key);
      numAuthorizedKeys--;
      if(numAuthorizedKeys >= 2)
       {
         required--;
       }
    }
  }

 function remove(uint index){
        if (index >= owners.length) return;

        for (uint i = index; i<owners.length-1; i++){
            owners[i] = owners[i+1];
            memberHashes[i] = memberHashes[i+1];
        }
        delete owners[owners.length-1];
    }


}
