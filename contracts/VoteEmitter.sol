pragma solidity ^0.4.8;

import './MultiEventsHistoryAdapter.sol';

contract VoteEmitter is MultiEventsHistoryAdapter {
    // event tracking new Polls
    event PollCreated(uint pollId);
    event PollDeleted(uint pollId);
    event PollEnded(uint pollId);
    event PollActivated(uint pollId);
    // event tracking of all votes
    event VoteCreated(uint choice, uint pollId);
    event SharesPercentUpdated(address indexed self);
    event IpfsHashToPollAdded(uint indexed id, bytes32 hash, uint count);
    event Error(address indexed self, uint indexed errorCode);

    function emitError(uint errorCode) {
        Error(_self(), errorCode);
    }

    function emitSharesPercentUpdated() {
        SharesPercentUpdated(_self());
    }

    function emitPollCreated(uint pollId) {
        PollCreated(pollId);
    }

    function emitPollDeleted(uint pollId) {
        PollDeleted(pollId);
    }

    function emitPollEnded(uint pollId) {
        PollEnded(pollId);
    }

    function emitPollActivated(uint pollId) {
        PollActivated(pollId);
    }

    function emitVoteCreated(uint choice, uint pollId) {
        VoteCreated(choice, pollId);
    }

    function emitIpfsHashToPollAdded(uint id, bytes32 hash, uint count) {
        IpfsHashToPollAdded(id, hash, count);
    }
}
