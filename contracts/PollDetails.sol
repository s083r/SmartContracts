pragma solidity ^0.4.11;

import "./Vote.sol";

contract PollDetails is Vote {
    function PollDetails(Storage _store, bytes32 _crate) StorageAdapter(_store, _crate) {
        _init();
    }

    function pollsCount() constant returns (uint) {
        return store.count(polls);
    }

    function getActivePolls() constant returns (uint[] result) {
        result = filteredPolls(checkPollIsActive, getActivePollsCount());
    }

    function getActivePollsCount() constant returns (uint result) {
        StorageInterface.Iterator memory iterator = store.listIterator(polls);
        while (store.canGetNextWithIterator(polls, iterator)) {
            if (store.get(active, store.getNextWithIterator(polls, iterator))) {
                ++result;
            }
        }
    }

    function getInactivePollsCount() constant returns (uint result) {
        return store.count(polls) - getActivePollsCount();
    }

    function getInactivePolls() constant returns (uint[] result) {
        result = filteredPolls(checkPollIsInactive, getInactivePollsCount());
    }

    function filteredPolls(function (uint) constant returns (bool) filter, uint count) private returns (uint[] result) {
        StorageInterface.Iterator memory iterator = store.listIterator(polls);
        uint pollId;
        result = new uint[](count);
        for(uint j = 0; store.canGetNextWithIterator(polls, iterator);) {
            pollId = store.getNextWithIterator(polls, iterator);
            if (filter(pollId)) {
                result[j++] = pollId;
            }
        }
    }

    function getPollTitles() constant returns (bytes32[] result) {
        StorageInterface.Iterator memory iterator = store.listIterator(polls);
        result = new bytes32[](iterator.count());
        for (uint i = 0; store.canGetNextWithIterator(polls, iterator); ++i) {
            result[i] = store.get(title, store.getNextWithIterator(polls, iterator));
        }
    }

    function getMemberPolls() constant returns (uint[] result) {
        StorageInterface.Iterator memory memberPollsIterator = store.listIterator(memberPolls, bytes32(msg.sender));
        result = new uint[](memberPollsIterator.count());
        for (uint i = 0; store.canGetNextWithIterator(memberPolls, memberPollsIterator); ++i) {
            result[i] = store.getNextWithIterator(memberPolls, memberPollsIterator);
        }
    }

    function getMemberVotesForPoll(uint _id) constant returns (uint result) {
        result = store.get(memberOption, _id, msg.sender);
    }

    function getOptionsForPoll(uint _id) constant returns (bytes32[] result) {
        StorageInterface.Iterator memory iterator = store.listIterator(optionsId, bytes32(_id));
        result = new bytes32[](iterator.count());
        for (uint i = 0; store.canGetNextWithIterator(optionsId, iterator); ++i) {
            result[i] = store.getNextWithIterator(optionsId, iterator);
        }
    }

    function getOptionsVotesForPoll(uint _id) constant returns (uint[] result) {
        uint _optionsCount = store.count(optionsId, bytes32(_id));
        result = new uint[](_optionsCount);
        for (uint i = 0; i < _optionsCount; i++) {
            result[i] = store.get(options, _id, i + 1);
        }
    }

    function getIpfsHashesFromPoll(uint _id) constant returns (bytes32[] result) {
        StorageInterface.Iterator memory hashesIterator = store.listIterator(ipfsHashes, bytes32(_id));
        result = new bytes32[](hashesIterator.count());
        for (uint i = 0; store.canGetNextWithIterator(ipfsHashes, hashesIterator); ++i) {
            result[i] = store.getNextWithIterator(ipfsHashes, hashesIterator);
        }
    }

    function getPoll(uint _pollId) constant returns (address _owner,
    bytes32 _title,
    bytes32 _description,
    uint _votelimit,
    uint _deadline,
    bool _status,
    bool _active,
    bytes32[] _options,
    bytes32[] _hashes) {
        _owner = store.get(owner, _pollId);
        _title = store.get(title, _pollId);
        _description = store.get(description, _pollId);
        _votelimit = store.get(votelimit, _pollId);
        _deadline = store.get(deadline, _pollId);
        _status = store.get(status, _pollId);
        _active = store.get(active, _pollId);

        StorageInterface.Iterator memory setIterator = store.listIterator(optionsId, bytes32(_pollId));
        _options = new bytes32[](setIterator.count());
        uint i;
        for (i = 0; store.canGetNextWithIterator(optionsId, setIterator); ++i) {
            _options[i] = store.getNextWithIterator(optionsId, setIterator);
        }

        setIterator = store.listIterator(ipfsHashes, bytes32(_pollId));
        _hashes = new bytes32[](setIterator.count());
        for (i = 0; store.canGetNextWithIterator(ipfsHashes, setIterator); ++i) {
            _hashes[i] = store.getNextWithIterator(ipfsHashes, setIterator);
        }
    }
}
