pragma solidity ^0.4.8;

import './MultiEventsHistoryAdapter.sol';
import './Errors.sol';

contract TimeHolderEmmiter is MultiEventsHistoryAdapter {
    using Errors for Errors.E;

    /**
    *  User deposited into current period.
    */
    event Deposit(address indexed who, uint indexed amount);

    /**
    *  Shares withdrawn by a shareholder.
    */
    event WithdrawShares(address indexed who, uint amount);

    /**
    *  Shares withdrawn by a shareholder.
    */
    event ListenerAdded(address indexed listener);

    /**
    *  Something went wrong.
    */
    event Error(address indexed self, uint indexed errorCode);

    function emitDeposit(address who, uint amount) {
        Deposit(who, amount);
    }

    function emitWithdrawShares(address who, uint amount) {
        WithdrawShares(who, amount);
    }

    function emitListenerAdded(address listener) {
        ListenerAdded(listener);
    }

    function emitError(Errors.E e) {
        Error(_self(), e.code());
    }
}
