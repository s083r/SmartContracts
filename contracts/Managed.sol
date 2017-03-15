pragma solidity ^0.4.8;

import "./Shareable.sol";

contract Managed is Shareable {
  
    function createMemberIfNotExist(address key) internal {
        UserManager(userManager).addMember(key,false);
    }

    function setMemberHash(address key, bytes32 _hash1, bytes14 _hash2) onlyAuthorized() returns (bool) {
//        createMemberIfNotExist(key);
        UserManager(userManager).setHashes(key, _hash1, _hash2);
        return true;
    }

    function setOwnHash(bytes32 _hash1, bytes14 _hash2) returns (bool) {
        createMemberIfNotExist(msg.sender);
        UserManager(userManager).setHashes(msg.sender, _hash1, _hash2);
        return true;
    }

    function getMemberHash(address key) constant returns (bytes32, bytes14) {
        return UserManager(userManager).getHash(key);
    }

    function required() constant returns (uint) {
        return UserManager(userManager).required();
    }

    function getTxsType(bytes32 _hash) returns (uint) {
        return uint(txs[_hash].op);
    }

    function getTxsData(bytes32 _hash) constant returns (bytes) {
        return txs[_hash].data;
    }

 //   function setRequired(uint _required) execute(Operations.changeReq) {
 //       if (_required > 1 && _required < adminCount) {
 //           required = _required;
 //       }
 //   }

    modifier onlyAuthorized() {
        if (isAuthorized(msg.sender)) {
            _;
        }
    }

    modifier execute(Operations _type) {
        if (UserManager(userManager).required() > 1) {
            if (this != msg.sender) {
                bytes32 _r = sha3(msg.data, "signature");
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
            if (!txs[_h].to.call(txs[_h].data)) {
                throw;
            }
            delete txs[_h];
            return true;
        }
    }

    function isAuthorized(address key) returns (bool) {
        if (isOwner(key) || this == key) {
            return true;
        }
        return false;
    }

    function addKey(address key) execute(Operations.createLOC) {
      //  if (!UserManager(userManager).getCBE(key)) { // Make sure that the key being submitted isn't already CBE
            UserManager(userManager).addMember(key,true);
            cbeUpdate(key);
       // }
    }

    function revokeKey(address key) execute(Operations.createLOC) {
        // Make sure that the key being revoked is exist and is CBE
        if (UserManager(userManager).getCBE(key)) {
            UserManager(userManager).setCBE(key,false);
            cbeUpdate(key);
        }
    }
}
