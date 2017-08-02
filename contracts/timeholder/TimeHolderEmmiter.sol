pragma solidity ^0.4.11;

import '../core/event/MultiEventsHistoryAdapter.sol';

contract TimeHolderEmmiter is MultiEventsHistoryAdapter {
    /**
    *  User deposited into current period.
    */
    event Deposit(address who, uint amount);

    /**
    *  Shares withdrawn by a shareholder.
    */
    event WithdrawShares(address who, uint amount);

    /**
    *  Shares withdrawn by a shareholder.
    */
    event ListenerAdded(address listener);

    /**
    *  Something went wrong.
    */
    event Error(address indexed self, uint errorCode);

    function emitDeposit(address who, uint amount) {
        Deposit(who, amount);
    }

    function emitWithdrawShares(address who, uint amount) {
        WithdrawShares(who, amount);
    }

    function emitListenerAdded(address listener) {
        ListenerAdded(listener);
    }

    function emitError(uint error) {
        Error(_self(), error);
    }
}
