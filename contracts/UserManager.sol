pragma solidity ^0.4.8;

import "./Managed.sol";
import "./UserManagerEmitter.sol";
import './Errors.sol';

contract UserManager is Managed, UserManagerEmitter {
    using Errors for Errors.E;

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

    function init(address _contractsManager) returns (uint) {
        if (store.get(contractsManager) != 0x0) {
            return Errors.E.USER_INVALID_STATE.code();
        }

        Errors.E e;

        e = addMember(msg.sender, true);
        if (e != Errors.E.OK) {
            return e.code();
        }

        e = ContractsManagerInterface(_contractsManager).addContract(this, ContractsManagerInterface.ContractType.UserManager);
        if (e != Errors.E.OK) {
            return e.code();
        }

        store.set(contractsManager, _contractsManager);
        return e.code();
    }

    function setupEventsHistory(address _eventsHistory) onlyAuthorized returns (uint) {
        if (getEventsHistory() != 0x0) {
            return Errors.E.USER_INVALID_STATE.code();
        }

        _setEventsHistory(_eventsHistory);
        return Errors.E.OK.code();
    }

    function addCBE(address _key, bytes32 _hash) returns (uint) {
        Errors.E e = multisig();
        if (Errors.E.OK != e) {
            return _emitError(e).code();
        }

        if (getCBE(_key)) {
            return _emitError(Errors.E.USER_ALREADY_CBE).code();
        }

        e = addMember(_key, true);
        if (e != Errors.E.OK) {
            return _emitError(e).code();
        }

        e = setMemberHashInt(_key, _hash);
        if (e != Errors.E.OK) {
            return _emitError(e).code();
        }

        _emitCBEUpdate(_key);
        return e.code();
    }

    function revokeCBE(address _key) returns (uint) {
        Errors.E e = multisig();
        if (Errors.E.OK != e) {
            return _emitError(e).code();
        }

        if (!getCBE(_key)) {
            return _emitError(Errors.E.USER_NOT_CBE).code();
        }

        e = setCBE(_key, false);
        if (e != Errors.E.OK) {
            return _emitError(e).code();
        }

        _emitCBEUpdate(_key);
        return e.code();
    }

    function setMemberHash(address key, bytes32 _hash) onlyAuthorized returns (uint) {
        createMemberIfNotExist(key);
        Errors.E e = setMemberHashInt(key, _hash);
        return e.code();
    }

    function setOwnHash(bytes32 _hash) returns (uint) {
        Errors.E e = setMemberHashInt(msg.sender, _hash);
        return e.code();
    }

    function setRequired(uint _required) returns (uint) {
        Errors.E e = multisig();
        if (Errors.E.OK != e) {
            return _emitError(e).code();
        }

        if (!(_required <= store.count(admins))) {
            return _emitError(Errors.E.USER_INVALID_REQURED).code();
        }

        store.set(req, _required);
        _emitSetRequired(_required);

        return Errors.E.OK.code();
    }

    function createMemberIfNotExist(address key) internal returns (Errors.E e) {
        return addMember(key, false);
    }

    function addMember(address key, bool isCBE) internal returns (Errors.E e) {
        store.add(members, key);
        return setCBE(key, isCBE);
    }

    function setMemberHashInt(address key, bytes32 _hash) internal returns (Errors.E e) {
        bytes32 oldHash = getMemberHash(key);
        if (_hash == oldHash) {
            return _emitError(Errors.E.USER_SAME_HASH);
        }

        e = setHashes(key, _hash);
        if (e != Errors.E.OK) {
            return _emitError(e);
        }

        _emitHashUpdate(key, oldHash, _hash);
    }

    function setCBE(address key, bool isCBE) internal returns (Errors.E e) {
        if (isCBE) {
            store.add(admins, key);
        } else {
            store.remove(admins, key);
            if (store.get(req) > store.count(admins)) {
                store.set(req, store.get(req) - 1);
            }
        }
        return Errors.E.OK;
    }

    function setHashes(address key, bytes32 _hash) internal returns (Errors.E e) {
        store.set(hashes, key, _hash);
        return Errors.E.OK;
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

    function _emitSetRequired(uint required) internal {
        UserManager(getEventsHistory()).emitSetRequired(required);
    }

    function _emitHashUpdate(address key, bytes32 oldHash, bytes32 newHash) internal {
        UserManager(getEventsHistory()).emitHashUpdate(key, oldHash, newHash);
    }

    function _emitError(Errors.E e) internal returns (Errors.E) {
        UserManager(getEventsHistory()).emitError(e);
        return e;
    }

    function() {
        throw;
    }
}
