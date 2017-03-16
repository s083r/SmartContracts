pragma solidity ^0.4.8;

import {PendingManager as Shareable} from "./PendingManager.sol";
import "./UserStorage.sol";

contract Managed {
 
    address userStorage;
    address shareable;

    event exec(bytes32 hash);

    modifier onlyAuthorized() {
        if (isAuthorized(msg.sender)) {
            _;
        }
    }

    modifier execute(Shareable.Operations _type) {
        if (UserStorage(userStorage).required() > 1) {
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
    return UserStorage(userStorage).getCBE(_addr);
  }

}
