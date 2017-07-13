pragma solidity ^0.4.8;

import './MultiEventsHistoryAdapter.sol';

contract ERC20ManagerEmitter is MultiEventsHistoryAdapter {

    event Error(address indexed self, uint errorCode);

    function emitError(uint error) {
        Error(_self(), error);
    }
}
