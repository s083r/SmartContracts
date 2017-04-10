pragma solidity ^0.4.8;

import "./Managed.sol";

contract UserManager is Managed {
    event cbeUpdate(address key);
    event setReq(uint required);

    function init(address _userStorage, address _shareable) returns (bool) {
        if (userStorage != 0x0) {
            return false;
        }
        userStorage = _userStorage;
        shareable = _shareable;
        UserStorage(userStorage).addMember(msg.sender, true);
        return true;
    }

    function addKey(address key) execute(Shareable.Operations.createLOC) {
        if (!UserStorage(userStorage).getCBE(key)) { // Make sure that the key being submitted isn't already CBE
            if (!UserStorage(userStorage).addMember(key, true)) { // member already exist
                if (UserStorage(userStorage).setCBE(key, true)) {
                    cbeUpdate(key);
                }
            } else {
                cbeUpdate(key);
            }
        }
    }

    function revokeKey(address key) execute(Shareable.Operations.createLOC) {
        if (UserStorage(userStorage).getCBE(key)) { // Make sure that the key being revoked is exist and is CBE
            UserStorage(userStorage).setCBE(key, false);
            cbeUpdate(key);
        }
    }

    function createMemberIfNotExist(address key) internal {
        UserStorage(userStorage).addMember(key, false);
    }

    function setMemberHash(address key, bytes32 _hash1) onlyAuthorized() returns (bool) {
        createMemberIfNotExist(key);
        UserStorage(userStorage).setHashes(key, _hash1);
        return true;
    }

    function setOwnHash(bytes32 _hash1) returns (bool) {
        createMemberIfNotExist(msg.sender);
        UserStorage(userStorage).setHashes(msg.sender, _hash1);
        return true;
    }

    function getMemberHash(address key) constant returns (bytes32) {
        return UserStorage(userStorage).getHash(key);
    }

    function required() constant returns (uint) {
        return UserStorage(userStorage).required();
    }

    function setRequired(uint _required) execute(Shareable.Operations.changeReq) returns (bool) {
        setReq(_required);
        return UserStorage(userStorage).setRequired(_required);
    }

    function()
    {
        throw;
    }
}
