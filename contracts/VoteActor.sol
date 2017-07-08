pragma solidity ^0.4.11;

import "./Vote.sol";
import "./VoteActorEmitter.sol";
import "./Errors.sol";
import {TimeHolderInterface as TimeHolder} from "./TimeHolderInterface.sol";
import "./ListenerInterface.sol";

contract VoteActor is Vote, VoteActorEmitter, ListenerInterface {
    using Errors for Errors.E;

    function VoteActor(Storage _store, bytes32 _crate) StorageAdapter(_store, _crate) {
        _init();
    }

    function init(address _contractsManager) returns (uint) {
        address contractsManagerAddress = store.get(contractsManager);
        if (contractsManagerAddress != 0x0 && contractsManagerAddress != _contractsManager) {
            return Errors.E.VOTE_INVALID_INVOCATION.code();
        }

        Errors.E e = ContractsManagerInterface(_contractsManager).addContract(this, ContractsManagerInterface.ContractType.VotingActor);
        if (Errors.E.OK != e) {
            return e.code();
        }

        store.set(contractsManager, _contractsManager);

        return Errors.E.OK.code();
    }

    //function for user vote. input is a string choice
    function vote(uint _pollId, uint _choice) returns (uint errorCode) {
        if (!store.get(status, _pollId)) {
            return _emitError(Errors.E.VOTE_POLL_WRONG_STATUS).code();
        }

        if (!store.get(active, _pollId)) {
            return _emitError(Errors.E.VOTE_POLL_INACTIVE).code();
        }

        address timeHolder = ContractsManagerInterface(store.get(contractsManager)).getContractAddressByType(ContractsManagerInterface.ContractType.TimeHolder);
        if (TimeHolder(timeHolder).shares(msg.sender) == 0) {
            return _emitError(Errors.E.VOTE_POLL_NO_SHARES).code();
        }

        if (store.get(memberOption, _pollId, msg.sender) != 0) {
            return _emitError(Errors.E.VOTE_POLL_ALREADY_VOTED).code();
        }

        uint optionsValue = store.get(options, _pollId, _choice) + TimeHolder(timeHolder).shares(msg.sender);
        store.set(options, _pollId, _choice, optionsValue);
        store.set(memberVotes, _pollId, msg.sender, TimeHolder(timeHolder).shares(msg.sender));
        store.add(members, bytes32(_pollId), msg.sender);
        store.set(memberOption, _pollId, msg.sender, _choice);
        store.add(memberPolls, bytes32(msg.sender), _pollId);
        _emitVoteCreated(_choice, _pollId);
        // if votelimit reached, end poll
        uint voteLimitNumber = store.get(votelimit, _pollId);
        if (optionsValue >= voteLimitNumber && (voteLimitNumber > 0 || store.get(deadline, _pollId) <= now)) {
            endPoll(_pollId);
        }
        return Errors.E.OK.code();
    }

    //TimeHolder interface implementation
    modifier onlyTimeHolder() {
        address timeHolder = ContractsManagerInterface(store.get(contractsManager)).getContractAddressByType(ContractsManagerInterface.ContractType.TimeHolder);
        if (msg.sender == timeHolder) {
            _;
        }
    }

    function deposit(address _address, uint _amount, uint _total) onlyTimeHolder returns (uint) {
        StorageInterface.Iterator memory memberPollsIterator = store.listIterator(memberPolls, bytes32(_address));
        while (store.canGetNextWithIterator(memberPolls, memberPollsIterator)) {
            uint pollId = store.getNextWithIterator(memberPolls, memberPollsIterator);
            if (store.get(status, pollId) && store.get(active, pollId)) {
                uint choice = store.get(memberOption, pollId, _address);
                uint value = store.get(options, pollId, choice);
                value = value + _amount;
                store.set(memberVotes, pollId, _address, _total);
                store.set(options, pollId, choice, value);
            }
            uint voteLimitNumber = store.get(votelimit, pollId);
            if (value >= voteLimitNumber && (voteLimitNumber > 0 || store.get(deadline, pollId) <= now)) {
                endPoll(pollId);
            }
        }
        return Errors.E.OK.code();
    }

    function withdrawn(address _address, uint _amount, uint _total) onlyTimeHolder returns (uint) {
        StorageInterface.Iterator memory memberPollsIterator = store.listIterator(memberPolls, bytes32(_address));
        while (store.canGetNextWithIterator(memberPolls, memberPollsIterator)) {
            uint pollId = uint(store.getNextWithIterator(memberPolls, memberPollsIterator));

            if (store.get(status, pollId) && store.get(active, pollId)) {
                uint choice = store.get(memberOption, pollId, _address);
                uint value = store.get(options, pollId, choice);
                value = value - _amount;
                store.set(memberVotes, pollId, _address, _total);
                store.set(options, pollId, choice, value);
                if (_total == 0) {
                    removeMember(pollId, _address);
                }
            }
        }
        return Errors.E.OK.code();
    }

    function removeMember(uint _pollId, address _address) {
        store.set(memberOption, _pollId, _address, 0);
        store.set(memberVotes, _pollId, _address, 0);
        store.remove(memberPolls, bytes32(_address), _pollId);
        store.remove(members, bytes32(_pollId), _address);
    }

    function _emitError(Errors.E error) internal returns (Errors.E) {
        VoteActor(getEventsHistory()).emitError(error.code());
        return error;
    }

    function _emitVoteCreated(uint choice, uint pollId) internal {
        VoteActor(getEventsHistory()).emitVoteCreated(choice, pollId);
    }
}
