pragma solidity ^0.4.8;

import "./Configurable.sol";
import "./Shareable.sol";

contract Managed is Configurable, Shareable {
    enum Operations {createLOC, editLOC, addLOC, removeLOC, editMint, changeReq}
    mapping (bytes32 => Transaction) public txs;
    uint adminCount = 0;
    event cbeUpdate(address key);

    struct Transaction {
        address to;
        bytes data;
        Operations op;
    }

    function Managed() {
        members[userCount] = Member(msg.sender, 0, 0, true);
        userIndex[uint(msg.sender)] = userCount;
        userCount++;
        adminCount++;
        required = 1;
    }

    function createMemberIfNotExist(address key) internal {
        if (userIndex[uint(key)] == uint(0x0)) {
            members[userCount] = Member(key, 0, 0, false);
            userIndex[uint(key)] = userCount;
            userCount++;
        }
    }

    function setMemberHash(address key, bytes32 _hash1, bytes14 _hash2) onlyAuthorized() returns (bool) {
        createMemberIfNotExist(key);
        members[userIndex[uint(key)]].hash1 = _hash1;
        members[userIndex[uint(key)]].hash2 = _hash2;
        return true;
    }

    function setOwnHash(bytes32 _hash1, bytes14 _hash2) returns (bool) {
        createMemberIfNotExist(msg.sender);
        members[userIndex[uint(msg.sender)]].hash1 = _hash1;
        members[userIndex[uint(msg.sender)]].hash2 = _hash2;
        return true;
    }

    function getMemberHash(address key) constant returns (bytes32 hash1, bytes14 hash2) {
        return (members[userIndex[uint(key)]].hash1, members[userIndex[uint(key)]].hash2);
    }

    function getCBEMembers() constant returns (address[] addresses, bytes32[] hashes1, bytes14[] hashes2) {
        addresses = new address[](adminCount);
        hashes1 = new bytes32[](adminCount);
        hashes2 = new bytes14[](adminCount);
        uint j = 0;
        for (uint i = 1; i < userCount; i++) {
            if (members[i].isCBE) {
                addresses[j] = members[i].memberAddr;
                hashes1[j] = members[i].hash1;
                hashes2[j] = members[i].hash2;
                j++;
            }
        }
        return (addresses, hashes1, hashes2);
    }

    function getTxsType(bytes32 _hash) returns (uint) {
        return uint(txs[_hash].op);
    }

    function getTxsData(bytes32 _hash) constant returns (bytes) {
        return txs[_hash].data;
    }

    function setRequired(uint _required) execute(Operations.changeReq) {
        if (_required > 1 && _required < adminCount) {
            required = _required;
        }
    }

    modifier onlyAuthorized() {
        if (isAuthorized(msg.sender)) {
            _;
        }
    }

    modifier execute(Operations _type) {
        if (required > 1) {
            if (this != msg.sender) {
                bytes32 _r = sha3(msg.data, "signature");
                txs[_r].data = msg.data;
                txs[_r].op = _type;
                txs[_r].to = this;
                confirm(_r);
            }
            else {
                _;
            }
        }
        else {
            _;
        }
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

    function isAuthorized(address key) returns (bool) {
        if (isOwner(key) || this == key) {
            return true;
        }
        return false;
    }

    function addKey(address key) execute(Operations.createLOC) {
        createMemberIfNotExist(key);
        if (!members[userIndex[uint(key)]].isCBE) { // Make sure that the key being submitted isn't already CBE
            members[userIndex[uint(key)]].isCBE = true;
            cbeUpdate(key);
            adminCount++;
            if (adminCount > 1)
            {
                required++;
            }
        }
    }

    function revokeKey(address key) execute(Operations.createLOC) {
        // Make sure that the key being revoked is exist and is CBE
        if (userIndex[uint(key)] != uint(0x0) && members[userIndex[uint(key)]].isCBE) {
            members[userIndex[uint(key)]].isCBE = false;
            cbeUpdate(key);
            adminCount--;
            if (adminCount >= 1)
            {
                required--;
            }
        }
    }
}
