pragma solidity ^0.4.8;

import "./UserManagerInterface.sol";
import "./Managed.sol";
import "./PendingManagerEmitter.sol";
import "./Errors.sol";

contract PendingManager is Managed, PendingManagerEmitter {
    using Errors for Errors.E;

    // TYPES
    StorageInterface.Set txHashes;
    StorageInterface.Bytes32AddressMapping to;
    StorageInterface.Bytes32UIntMapping value;
    StorageInterface.Bytes32UIntMapping yetNeeded;
    StorageInterface.Bytes32UIntMapping ownersDone;
    StorageInterface.Bytes32UIntMapping timestamp;

    mapping (bytes32 => bytes) data;

    function PendingManager(Storage _store, bytes32 _crate) StorageAdapter(_store, _crate) {
        txHashes.init('txHashesh');
        to.init('to');
        value.init('value');
        yetNeeded.init('yetNeeded');
        ownersDone.init('ownersDone');
        timestamp.init('timestamp');
    }

    // METHODS

    function init(address _contractsManager) returns (uint) {
        if (store.get(contractsManager) != 0x0) {
            return Errors.E.PENDING_INVALID_INVOCATION.code();
        }

        Errors.E e = ContractsManagerInterface(_contractsManager).addContract(this, ContractsManagerInterface.ContractType.PendingManager);
        if (Errors.E.OK != e) {
            return e.code();
        }

        store.set(contractsManager, _contractsManager);

        return Errors.E.OK.code();
    }

    function setupEventsHistory(address _eventsHistory) onlyAuthorized returns (uint) {
        if (getEventsHistory() != 0x0) {
            return Errors.E.PENDING_INVALID_INVOCATION.code();
        }

        _setEventsHistory(_eventsHistory);
        return Errors.E.OK.code();
    }

    function pendingsCount() constant returns (uint) {
        return store.count(txHashes);
    }

    function getTxs() constant returns (bytes32[] _hashes, uint[] _yetNeeded, uint[] _ownersDone, uint[] _timestamp) {
        _hashes = new bytes32[](pendingsCount());
        _yetNeeded = new uint[](pendingsCount());
        _ownersDone = new uint[](pendingsCount());
        _timestamp = new uint[](pendingsCount());
        for (uint i = 0; i < pendingsCount(); i++) {
            _hashes[i] = store.get(txHashes, i);
            _yetNeeded[i] = store.get(yetNeeded, _hashes[i]);
            _ownersDone[i] = store.get(ownersDone, _hashes[i]);
            _timestamp[i] = store.get(timestamp, _hashes[i]);
        }
        return (_hashes, _yetNeeded, _ownersDone, _timestamp);
    }

    function getTx(bytes32 _hash) constant returns (bytes _data, uint _yetNeeded, uint _ownersDone, uint _timestamp) {
        return (data[_hash], store.get(yetNeeded, _hash), store.get(ownersDone, _hash), store.get(timestamp, _hash));
    }

    function pendingYetNeeded(bytes32 _hash) constant returns (uint) {
        return store.get(yetNeeded, _hash);
    }

    function getTxData(bytes32 _hash) constant returns (bytes) {
        return data[_hash];
    }

    function getUserManager() constant returns (address) {
        return ContractsManagerInterface(store.get(contractsManager)).getContractAddressByType(ContractsManagerInterface.ContractType.UserManager);
    }

    function addTx(bytes32 _hash, bytes _data, address _to, address _sender) onlyAuthorizedContract(_sender) returns (Errors.E) {
        if (store.includes(txHashes, _hash)) {
            return _emitError(Errors.E.PENDING_DUPLICATE_TX);
        }

        store.add(txHashes, _hash);
        data[_hash] = _data;
        store.set(to, _hash, _to);
        address userManager = getUserManager();
        store.set(yetNeeded, _hash, UserManagerInterface(userManager).required());
        store.set(timestamp, _hash, now);

        Errors.E result = conf(_hash, _sender);
        return _checkAndEmitError(result);
    }

    function confirm(bytes32 _hash) external returns (uint errorCode) {
        Errors.E result = conf(_hash, msg.sender);
        errorCode = _checkAndEmitError(result).code();
    }

    function conf(bytes32 _hash, address _sender) internal returns (Errors.E) {
        Errors.E e = confirmAndCheck(_hash, _sender);
        if (Errors.E.OK != e) {
            return e;
        }

        if (store.get(to, _hash) == 0) {
            return Errors.E.PENDING_NOT_FOUND;
        }

        if (!store.get(to, _hash).call(data[_hash])) {
            return Errors.E.PENDING_CANNOT_CONFIRM;
        }

        deleteTx(_hash);
        return Errors.E.OK;
    }

    // revokes a prior confirmation of the given operation
    function revoke(bytes32 _hash) external onlyAuthorized returns (uint errorCode) {
        address userManager = getUserManager();
        uint ownerIndexBit = 2 ** UserManagerInterface(userManager).getMemberId(msg.sender);
        if (store.get(ownersDone, _hash) & ownerIndexBit <= 0) {
            errorCode = _emitError(Errors.E.PENDING_NOT_FOUND).code();
            return errorCode;
        }

        store.set(yetNeeded, _hash, store.get(yetNeeded, _hash) + 1);
        store.set(ownersDone, _hash, store.get(ownersDone, _hash) - ownerIndexBit);
        _emitRevoke(msg.sender, _hash);
        if (store.get(yetNeeded, _hash) == UserManagerInterface(userManager).required()) {
            deleteTx(_hash);
            _emitCancelled(_hash);
        }

        errorCode = Errors.E.OK.code();
    }

    function hasConfirmed(bytes32 _hash, address _owner) onlyAuthorizedContract(_owner) constant returns (bool) {
        // determine the bit to set for this owner
        address userManager = getUserManager();
        uint ownerIndexBit = 2 ** UserManagerInterface(userManager).getMemberId(_owner);
        return !(store.get(ownersDone, _hash) & ownerIndexBit == 0);
    }


    // INTERNAL METHODS

    function confirmAndCheck(bytes32 _hash, address _sender) internal onlyAuthorizedContract(_sender) returns (Errors.E) {
        // determine the bit to set for this owner
        address userManager = getUserManager();
        uint ownerIndexBit = 2 ** UserManagerInterface(userManager).getMemberId(_sender);
        // make sure we (the message sender) haven't confirmed this operation previously
        if (store.get(ownersDone, _hash) & ownerIndexBit != 0) {
            return Errors.E.PENDING_PREVIOUSLY_CONFIRMED;
        }

        // ok - check if count is enough to go ahead
        if (store.get(yetNeeded, _hash) <= 1) {
            // enough confirmations: reset and run interior
            _emitDone(_hash, data[_hash], now);
            return Errors.E.OK;
        } else {
            // not enough: record that this owner in particular confirmed
            store.set(yetNeeded, _hash, store.get(yetNeeded, _hash) - 1);
            uint _ownersDone = store.get(ownersDone, _hash);
            _ownersDone |= ownerIndexBit;
            store.set(ownersDone, _hash, _ownersDone);
            _emitConfirmation(_sender, _hash);
            return Errors.E.MULTISIG_ADDED;
        }
    }

    function deleteTx(bytes32 _hash) internal {
        uint txId = store.getIndex(txHashes, _hash);
        uint txCount = store.count(txHashes);
        if (txId != txCount - 1) {
            updateTxId(txId, txCount - 1);
        }

        store.remove(txHashes, _hash);
    }

    function updateTxId(uint _oldId, uint _newId) internal {
        store.set(to, store.get(txHashes, _oldId), store.get(to, store.get(txHashes, _newId)));
        store.set(value, store.get(txHashes, _oldId), store.get(value, store.get(txHashes, _newId)));
        store.set(yetNeeded, store.get(txHashes, _oldId), store.get(yetNeeded, store.get(txHashes, _newId)));
        store.set(ownersDone, store.get(txHashes, _oldId), store.get(ownersDone, store.get(txHashes, _newId)));
        store.set(timestamp, store.get(txHashes, _oldId), store.get(timestamp, store.get(txHashes, _newId)));
        data[store.get(txHashes, _oldId)] = data[store.get(txHashes, _newId)];
    }

    function _emitConfirmation(address owner, bytes32 hash) internal {
        PendingManager(getEventsHistory()).emitConfirmation(owner, hash);
    }

    function _emitRevoke(address owner, bytes32 hash) internal {
        PendingManager(getEventsHistory()).emitRevoke(owner, hash);
    }

    function _emitCancelled(bytes32 hash) internal {
        PendingManager(getEventsHistory()).emitCancelled(hash);
    }

    function _emitDone(bytes32 hash, bytes data, uint timestamp) internal {
        PendingManager(getEventsHistory()).emitDone(hash, data, timestamp);
    }

    function _emitError(Errors.E error) internal returns (Errors.E) {
        PendingManager(getEventsHistory()).emitError(error.code());

        return error;
    }

    function _checkAndEmitError(Errors.E error) internal returns (Errors.E)  {
        if (error != Errors.E.OK && error != Errors.E.MULTISIG_ADDED) {
            return _emitError(error);
        }

        return error;
    }

    function()
    {
        throw;
    }
}
