pragma solidity ^0.4.11;

import '../core/event/MultiEventsHistoryAdapter.sol';

contract LOCManagerEmitter is MultiEventsHistoryAdapter {
    event AssetSent(address indexed self, bytes32 symbol, address indexed to, uint value);
    event HashUpdate(address indexed self, bytes32 locName, bytes32 oldHash, bytes32 newHash);
    event NewLOC(address indexed self, bytes32 locName, uint count);
    event UpdateLOC(address indexed self, bytes32 locName, bytes32 newName);
    event RemLOC(address indexed self, bytes32 indexed locName);
    event UpdLOCStatus(address indexed self, bytes32 locName, uint oldStatus, uint newStatus);
    event Reissue(address indexed self, bytes32 locName, uint value);
    event Revoke(address indexed self, bytes32 locName, uint value);
    event Error(address indexed self, uint errorCode);

    function emitAssetSent(bytes32 _symbol, address _to, uint _value) {
        AssetSent(_self(), _symbol, _to, _value);
    }

    function emitNewLOC(bytes32 _locName, uint _count) {
        NewLOC(_self(), _locName, _count);
    }

    function emitRemLOC(bytes32 _locName) {
        RemLOC(_self(), _locName);
    }

    function emitUpdLOCStatus(bytes32 locName, uint _oldStatus, uint _newStatus) {
        UpdLOCStatus(_self(), locName, _oldStatus, _newStatus);
    }

    function emitUpdateLOC(bytes32 _locName, bytes32 _newName) {
        UpdateLOC(_self(), _locName, _newName);
    }

    function emitReissue(bytes32 _locName, uint _value) {
        Reissue(_self(), _locName, _value);
    }

    function emitRevoke(bytes32 _locName, uint _value) {
        Revoke(_self(), _locName, _value);
    }

    function emitHashUpdate(bytes32 _locName, bytes32 _oldHash, bytes32 _newHash) {
        HashUpdate(_self(), _locName, _oldHash, _newHash);
    }

    function emitError(uint _errorCode) {
        Error(_self(), _errorCode);
    }
}
