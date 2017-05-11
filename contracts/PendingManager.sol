pragma solidity ^0.4.8;

import "./UserStorage.sol";

contract PendingManager {
// TYPES

    address userStorage;
    mapping (uint => Transaction) public txs;
    mapping(bytes32 => uint) txsIndex;
    uint txsCount = 1;

    struct Transaction {
        address to;
        bytes data;
        uint yetNeeded;
        uint ownersDone;
    }

    uint[] deletedIds;

    function init(address _userStorage) {
        userStorage = _userStorage;
    }

    function pendingsCount() constant returns(uint) {
        return txsCount - deletedIds.length - 1;
    }

    function pendingYetNeeded(bytes32 _hash) constant returns(uint) {
        return txs[txsIndex[_hash]].yetNeeded;
    }

    function getTxsData(bytes32 _hash) constant returns (bytes) {
        return txs[txsIndex[_hash]].data;
    }

    function getPending(uint _id) constant returns (bytes data, uint yetNeeded, uint ownersDone) {
        data = txs[_id].data;
        yetNeeded = txs[_id].yetNeeded;
        ownersDone = txs[_id].ownersDone;
        return (data, yetNeeded, ownersDone);
    }

// EVENTS

// this contract only has six types of events: it can accept a confirmation, in which case
// we record owner and operation (hash) alongside it.
    event Confirmation(address owner, bytes32 operation);
    event Revoke(address owner, bytes32 operation);
    event Done(bytes data);

/// MODIFIERS

// simple single-sig function modifier.
  //  modifier onlyOwner {
  //      if (isOwner(msg.sender))
  //      _;
  //  }

// multi-sig function modifier: the operation must have an intrinsic hash in order
// that later attempts can be realised as the same underlying operation and
// thus count as confirmations.
    modifier onlymanyowners(bytes32 _operation, address _sender) {
        if (confirmAndCheck(_operation, _sender))
        _;
    }


// METHODS

    function addTx(bytes32 _r, bytes data, address to, address sender) {
        if(isOwner(sender)) {
            uint id;
            if(deletedIds.length != 0) {
                id = deletedIds[deletedIds.length-1];
                deletedIds.length--;
            }
            else {
                id = txsCount;
                txsCount++;
            }
            txsIndex[_r] = id;
            txs[id].data = data;
            txs[id].to = to;
            txs[id].yetNeeded = UserStorage(userStorage).required();
            txs[id].ownersDone = 0;
            conf(_r, sender);
        }
    }

    function confirm(bytes32 _h) returns (bool) {
        return conf(_h, msg.sender);
    }

    function conf(bytes32 _h, address sender) onlymanyowners(_h, sender) returns (bool) {
        if (txs[txsIndex[_h]].to != 0) {
            if (!txs[txsIndex[_h]].to.call(txs[txsIndex[_h]].data)) {
                throw;
            }
            deleteTx(_h);
            return true;
        }
    }

    function deleteTx(bytes32 _h) internal {
        if(txsIndex[_h] == txsCount - 1)
            txsCount--;
        else
            deletedIds.push(txsIndex[_h]);
        delete txsIndex[_h];
        delete txs[txsIndex[_h]];

    }

// Revokes a prior confirmation of the given operation
    function revoke(bytes32 _operation) external {
        if(isOwner(msg.sender)) {
            uint index = UserStorage(userStorage).getMemberId(msg.sender);
        // make sure they're an owner
            if (index == 0) return;
            uint ownerIndexBit = 2**index;
            var pending = txs[txsIndex[_operation]];
            if (pending.ownersDone & ownerIndexBit > 0) {
                pending.yetNeeded++;
                pending.ownersDone -= ownerIndexBit;
                Revoke(msg.sender, _operation);
                if(pending.yetNeeded == UserStorage(userStorage).required()) {
                    deleteTx(_operation);
                }
            }

        }
    }

// Gets an owner by 0-indexed position (using numOwners as the count)
    function getOwner(uint ownerIndex) external constant returns (address) {
        return UserStorage(userStorage).getMemberAddr(ownerIndex);
    }

    function isOwner(address _addr) constant returns (bool) {
        return UserStorage(userStorage).getCBE(_addr);
    }

    function hasConfirmed(bytes32 _operation, address _owner) constant returns (bool) {
        var pending = txs[txsIndex[_operation]];
        if(isOwner(_owner)) {
            uint index = UserStorage(userStorage).getMemberId(_owner);
        // make sure they're an owner
            if (index == 0) return false;

        // determine the bit to set for this owner.
            uint ownerIndexBit = 2**index;
            return !(pending.ownersDone & ownerIndexBit == 0);
        }
    }

// INTERNAL METHODS

    function confirmAndCheck(bytes32 _operation, address sender) internal returns (bool) {
        if(isOwner(sender)) {
        // determine what index the present sender is:
            uint index = UserStorage(userStorage).getMemberId(sender);

        // make sure they're an owner
            if (index == 0) return;
            Transaction pending = txs[txsIndex[_operation]];
        // determine the bit to set for this owner.
            uint ownerIndexBit = 2**index;
        // make sure we (the message sender) haven't confirmed this operation previously.
            if (pending.ownersDone & ownerIndexBit == 0) {
                Confirmation(msg.sender, _operation);
            // ok - check if count is enough to go ahead.
                if (pending.yetNeeded <= 1) {
                // enough confirmations: reset and run interior.
                    Done(txs[txsIndex[_operation]].data);
                    return true;
                }
                else
                {
                // not enough: record that this owner in particular confirmed.
                    pending.yetNeeded--;
                    pending.ownersDone |= ownerIndexBit;
                    return false;
                }
            }
        }
    }

    function()
    {
        throw;
    }
}
