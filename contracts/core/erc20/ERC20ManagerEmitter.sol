pragma solidity ^0.4.11;

import '../event/MultiEventsHistoryAdapter.sol';

contract ERC20ManagerEmitter is MultiEventsHistoryAdapter {

    event Error(address indexed self, uint errorCode);

    function emitError(uint error) {
        Error(_self(), error);
    }
}
