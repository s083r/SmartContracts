pragma solidity ^0.4.8;

import './MultiEventsHistoryAdapter.sol';

contract WalletsManagerEmitter is MultiEventsHistoryAdapter {

    event Error(address indexed self, uint errorCode);
    event WalletAdded(address indexed self, address wallet);
    event WalletCreated(address indexed self, address wallet);

    function emitError(uint errorCode) {
        Error(_self(), errorCode);
    }

    function emitWalletAdded(address wallet) {
        WalletAdded(_self(), wallet);
    }

    function emitWalletCreated(address wallet) {
        WalletCreated(_self(), wallet);
    }

}
