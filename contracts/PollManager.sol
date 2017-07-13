pragma solidity ^0.4.11;

import "./Vote.sol";
import "./PollEmitter.sol";
import {TimeHolderInterface as TimeHolder} from "./TimeHolderInterface.sol";

contract PollManager is Vote, PollEmitter {

    uint8 constant DEFAULT_SHARES_PERCENT = 1;
    uint8 constant ACTIVE_POLLS_MAX = 20;
    uint8 constant IPFS_HASH_POLLS_MAX = 5;

    function PollManager(Storage _store, bytes32 _crate) StorageAdapter(_store, _crate) {
        _init();
    }

    function init(address _contractsManager) returns (uint) {
        address contractsManagerAddress = store.get(contractsManager);
        if (contractsManagerAddress != 0x0 && contractsManagerAddress != _contractsManager) {
            return ERROR_VOTE_INVALID_INVOCATION;
        }

        uint e = ContractsManagerInterface(_contractsManager).addContract(this, bytes32("Voting"));
        if (OK != e) {
            return e;
        }

        store.set(contractsManager, _contractsManager);
        store.set(sharesPercent, DEFAULT_SHARES_PERCENT);

        return OK;
    }

    function getVoteLimit() constant returns (uint) {
        address timeHolder = ContractsManagerInterface(store.get(contractsManager)).getContractAddressByType(bytes32("TimeHolder"));
        return TimeHolder(timeHolder).totalSupply() / 10000 * store.get(sharesPercent);
    }

    function NewPoll(bytes32[16] _options, bytes32[4] _ipfsHashes, bytes32 _title, bytes32 _description, uint _votelimit, uint _deadline) returns (uint errorCode) {
        if (_votelimit > getVoteLimit()) {
            return _emitError(ERROR_VOTE_LIMIT_EXCEEDED);
        }

        uint prevId = store.get(pollsIdCounter);
        uint id = prevId + 1;
        store.set(pollsIdCounter, id);
        store.set(owner, id, msg.sender);
        store.set(title, id, _title);
        store.set(description, id, _description);
        store.set(votelimit, id, _votelimit);
        store.set(deadline, id, _deadline);
        store.set(status, id, true);
        store.set(active, id, false);
        uint i;
        for (i = 0; i < _options.length; i++) {
            if (_options[i] != bytes32(0)) {
                store.add(optionsId, bytes32(id), _options[i]);
            }
        }

        for (i = 0; i < _ipfsHashes.length; i++) {
            if (_ipfsHashes[i] != bytes32(0)) {
                store.add(ipfsHashes, bytes32(id), _ipfsHashes[i]);
            }
        }
        store.add(polls, id);
        _emitPollCreated(id);
        errorCode = OK;
    }

    function addIpfsHashToPoll(uint _id, bytes32 _hash) onlyCreator(_id) returns (uint errorCode) {
        if (store.count(ipfsHashes, bytes32(_id)) >= IPFS_HASH_POLLS_MAX) {
            return _emitError(ERROR_VOTE_POLL_LIMIT_REACHED);
        }

        store.add(ipfsHashes, bytes32(_id), _hash);
        _emitIpfsHashToPollAdded(_id, _hash, store.count(ipfsHashes, bytes32(_id)));
        errorCode = OK;
    }

    function setVotesPercent(uint _percent) returns (uint errorCode) {
        uint e = multisig();
        if (OK != e) {
            return _checkAndEmitError(e);
        }

        if (_percent > 0 && _percent < 100) {
            store.set(sharesPercent, _percent);
            _emitSharesPercentUpdated();
            errorCode = OK;
        }
        else {
            errorCode = _emitError(ERROR_VOTE_INVALID_PARAMETER);
        }
    }

    function removePoll(uint _pollId) onlyAuthorized returns (uint errorCode) {
        if (!store.get(active, _pollId) && store.get(status, _pollId) && store.includes(polls, _pollId)) {
            errorCode = deletePoll(_pollId);
        }
        else {
            errorCode = _emitError(ERROR_VOTE_INVALID_PARAMETER);
        }
    }

    function cleanInactivePolls() onlyAuthorized returns (uint errorCode) {
        StorageInterface.Iterator memory iterator = store.listIterator(polls);
        uint pollId;
        while(store.canGetNextWithIterator(polls, iterator)) {
            pollId = store.getNextWithIterator(polls, iterator);
            if (checkPollIsInactive(pollId)) {
                deletePoll(pollId);
            }
        }
        return OK;
    }

    function deletePoll(uint _pollId) internal returns (uint) {
        store.remove(polls, _pollId);
        // TODO: how to deal with hashes
        _emitPollDeleted(_pollId);
        return OK;
    }

    function activatePoll(uint _pollId) returns (uint errorCode) {
        uint e = multisig();
        if (OK != e) {
            return _checkAndEmitError(e);
        }

        uint _activePollsCount = store.get(activePollsCount);
        if (_activePollsCount + 1 > ACTIVE_POLLS_MAX) {
            return _emitError(ERROR_VOTE_ACTIVE_POLL_LIMIT_REACHED);
        }

        if (!store.get(status, _pollId)) {
            return _emitError(ERROR_VOTE_UNABLE_TO_ACTIVATE_POLL);
        }

        store.set(active, _pollId, true);
        store.set(activePollsCount, _activePollsCount + 1);
        _emitPollActivated(_pollId);
        return OK;
    }

    function adminEndPoll(uint _pollId) returns (uint errorCode) {
        uint e = multisig();
        if (OK != e) {
            return _checkAndEmitError(e);
        }

        uint result = endPoll(_pollId);
        errorCode = _checkAndEmitError(result);
    }

    function _emitError(uint error) internal returns (uint) {
        PollManager(getEventsHistory()).emitError(error );
        return error;
    }

    function _checkAndEmitError(uint error) internal returns (uint) {
        if (error != OK && error != MULTISIG_ADDED) {
            return _emitError(error);
        }

        return error;
    }

    function _emitSharesPercentUpdated() internal {
        PollManager(getEventsHistory()).emitSharesPercentUpdated();
    }

    function _emitPollCreated(uint pollId) internal {
        emitPollCreated(pollId);
    }

    function _emitPollDeleted(uint pollId) internal {
        PollManager(getEventsHistory()).emitPollDeleted(pollId);
    }

    function _emitPollEnded(uint pollId) internal {
        PollManager(getEventsHistory()).emitPollEnded(pollId);
    }

    function _emitPollActivated(uint pollId) internal {
        PollManager(getEventsHistory()).emitPollActivated(pollId);
    }

    function _emitIpfsHashToPollAdded(uint id, bytes32 hash, uint count) internal {
        PollManager(getEventsHistory()).emitIpfsHashToPollAdded(id, hash, count);
    }
}
