pragma solidity ^0.4.8;


/*
 * Shareable
 *
 * Based on https://github.com/ethereum/dapp-bin/blob/master/wallet/wallet.sol
 *
 * inheritable "property" contract that enables methods to be protected by requiring the acquiescence of either a single, or, crucially, each of a number of, designated owners.
 *
 * usage:
 * use modifiers onlyowner (just own owned) or onlymanyowners(hash), whereby the same hash must be provided by some number (specified in constructor) of the set of owners (specified in the constructor) before the interior is executed.
 */
contract Shareable {
  // TYPES

  // struct for the status of a pending operation.
  struct PendingState {
    uint yetNeeded;
    uint ownersDone;
    uint index;
  }


  // FIELDS

  // the number of owners that must confirm the same operation before it is run.
  uint public required;

  mapping (uint => Member) public members;

  struct Member {
    address memberAddr;
    bytes32 hash1;
    bytes14 hash2;
    bool isCBE;
  }

  mapping(uint => uint) userIndex;
  uint public userCount = 1;
  // the ongoing operations.
  mapping(bytes32 => PendingState) pendings;
  bytes32[] pendingsIndex;


  // EVENTS

  // this contract only has six types of events: it can accept a confirmation, in which case
  // we record owner and operation (hash) alongside it.
  event Confirmation(address owner, bytes32 operation);
  event Revoke(address owner, bytes32 operation);

  // MODIFIERS

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

  // Revokes a prior confirmation of the given operation
  function revoke(bytes32 _operation) external {
    if(isOwner(msg.sender)) {
    uint index = userIndex[uint(msg.sender)];
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
    return address(members[userCount].memberAddr);
  }

  function isOwner(address _addr) constant returns (bool) {
    return members[userIndex[uint(_addr)]].isCBE;
  }

  function hasConfirmed(bytes32 _operation, address _owner) constant returns (bool) {
    var pending = pendings[_operation];
    if(isOwner(_owner)) {
      uint index = userIndex[uint(_owner)];
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
    uint index = userIndex[uint(msg.sender)];
    // make sure they're an owner
    if (index == 0) return;

    var pending = pendings[_operation];
    // if we're not yet working on this operation, switch over and reset the confirmation status.
    if (pending.yetNeeded == 0) {
      // reset count of confirmations needed.
      pending.yetNeeded = required;
      // reset which owners have confirmed (none) - set our bitmap to 0.
      pending.ownersDone = 0;
      pending.index = pendingsIndex.length++;
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
    if (i >= pendingsIndex.length) return;

        while(i<pendingsIndex.length-1){
            pendings[pendingsIndex[i+1]].index = pendings[pendingsIndex[i]].index;
            pendingsIndex[i] = pendingsIndex[i+1];
            i++;
        }
        pendingsIndex.length--;
    }

  function clearPending() internal {
    uint length = pendingsIndex.length;
    for (uint i = 0; i < length; ++i)
    if (pendingsIndex[i] != 0)
      delete pendings[pendingsIndex[i]];
    delete pendingsIndex;
  }

}
