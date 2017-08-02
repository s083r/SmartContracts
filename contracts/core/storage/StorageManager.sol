pragma solidity ^0.4.11;

import '../common/Object.sol';
import '../event/MultiEventsHistoryAdapter.sol';

contract StorageManager is MultiEventsHistoryAdapter, Object {

    uint constant ERROR_STORAGE_INVALID_INVOCATION = 5000;

    event AccessGiven(address indexed self, address actor, bytes32 role);
    event AccessBlocked(address indexed self, address actor, bytes32 role);
    event Error(address indexed self, uint errorCode);

    mapping (address => uint) public authorised;
    mapping (bytes32 => bool) public accessRights;

    function giveAccess(address _actor, bytes32 _role) onlyContractOwner() returns(uint) {
        if (!accessRights[sha3(_actor, _role)]) {
            accessRights[sha3(_actor, _role)] = true;
            authorised[_actor] += 1;
            emitAccessGiven(_actor, _role);
        }

        return OK;
    }

    function blockAccess(address _actor, bytes32 _role) onlyContractOwner() returns(uint) {
        if (accessRights[sha3(_actor, _role)]) {
            delete accessRights[sha3(_actor, _role)];
            authorised[_actor] -= 1;
            if (authorised[_actor] == 0) {
                delete authorised[_actor];
            }
            emitAccessBlocked(_actor, _role);
        }

        return OK;
    }

    function isAllowed(address _actor, bytes32 _role) constant returns(bool) {
        return accessRights[sha3(_actor, _role)] || (this == _actor);
    }

    function hasAccess(address _actor) constant returns(bool) {
        return (authorised[_actor] > 0) || (this == _actor);
    }

    function emitAccessGiven(address _user, bytes32 _role) {
        AccessGiven(this, _user, _role);
    }

    function emitAccessBlocked(address _user, bytes32 _role) {
        AccessBlocked(this, _user, _role);
    }
}
