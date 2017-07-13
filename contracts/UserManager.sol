pragma solidity ^0.4.8;

import "./Managed.sol";
import "./UserManagerEmitter.sol";

contract UserManager is Managed, UserManagerEmitter {

    uint constant OK = 1;
    uint constant ERROR_USER_NOT_FOUND = 2000;
    uint constant ERROR_USER_INVALID_PARAMETER = 2001;
    uint constant ERROR_USER_ALREADY_CBE = 2002;
    uint constant ERROR_USER_NOT_CBE = 2003;
    uint constant ERROR_USER_SAME_HASH = 2004;
    uint constant ERROR_USER_INVALID_REQURED = 2005;
    uint constant ERROR_USER_INVALID_STATE = 2006;

    StorageInterface.UInt req;
    StorageInterface.AddressesSet members;
    StorageInterface.AddressesSet admins;
    StorageInterface.AddressBytes32Mapping hashes;

    function UserManager(Storage _store, bytes32 _crate) StorageAdapter(_store, _crate) {
        req.init('req');
        admins.init('admins');
        members.init('members');
        hashes.init('hashes');
    }

    function init(address _contractsManager) returns (uint errorCode) {
        if (store.get(contractsManager) != 0x0) {
            return ERROR_USER_INVALID_STATE;
        }

        errorCode = addMember(msg.sender, true);
        if (OK != errorCode) {
            return errorCode;
        }

        errorCode = ContractsManagerInterface(_contractsManager).addContract(this, bytes32("UserManager"));
        if (OK != errorCode) {
            return errorCode;
        }

        store.set(contractsManager, _contractsManager);
        return OK;
    }

    function setupEventsHistory(address _eventsHistory) onlyAuthorized returns (uint) {
        if (getEventsHistory() != 0x0) {
            return ERROR_USER_INVALID_STATE;
        }

        _setEventsHistory(_eventsHistory);
        return OK;
    }

    function addCBE(address _key, bytes32 _hash) returns (uint errorCode) {
        errorCode = multisig();
        if (OK != errorCode) {
            return _handleResult(errorCode);
        }

        if (getCBE(_key)) {
            return _emitError(ERROR_USER_ALREADY_CBE);
        }

        errorCode = addMember(_key, true);
        if (OK != errorCode) {
            return _emitError(errorCode);
        }

        errorCode = setMemberHashInt(_key, _hash);
        if (OK != errorCode) {
            return _emitError(errorCode);
        }

        _emitCBEUpdate(_key);
        return OK;
    }

    function revokeCBE(address _key) returns (uint errorCode) {
        errorCode = multisig();
        if (OK != errorCode) {
            return _handleResult(errorCode);
        }

        if (!getCBE(_key)) {
            return _emitError(ERROR_USER_NOT_CBE);
        }

        errorCode = setCBE(_key, false);
        if (OK != errorCode) {
            return _emitError(errorCode);
        }

        _emitCBEUpdate(_key);
        return OK;
    }

    function setMemberHash(address key, bytes32 _hash) onlyAuthorized returns (uint errorCode) {
        createMemberIfNotExist(key);
        errorCode = setMemberHashInt(key, _hash);
        return _handleResult(errorCode);
    }

    function setOwnHash(bytes32 _hash) returns (uint errorCode) {
        errorCode = setMemberHashInt(msg.sender, _hash);
        return _handleResult(errorCode);
    }

    function setRequired(uint _required) returns (uint errorCode) {
        errorCode= multisig();
        if (OK != errorCode) {
            return _handleResult(errorCode);
        }

        if (!(_required <= store.count(admins))) {
            return _emitError(ERROR_USER_INVALID_REQURED);
        }

        store.set(req, _required);
        _emitSetRequired(_required);

        return OK;
    }

    function createMemberIfNotExist(address key) internal returns (uint) {
        return addMember(key, false);
    }

    function addMember(address key, bool isCBE) internal returns (uint) {
        if (getMemberId(key) == 0x0) {
            store.add(members, key);
            _emitNewUserRegistered(key);
        }

        return setCBE(key, isCBE);
    }

    function setMemberHashInt(address key, bytes32 _hash) internal returns (uint errorCode) {
        bytes32 oldHash = getMemberHash(key);
        if (_hash == oldHash) {
            return ERROR_USER_SAME_HASH;
        }

        errorCode = setHashes(key, _hash);
        if (OK != errorCode) {
            return errorCode;
        }

        _emitHashUpdate(key, oldHash, _hash);
        return OK;
    }

    function setCBE(address key, bool isCBE) internal returns (uint) {
        if (isCBE) {
            store.add(admins, key);
        } else {
            store.remove(admins, key);
            if (store.get(req) > store.count(admins)) {
                store.set(req, store.get(req) - 1);
            }
        }
        return OK;
    }

    function setHashes(address key, bytes32 _hash) internal returns (uint) {
        store.set(hashes, key, _hash);
        return OK;
    }

    function getMemberHash(address key) constant returns (bytes32) {
        return store.get(hashes, key);
    }

    function getCBE(address key) constant returns (bool) {
        return store.includes(admins, key);
    }

    function getMemberId(address sender) constant returns (uint) {
        return store.getIndex(members, sender);
    }

    function required() constant returns (uint) {
        return store.get(req);
    }

    function adminCount() constant returns (uint) {
        return store.count(admins);
    }

    function userCount() constant returns (uint) {
        return store.count(members);
    }

    function getCBEMembers() constant returns (address[] _addresses, bytes32[] _hashes) {
        _hashes = new bytes32[](adminCount());
        for (uint i = 0; i < adminCount(); i++) {
            _hashes[i] = store.get(hashes, store.get(admins, i));
        }
        return (store.get(admins), _hashes);
    }

    function _emitCBEUpdate(address key) internal {
        UserManager(getEventsHistory()).emitCBEUpdate(key);
    }

    function _emitNewUserRegistered(address key) internal {
        if (getEventsHistory() == 0x0) {
            return;
        }
        UserManager(getEventsHistory()).emitNewUserRegistered(key);
    }

    function _emitSetRequired(uint required) internal {
        UserManager(getEventsHistory()).emitSetRequired(required);
    }

    function _emitHashUpdate(address key, bytes32 oldHash, bytes32 newHash) internal {
        UserManager(getEventsHistory()).emitHashUpdate(key, oldHash, newHash);
    }

    function _emitError(uint error) internal returns (uint) {
        UserManager(getEventsHistory()).emitError(error);
        return error;
    }

    function _handleResult(uint error) internal returns (uint) {
        if (error != OK && error != MULTISIG_ADDED) {
            return _emitError(error);
        }
        return error;
    }

    function() {
        throw;
    }
}
