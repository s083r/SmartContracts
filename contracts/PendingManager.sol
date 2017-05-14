pragma solidity ^0.4.8;

import "./UserStorage.sol";

contract PendingManager {
    // TYPES

    address userStorage;
    mapping (uint => Transaction) public txs;
    mapping (bytes32 => uint) txsIndex;
    uint txsCount = 1;

    struct Transaction {
        address to;
        bytes32 hash;
        bytes data;
        uint yetNeeded;
        uint ownersDone;
        uint timestamp;
    }

    uint[] deletedIds;


    // EVENTS

    event Confirmation(address owner, uint id);
    event Revoke(address owner, uint id);
    event Done(bytes32 hash, bytes data, uint timestamp);
    event Error(bytes32 message);


    /// MODIFIERS

    // multi-sig function modifier: the operation must have an intrinsic hash in order
    // that later attempts can be realised as the same underlying operation and
    // thus count as confirmations
    modifier onlyManyOwners(bytes32 _operation, address _sender) {
        if (confirmAndCheck(_operation, _sender)) {
            _;
        }
    }

    // METHODS

    function init(address _userStorage) {
        userStorage = _userStorage;
    }

    function pendingsCount() constant returns (uint) {
        return txsCount - deletedIds.length - 1;
    }

    function pendingYetNeeded(bytes32 _hash) constant returns (uint) {
        return txs[txsIndex[_hash]].yetNeeded;
    }

    function getTxsData(bytes32 _hash) constant returns (bytes) {
        return txs[txsIndex[_hash]].data;
    }

    function getPending(uint _id) constant returns (bytes32 hash, bytes data, uint yetNeeded, uint ownersDone, uint timestamp) {
        return (txs[_id].hash, txs[_id].data, txs[_id].yetNeeded, txs[_id].ownersDone, txs[_id].timestamp);
    }

    function addTx(bytes32 _r, bytes data, address to, address sender) {
        if (txsIndex[_r] != 0) {
            Error("duplicate");
            return;
        }
        if (isOwner(sender)) {
            uint id;
            if (deletedIds.length != 0) {
                id = deletedIds[deletedIds.length - 1];
                deletedIds.length--;
            }
            else {
                id = txsCount;
                txsCount++;
            }
            txsIndex[_r] = id;
            txs[id].hash = _r;
            txs[id].data = data;
            txs[id].to = to;
            txs[id].yetNeeded = UserStorage(userStorage).required();
            txs[id].ownersDone = 0;
            txs[id].timestamp = now;
            conf(_r, sender);
        }
    }

    function confirm(bytes32 _h) returns (bool) {
        return conf(_h, msg.sender);
    }

    function conf(bytes32 _h, address sender) onlyManyOwners(_h, sender) returns (bool) {
        if (txs[txsIndex[_h]].to != 0) {
            if (!txs[txsIndex[_h]].to.call(txs[txsIndex[_h]].data)) {
                throw;
            }
            deleteTx(_h);
            return true;
        }
    }

    // revokes a prior confirmation of the given operation
    function revoke(bytes32 _operation) external {
        if (isOwner(msg.sender)) {
            uint ownerIndexBit = 2 ** UserStorage(userStorage).getMemberId(msg.sender);
            var pending = txs[txsIndex[_operation]];
            if (pending.ownersDone & ownerIndexBit > 0) {
                pending.yetNeeded++;
                pending.ownersDone -= ownerIndexBit;
                Revoke(msg.sender, txsIndex[_operation]);
                if (pending.yetNeeded == UserStorage(userStorage).required()) {
                    deleteTx(_operation);
                }
            }

        }
    }

    // gets an owner by 0-indexed position (using numOwners as the count)
    function getOwner(uint ownerIndex) external constant returns (address) {
        return UserStorage(userStorage).getMemberAddr(ownerIndex);
    }

    function isOwner(address _addr) constant returns (bool) {
        return UserStorage(userStorage).getCBE(_addr);
    }

    function hasConfirmed(bytes32 _operation, address _owner) constant returns (bool) {
        var pending = txs[txsIndex[_operation]];
        if (isOwner(_owner)) {
            // determine the bit to set for this owner
            uint ownerIndexBit = 2 ** UserStorage(userStorage).getMemberId(_owner);
            return !(pending.ownersDone & ownerIndexBit == 0);
        }
    }


    // INTERNAL METHODS

    function confirmAndCheck(bytes32 _operation, address sender) internal returns (bool) {
        if (isOwner(sender)) {
            Transaction pending = txs[txsIndex[_operation]];
            // determine the bit to set for this owner
            uint ownerIndexBit = 2 ** UserStorage(userStorage).getMemberId(sender);
            // make sure we (the message sender) haven't confirmed this operation previously
            if (pending.ownersDone & ownerIndexBit == 0) {
                // ok - check if count is enough to go ahead
                if (pending.yetNeeded <= 1) {
                    // enough confirmations: reset and run interior
                    Done(_operation, pending.data, now);
                    return true;
                } else {
                    // not enough: record that this owner in particular confirmed
                    pending.yetNeeded--;
                    pending.ownersDone |= ownerIndexBit;
                    Confirmation(msg.sender, txsIndex[_operation]);
                    return false;
                }
            }
        }
    }

    function deleteTx(bytes32 _h) internal {
        if (txsIndex[_h] == txsCount - 1) {
            txsCount--;
        } else {
            deletedIds.push(txsIndex[_h]);
        }
        delete txsIndex[_h];
        delete txs[txsIndex[_h]];
    }

    function()
    {
        throw;
    }
}
