pragma solidity ^0.4.8;

import './Owned.sol';
import './MultiEventsHistoryAdapter.sol';

contract StorageManager is MultiEventsHistoryAdapter, Owned {

    uint constant OK = 1;
    uint constant ERROR_STORAGE_INVALID_INVOCATION = 5000;

    event AccessGiven(address indexed self, address actor, bytes32 role);
    event AccessBlocked(address indexed self, address actor, bytes32 role);
    event Error(address indexed self, uint errorCode);

    mapping(address => mapping(bytes32 => bool)) internal approvedContracts;

    function setupEventsHistory(address _eventsHistory) onlyContractOwner() returns(uint) {
        if (getEventsHistory() != 0x0) {
            return ERROR_STORAGE_INVALID_INVOCATION;
        }

        _setEventsHistory(_eventsHistory);
        return OK;
    }

    function giveAccess(address _actor, bytes32 _role) onlyContractOwner() returns(uint) {
        approvedContracts[_actor][_role] = true;
        _emitAccessGiven(_actor, _role);
        return OK;
    }

    function blockAccess(address _actor, bytes32 _role) onlyContractOwner() returns(uint) {
        approvedContracts[_actor][_role] = false;
        _emitAccessBlocked(_actor, _role);
        return OK;
    }

    function isAllowed(address _actor, bytes32 _role) constant returns(bool) {
        return approvedContracts[_actor][_role];
    }

    function _emitAccessGiven(address _user, bytes32 _role) internal {
        if (getEventsHistory() != 0x0) {
            StorageManager(getEventsHistory()).emitAccessGiven(_user, _role);
        }
    }

    function _emitAccessBlocked(address _user, bytes32 _role) internal {
        if (getEventsHistory() != 0x0) {
            StorageManager(getEventsHistory()).emitAccessBlocked(_user, _role);
        }
    }

    function _emitError(uint error) internal returns (uint) {
        if (getEventsHistory() != 0x0) {
            StorageManager(getEventsHistory()).emitError(error);
        }

        return error;
    }

    function emitAccessGiven(address _user, bytes32 _role) {
        AccessGiven(_self(), _user, _role);
    }

    function emitAccessBlocked(address _user, bytes32 _role) {
        AccessBlocked(_self(), _user, _role);
    }

    function emitError(uint errorCode) {
        Error(_self(), errorCode);
    }
}
