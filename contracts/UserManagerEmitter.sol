pragma solidity ^0.4.8;

import './MultiEventsHistoryAdapter.sol';
import './Errors.sol';

contract UserManagerEmitter is MultiEventsHistoryAdapter {
    using Errors for Errors.E;

    event CBEUpdate(address indexed self, address key);
    event SetRequired(address indexed self, uint required);
    event SetHash(address indexed self, address indexed key, bytes32 oldHash, bytes32 newHash);
    event Error(address indexed self, uint indexed errorCode);

    function emitCBEUpdate(address key) {
        CBEUpdate(_self(), key);
    }

    function emitSetRequired(uint required) {
        SetRequired(_self(), required);
    }

    function emitHashUpdate(address key, bytes32 oldHash, bytes32 newHash) {
        SetHash(_self(), key, oldHash, newHash);
    }

    function emitError(Errors.E e) {
        Error(_self(), e.code());
    }
}
