pragma solidity ^0.4.8;

import "./MultiEventsHistoryAdapter.sol";

contract CrowdfundingManagerEmitter is MultiEventsHistoryAdapter {
    event ComplainCreated(address indexed self, address indexed creator, bytes32 symbol, address crowdsale);
    event Error(address indexed self, uint errorCode);

    function emitComplainCreated(address creator, bytes32 symbol, address crowdsale) {
        ComplainCreated(_self(), creator, symbol, crowdsale);
    }

    function emitError(uint errorCode) {
        Error(_self(), errorCode);
    }
}
