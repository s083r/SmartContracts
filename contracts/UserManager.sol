pragma solidity ^0.4.8;

import "./Managed.sol";

contract UserManager is Managed {

  function init(address _userStorage, address _shareable) {
    userStorage = _userStorage;
    shareable = _shareable;
    UserStorage(userStorage).addMember(msg.sender,true);
  }

    function addKey(address key) execute(Shareable.Operations.createLOC) {
      //  if (!UserStorage(userStorage).getCBE(key)) { // Make sure that the key being submitted isn't already CBE
            UserStorage(userStorage).addMember(key,true);
            cbeUpdate(key);
       // }
    }

    function revokeKey(address key) execute(Shareable.Operations.createLOC) {
        // Make sure that the key being revoked is exist and is CBE
        if (UserStorage(userStorage).getCBE(key)) {
            UserStorage(userStorage).setCBE(key,false);
            cbeUpdate(key);
        }
    }

    event cbeUpdate(address key);

    function createMemberIfNotExist(address key) internal {
        UserStorage(userStorage).addMember(key,false);
    }

    function setMemberHash(address key, bytes32 _hash1, bytes14 _hash2) onlyAuthorized() returns (bool) {
        createMemberIfNotExist(key);
        UserStorage(userStorage).setHashes(key, _hash1, _hash2);
        return true;
    }

    function setOwnHash(bytes32 _hash1, bytes14 _hash2) returns (bool) {
        createMemberIfNotExist(msg.sender);
        UserStorage(userStorage).setHashes(msg.sender, _hash1, _hash2);
        return true;
    }

    function getMemberHash(address key) constant returns (bytes32, bytes14) {
        return UserStorage(userStorage).getHash(key);
    }

    function required() constant returns (uint) {
        return UserStorage(userStorage).required();
    }

    function setRequired(uint _required) execute(Shareable.Operations.changeReq) {
        return UserStorage(userStorage).setRequired(_required);
    }
}
