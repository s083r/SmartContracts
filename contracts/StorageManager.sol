pragma solidity ^0.4.8;

import './Owned.sol';
import './MultiEventsHistoryAdapter.sol';
import "./Errors.sol";

contract StorageManager is MultiEventsHistoryAdapter, Owned {
    using Errors for Errors.E;

    event AccessGiven(address indexed self, address actor, bytes32 role);
    event AccessBlocked(address indexed self, address actor, bytes32 role);
    event Error(address indexed self, uint errorCode);

    mapping(address => mapping(bytes32 => bool)) internal approvedContracts;

    function setupEventsHistory(address _eventsHistory) onlyContractOwner() returns(uint errorCode) {
        if (getEventsHistory() != 0x0) {
            return Errors.E.STORAGE_INVALID_INVOCATION.code();
        }

        _setEventsHistory(_eventsHistory);
        return Errors.E.OK.code();
    }

    function giveAccess(address _actor, bytes32 _role) onlyContractOwner() returns(uint errorCode) {
        approvedContracts[_actor][_role] = true;
        _emitAccessGiven(_actor, _role);
        errorCode = Errors.E.OK.code();
    }

    function blockAccess(address _actor, bytes32 _role) onlyContractOwner() returns(uint errorCode) {
        approvedContracts[_actor][_role] = false;
        _emitAccessBlocked(_actor, _role);
        errorCode = Errors.E.OK.code();
    }

    function isAllowed(address _actor, bytes32 _role) constant returns(bool) {
        return approvedContracts[_actor][_role];
    }

    function _emitAccessGiven(address _user, bytes32 _role) internal {
        StorageManager(getEventsHistory()).emitAccessGiven(_user, _role);
    }

    function _emitAccessBlocked(address _user, bytes32 _role) internal {
        StorageManager(getEventsHistory()).emitAccessBlocked(_user, _role);
    }

    function _emitError(Errors.E error) internal returns (Errors.E) {
        StorageManager(getEventsHistory()).emitError(error.code());
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
