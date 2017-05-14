pragma solidity ^0.4.8;

import "./Managed.sol";

contract UserManager is Managed {
    event CBEUpdate(address key);
    event SetRequired(uint required);

    function init(address _userStorage, address _shareable) returns (bool) {
        if (userStorage != 0x0) {
            return false;
        }
        userStorage = _userStorage;
        shareable = _shareable;
        UserStorage(userStorage).addMember(msg.sender, true);
        return true;
    }

    function addCBE(address _key, bytes32 _hash) multisig {
        if (!UserStorage(userStorage).getCBE(_key)) { // Make sure that the key being submitted isn't already CBE
            if (UserStorage(userStorage).addMember(_key, true) || UserStorage(userStorage).setCBE(_key, true)) {
                setMemberHash(_key, _hash);
                CBEUpdate(_key);
            }
        }
    }

    function revokeCBE(address _key) multisig {
        if (UserStorage(userStorage).getCBE(_key)) { // Make sure that the key being revoked is exist and is CBE
            UserStorage(userStorage).setCBE(_key, false);
            CBEUpdate(_key);
        }
    }

    function createMemberIfNotExist(address key) internal {
        UserStorage(userStorage).addMember(key, false);
    }

    function setMemberHash(address key, bytes32 _hash) onlyAuthorized returns (bool) {
        createMemberIfNotExist(key);
        UserStorage(userStorage).setHashes(key, _hash);
        return true;
    }

    function setOwnHash(bytes32 _hash) returns (bool) {
        createMemberIfNotExist(msg.sender);
        UserStorage(userStorage).setHashes(msg.sender, _hash);
        return true;
    }

    function getMemberHash(address key) constant returns (bytes32) {
        return UserStorage(userStorage).getHash(key);
    }

    function required() constant returns (uint) {
        return UserStorage(userStorage).required();
    }

    function setRequired(uint _required) multisig returns (bool) {
        if (UserStorage(userStorage).setRequired(_required)) {
            SetRequired(_required);
            return true;
        }
        return false;
    }

    function()
    {
        throw;
    }
}
