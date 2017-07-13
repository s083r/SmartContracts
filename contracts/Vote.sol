pragma solidity ^0.4.8;

import "./Managed.sol";
import "./VoteEmitter.sol";

contract Vote is Managed, VoteEmitter {
  // Vote errors
    uint constant ERROR_VOTE_INVALID_PARAMETER = 8000;
    uint constant ERROR_VOTE_INVALID_INVOCATION = 8001;
    uint constant ERROR_VOTE_ADD_CONTRACT = 8002;
    uint constant ERROR_VOTE_LIMIT_EXCEEDED = 8003;
    uint constant ERROR_VOTE_POLL_LIMIT_REACHED = 8004;
    uint constant ERROR_VOTE_POLL_WRONG_STATUS = 8005;
    uint constant ERROR_VOTE_POLL_INACTIVE = 8006;
    uint constant ERROR_VOTE_POLL_NO_SHARES = 8007;
    uint constant ERROR_VOTE_POLL_ALREADY_VOTED = 8008;
    uint constant ERROR_VOTE_ACTIVE_POLL_LIMIT_REACHED = 8009;
    uint constant ERROR_VOTE_UNABLE_TO_ACTIVATE_POLL = 8010;

    StorageInterface.UInt pollsIdCounter;
    StorageInterface.UInt activePollsCount;

    StorageInterface.OrderedUIntSet polls;

    StorageInterface.UInt sharesPercent;

    StorageInterface.UIntAddressMapping owner;
    StorageInterface.UIntBytes32Mapping title;
    StorageInterface.UIntBytes32Mapping description;
    StorageInterface.UIntUIntMapping votelimit;
    StorageInterface.UIntUIntMapping deadline;
    StorageInterface.UIntBoolMapping status;
    StorageInterface.UIntBoolMapping active;

    StorageInterface.UIntAddressUIntMapping memberOption;
    StorageInterface.UIntAddressUIntMapping memberVotes;
    StorageInterface.UIntUIntUIntMapping options;

    StorageInterface.AddressOrderedSetMapping members;
    StorageInterface.UIntOrderedSetMapping memberPolls;
    StorageInterface.Bytes32OrderedSetMapping ipfsHashes;
    StorageInterface.Bytes32OrderedSetMapping optionsId;

    // function Vote(Storage _store, bytes32 _crate) StorageAdapter(_store, _crate) {

    // }

    function _init() internal {
        pollsIdCounter.init('pollsIdCounter');
        activePollsCount.init('activePollsCount');
        polls.init('polls');
        sharesPercent.init('sharesPercent');
        owner.init('owner');
        title.init('title');
        description.init('description');
        votelimit.init('votelimit');
        deadline.init('deadline');
        status.init('status');
        active.init('active');
        memberOption.init('memberOption');
        memberVotes.init('memberVotes');
        options.init('options');
        members.init('members');
        memberPolls.init('memberPolls');
        ipfsHashes.init('ipfsHashes');
        optionsId.init('optionsId');
    }

    function setupEventsHistory(address _eventsHistory) onlyAuthorized returns (uint) {
        if (getEventsHistory() != 0x0) {
            return ERROR_VOTE_INVALID_INVOCATION;
        }

        _setEventsHistory(_eventsHistory);
        return OK;
    }

    function checkPollIsActive(uint _pollId) constant returns (bool) {
        return store.get(active, _pollId);
    }

    function checkPollIsInactive(uint _pollId) internal constant returns (bool) {
        return !checkPollIsActive(_pollId);
    }

    modifier onlyCreator(uint _id) {
        if (isPollOwner(_id)) {
            _;
        }
    }

    //when time or vote limit is reached, set the poll status to false
    function endPoll(uint _pollId) internal returns (uint) {
        if (!store.get(status, _pollId))  {
            return ERROR_VOTE_INVALID_PARAMETER;
        }

        store.set(status, _pollId, false);
        store.set(active, _pollId, false);
        store.set(activePollsCount, store.get(activePollsCount) - 1);

        _emitPollEnded(_pollId);
        return OK;
    }

    function isPollOwner(uint _id) constant returns (bool) {
        return store.get(owner, _id) == msg.sender;
    }

    function _emitPollEnded(uint pollId) internal {
        address eventsHistory = getEventsHistory();
        if (eventsHistory != 0x0) {
            Vote(eventsHistory).emitPollEnded(pollId);
        }
    }

    function() {
        throw;
    }
}
