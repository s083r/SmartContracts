pragma solidity ^0.4.8;

contract UserStorage {
  // FIELDS

  // the number of owners that must confirm the same operation before it is run.
  uint public required;

  mapping (uint => Member) public members;

  struct Member {
    address memberAddr;
    bytes32 hash1;
    bytes14 hash2;
    bool isCBE;
  }

  mapping(address => uint) userIndex;
  uint public userCount = 1;
  uint public adminCount = 0;

  uint ownersCount = 1;
  mapping (address => uint) public ownersIndex;

  // simple single-sig function modifier.
  modifier onlyOwner {
    if (isOwner(msg.sender))
      _;
  }

  function isOwner(address _addr) constant returns (bool) {
    if(ownersIndex[_addr] != 0x0) {
      return true;
    }
    return false;
  }

  function UserStorage() {
    ownersIndex[msg.sender] = ownersCount;
    ownersCount++;
  }

function setRequired(uint _required) onlyOwner() {
    if(_required > 1 && adminCount >= _required) {
      required = _required; 
    }
  }

  function addOwner(address _owner) onlyOwner() returns(bool) {
    ownersIndex[_owner] = ownersCount;
    ownersCount++;
    return true;
  }

  function getOwner(address _owner) constant returns(bool) {
    if(ownersIndex[_owner] > 0)
      return true;
    return false;
  }
 
  function deleteOwner(address _owner) onlyOwner() returns(bool) {
    delete ownersIndex[_owner];
    return true;
  }

  function getCBEMembers() constant returns (address[] addresses, bytes32[] hashes1, bytes14[] hashes2) {
        addresses = new address[](adminCount);
        hashes1 = new bytes32[](adminCount);
        hashes2 = new bytes14[](adminCount);
        uint j = 0;
        for (uint i = 1; i < userCount; i++) {
            if (members[i].isCBE) {
                addresses[j] = members[i].memberAddr;
                hashes1[j] = members[i].hash1;
                hashes2[j] = members[i].hash2;
                j++;
            }
        }
        return (addresses, hashes1, hashes2);
    }

  function addMember(address _member, bool _isCBE) onlyOwner() returns(bool) {
    if (userIndex[_member] == 0) {
      members[userCount] = Member(_member, 1, 1, _isCBE);
      userIndex[_member] = userCount;
      userCount++;
      isCBE(_isCBE);
      return true;
    }
    return false;
  } 

  function isCBE(bool _isCBE) internal{
    if(_isCBE) {
      adminCount++;
      required++;
    }
    else {
      adminCount--;
      if(adminCount >= 2)
         required--;
    }
  }

  function setCBE(address _member, bool _isCBE) onlyOwner() returns(bool) {
    members[userIndex[_member]].isCBE = _isCBE;
    isCBE(_isCBE);
    return true;
 }

  function setHashes(address _member, bytes32 _hash1, bytes14 _hash2) onlyOwner() returns(bool) {
    members[userIndex[_member]].hash1 = _hash1;
    members[userIndex[_member]].hash2 = _hash2;
    return true;
  }

  function getHash(address _member) constant returns(bytes32,bytes14) {
    return (members[userIndex[_member]].hash1, members[userIndex[_member]].hash2);
  }
 
  function deleteMember(uint _id) onlyOwner() returns(bool) {
    delete members[_id];
    return true;
  }

  function getMember(address _member) constant returns(address) {
    return members[userIndex[_member]].memberAddr; 
  }

 function getMemberAddr(uint _id) constant returns(address) {
    return members[_id].memberAddr;
 }

  function getMemberId(address _member) constant returns(uint) {
    return userIndex[_member];
  }

  function getCBE(address _member) constant returns(bool) {
    return members[userIndex[_member]].isCBE;
  }
  
}
