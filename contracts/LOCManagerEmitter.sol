pragma solidity ^0.4.8;
import './MultiEventsHistoryAdapter.sol';

contract LOCManagerEmitter is MultiEventsHistoryAdapter {

    event HashUpdate(address indexed self, bytes32 indexed locName, bytes32 oldHash, bytes32 newHash);
    event NewLOC(address indexed self, bytes32 indexed locName);
    event UpdLOCIssued(address indexed self,bytes32 indexed locName, uint issued);
    event UpdLOCName(address indexed self, bytes32 indexed locName, bytes32 indexed newName);
    event RemLOC(address indexed self, bytes32 indexed locName);
    event UpdLOCStatus(address indexed self, bytes32 indexed locName, uint _oldStatus, uint newStatus);
    event Reissue(address indexed self, bytes32 indexed locName, uint value);
    event Revoke(address indexed self, bytes32 indexed locName, uint value);
    event Error(address indexed self, bytes32 indexed error);

    function emitNewLOC(bytes32 locName) {
        NewLOC(_self(),locName);
    }
    function emitRemLOC(bytes32 locName) {
        RemLOC(_self(),locName);
    }
    function emitUpdLOCStatus(bytes32 locName, uint _oldStatus, uint _newStatus) {
        UpdLOCStatus(_self(),locName,_oldStatus,_newStatus);
    }
    function emitUpdLOCIssued(bytes32 locName, uint _issued) {

    }
    function emitUpdLOCName(bytes32 _locName, bytes32 _newName) {
        UpdLOCName(_self(),_locName,_newName);
    }
    function emitReissue(bytes32 locName, uint value) {
        Reissue(_self(),locName,value);
    }
    function emitRevoke(bytes32 locName, uint value) {
        Revoke(_self(),locName,value);
    }
    function emitHashUpdate(bytes32 locName, bytes32 oldHash, bytes32 newHash) {
        HashUpdate(_self(),locName,oldHash,newHash);
    }
    function emitError(bytes32 _message) {
        Error(_self(),_message);
    }

}