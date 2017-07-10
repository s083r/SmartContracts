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
    event Error(address indexed self, uint errorCode);

    function emitPollEnded(uint pollId) {
        PollEnded(pollId);
    }
}
