pragma solidity ^0.4.8;

import "./Managed.sol";
import "./UserManagerEmitter.sol";

contract UserManager is Managed, UserManagerEmitter {
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

    function init(address _contractsManager) returns (bool) {
        addMember(msg.sender, true);
        if(store.get(contractsManager) != 0x0)
        return false;
        if(!ContractsManagerInterface(_contractsManager).addContract(this,ContractsManagerInterface.ContractType.UserManager))
        return false;
        store.set(contractsManager,_contractsManager);
        return true;
    }

    function setupEventsHistory(address _eventsHistory) onlyAuthorized returns(bool) {
        if (getEventsHistory() != 0x0) {
            return false;
        }
        _setEventsHistory(_eventsHistory);
        return true;
    }

    function addCBE(address _key, bytes32 _hash) multisig returns(bool) {
        if (!getCBE(_key)) { // Make sure that the key being submitted isn't already CBE
            if (addMember(_key, true)) {
                setMemberHashInt(_key, _hash);
                _emitCBEUpdate(_key);
                return true;
            }
        } else {
            _emitError("This address is already CBE");
            return false;
        }
    }

    function revokeCBE(address _key) multisig {
        if (getCBE(_key)) { // Make sure that the key being revoked is exist and is CBE
            setCBE(_key, false);
            _emitCBEUpdate(_key);
        }
        else {
            _emitError("This address in not CBE");
        }
    }

    function createMemberIfNotExist(address key) internal returns (bool) {
        return addMember(key, false);
    }

    function setMemberHash(address key, bytes32 _hash) onlyAuthorized returns (bool) {
        createMemberIfNotExist(key);
        return setMemberHashInt(key, _hash);
    }

    function setMemberHashInt(address key, bytes32 _hash) internal returns (bool) {
        bytes32 oldHash = getMemberHash(key);
        if(!(_hash == oldHash)) {
            _emitHashUpdate(key,oldHash, _hash);
            setHashes(key, _hash);
            return true;
        }
        _emitError("Same hash set");
        return false;
    }

    function setOwnHash(bytes32 _hash) returns (bool) {
        return setMemberHashInt(msg.sender, _hash);
    }

    function setRequired(uint _required) multisig returns (bool) {
            if(!(_required <= store.count(admins))) {
                _emitError("Required to high");
                return false;
            }
            store.set(req,_required);
            _emitSetRequired(_required);
            return true;
    }

    function addMember(address key, bool isCBE) internal returns(bool){
        store.add(members,key);
        setCBE(key,isCBE);
        return true;
    }

    function setCBE(address key, bool isCBE) internal returns(bool) {
        if(isCBE) {
            store.add(admins,key);
        }
        else {
            store.remove(admins,key);
            if(store.get(req) > store.count(admins))
                store.set(req,store.get(req)-1);
        }
        return true;
    }

    function setHashes(address key, bytes32 hash) internal {
        store.set(hashes,key,hash);
    }

    function getMemberHash(address key) constant returns (bytes32) {
        return store.get(hashes,key);
    }

    function getCBE(address key) constant returns (bool) {
        return store.includes(admins,key);
    }

    function getMemberId(address sender) constant returns (uint) {
        return store.getIndex(members,sender);
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
            _hashes[i] = store.get(hashes,store.get(admins,i));
        }
        return (store.get(admins), _hashes);
    }

    function _emitCBEUpdate(address key) {
        UserManager(getEventsHistory()).emitCBEUpdate(key);
    }
    function _emitSetRequired(uint required) {
        UserManager(getEventsHistory()).emitSetRequired(required);
    }
    function _emitHashUpdate(address key,bytes32 oldHash, bytes32 newHash) {
        UserManager(getEventsHistory()).emitHashUpdate(key,oldHash,newHash);
    }
    function _emitError(bytes32 _error) {
        UserManager(getEventsHistory()).emitError(_error);
    }

    function()
    {
        throw;
    }
}
