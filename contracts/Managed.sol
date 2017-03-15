pragma solidity ^0.4.8;

import {PendingManager as Shareable} from "./PendingManager.sol";
import "./UserManager.sol";

contract Managed {
 
    address userManager;
    address shareable;

    event cbeUpdate(address key);
    event exec(bytes32 hash);

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

 //   function setRequired(uint _required) execute(Shareable.Operations.changeReq) {
 //       if (_required > 1 && _required < adminCount) {
 //           required = _required;
 //       }
 //   }

    modifier onlyAuthorized() {
        if (isAuthorized(msg.sender)) {
            _;
        }
    }

    modifier execute(Shareable.Operations _type) {
        if (UserManager(userManager).required() > 1) {
           if(msg.sender != shareable) {
                bytes32 _r = sha3(msg.data, "signature");
                Shareable(shareable).addTx(_r, msg.data,_type,this);
                exec(_r);
           }
           else {
            _;
           }
        }
        else {
            _;
        }
    }

    function isAuthorized(address key) returns (bool) {
        if (isOwner(key) || shareable == key) {
            return true;
        }
        return false;
    }

  function isOwner(address _addr) constant returns (bool) {
    return UserManager(userManager).getCBE(_addr);
  }

    function addKey(address key) execute(Shareable.Operations.createLOC) {
      //  if (!UserManager(userManager).getCBE(key)) { // Make sure that the key being submitted isn't already CBE
            UserManager(userManager).addMember(key,true);
            cbeUpdate(key);
       // }
    }

    function revokeKey(address key) execute(Shareable.Operations.createLOC) {
        // Make sure that the key being revoked is exist and is CBE
        if (UserManager(userManager).getCBE(key)) {
            UserManager(userManager).setCBE(key,false);
            cbeUpdate(key);
        }
    }
}
