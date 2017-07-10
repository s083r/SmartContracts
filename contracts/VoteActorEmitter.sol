pragma solidity ^0.4.8;

import "./VoteEmitter.sol";

contract VoteActorEmitter is VoteEmitter {
    function emitError(uint errorCode) {
        Error(_self(), errorCode);
    }

    function emitVoteCreated(uint choice, uint pollId) {
        VoteCreated(choice, pollId);
    }
}
