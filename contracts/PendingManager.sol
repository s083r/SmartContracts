pragma solidity ^0.4.8;

import "./UserManager.sol";

contract PendingManager {
  // TYPES

    address userManager;

    enum Operations {createLOC, editLOC, addLOC, removeLOC, editMint, changeReq}
 
    event Test(bytes32 test);

    mapping (bytes32 => Transaction) public txs;

    struct Transaction {
        address to;
        bytes data;
        Operations op;
    }

  // struct for the status of a pending operation.
  struct PendingState {
    uint yetNeeded;
    uint ownersDone;
    uint index;
  }

  function init(address _userManager) {
    userManager = _userManager;
  }

  // FIELDS

  // the ongoing operations.
  mapping(bytes32 => PendingState) pendings;
  mapping(uint => bytes32) pendingsIndex;

  function pendingsCount() constant returns(uint) {
    return UserManager(userManager).pending();
  }

  function pendingById(uint _id) constant returns(bytes32) {
    return pendingsIndex[_id];
  }

  function pendingYetNeeded(bytes32 _hash) constant returns(uint) {
    return pendings[_hash].yetNeeded;
  }

    function getTxsType(bytes32 _hash) returns (uint) {
        return uint(txs[_hash].op);
    }

    function getTxsData(bytes32 _hash) constant returns (bytes) {
        return txs[_hash].data;
    }

  // EVENTS

  // this contract only has six types of events: it can accept a confirmation, in which case
  // we record owner and operation (hash) alongside it.
  event Confirmation(address owner, bytes32 operation);
  event Revoke(address owner, bytes32 operation);

  /// MODIFIERS

  // simple single-sig function modifier.
  modifier onlyOwner {
    if (isOwner(msg.sender))
      _;
  }

  // multi-sig function modifier: the operation must have an intrinsic hash in order
  // that later attempts can be realised as the same underlying operation and
  // thus count as confirmations.
  modifier onlymanyowners(bytes32 _operation) {
    if (confirmAndCheck(_operation))
      _;
  }


  // METHODS

    function addTx(bytes32 _r, bytes data, Operations op, address to) {
                txs[_r].data = data;
                txs[_r].op = op;
                txs[_r].to = to;
                confirm(_r);
    }

  function confirm(bytes32 _h) onlymanyowners(_h) returns (bool) {
        if (txs[_h].to != 0) {
            if (!txs[_h].to.call(txs[_h].data)) {
                throw;
            }
            delete txs[_h];
            return true;
        }
    }

  // Revokes a prior confirmation of the given operation
  function revoke(bytes32 _operation) external {
    if(isOwner(msg.sender)) {
    uint index = UserManager(userManager).getMemberId(msg.sender);
    // make sure they're an owner
    if (index == 0) return;
    uint ownerIndexBit = 2**index;
    var pending = pendings[_operation];
    if (pending.ownersDone & ownerIndexBit > 0) {
      pending.yetNeeded++;
      pending.ownersDone -= ownerIndexBit;
      Revoke(msg.sender, _operation);
    }
    }
  }

  // Gets an owner by 0-indexed position (using numOwners as the count)
  function getOwner(uint ownerIndex) external constant returns (address) {
    return UserManager(userManager).getMemberAddr(ownerIndex);
  }

  function isOwner(address _addr) constant returns (bool) {
    return UserManager(userManager).getCBE(_addr);
  }

  function hasConfirmed(bytes32 _operation, address _owner) constant returns (bool) {
    var pending = pendings[_operation];
    if(isOwner(_owner)) {
      uint index = UserManager(userManager).getMemberId(_owner);
      // make sure they're an owner
      if (index == 0) return false;

      // determine the bit to set for this owner.
      uint ownerIndexBit = 2**index;
      return !(pending.ownersDone & ownerIndexBit == 0);
    }
  }

  // INTERNAL METHODS

  function confirmAndCheck(bytes32 _operation) internal returns (bool) {
    if(isOwner(msg.sender)) {
    // determine what index the present sender is:
    uint index = UserManager(userManager).getMemberId(msg.sender);
    // make sure they're an owner
    if (index == 0) return;

    var pending = pendings[_operation];
    // if we're not yet working on this operation, switch over and reset the confirmation status.
    if (pending.yetNeeded == 0) {
      // reset count of confirmations needed.
      pending.yetNeeded = UserManager(userManager).required();
      // reset which owners have confirmed (none) - set our bitmap to 0.
      pending.ownersDone = 0;
      pending.index = UserManager(userManager).incrPend();
      pendingsIndex[pending.index] = _operation;
    }
    // determine the bit to set for this owner.
    uint ownerIndexBit = 2**index;
    // make sure we (the message sender) haven't confirmed this operation previously.
    if (pending.ownersDone & ownerIndexBit == 0) {
      Confirmation(msg.sender, _operation);
      // ok - check if count is enough to go ahead.
      if (pending.yetNeeded <= 1) {
        // enough confirmations: reset and run interior.
        delete pendingsIndex[pendings[_operation].index];
        removeOp(pendings[_operation].index);
        delete pendings[_operation];
        return true;
      }
      else
        {
          // not enough: record that this owner in particular confirmed.
          pending.yetNeeded--;
          pending.ownersDone |= ownerIndexBit;
        }
    }
    }
  }

  function removeOp(uint i) {
    uint count = UserManager(userManager).pending();
    if (i >= count) return;

        while(i<count-1){
            pendings[pendingsIndex[i+1]].index = pendings[pendingsIndex[i]].index;
            pendingsIndex[i] = pendingsIndex[i+1];
            i++;
        }
        UserManager(userManager).decrPend();
    }

  function clearPending() internal {
    uint length = UserManager(userManager).pending();
    for (uint i = 0; i < length; ++i)
    if (pendingsIndex[i] != 0) {
      delete pendings[pendingsIndex[i]];
      delete pendingsIndex[i];
    }
  }

}
