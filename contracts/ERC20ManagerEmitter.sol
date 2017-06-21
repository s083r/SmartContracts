pragma solidity ^0.4.8;

import './MultiEventsHistoryAdapter.sol';
import "./Errors.sol";

contract ERC20ManagerEmitter is MultiEventsHistoryAdapter {
    using Errors for Errors.E;
    event Error(address indexed self, uint errorCode);

    function emitError(Errors.E e) {
        Error(_self(),e.code());
    }

}
