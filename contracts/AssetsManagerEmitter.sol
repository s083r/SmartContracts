pragma solidity ^0.4.8;

import './MultiEventsHistoryAdapter.sol';

contract AssetsManagerEmitter is MultiEventsHistoryAdapter {
    event Error(address indexed self, uint errorCode);
    event AssetAdded(address indexed self, address asset, bytes32 symbol, address owner);
    event AssetCreated(address indexed self, bytes32 symbol, address token);
    event AssetOwnerAdded(address indexed self, bytes32 symbol, address owner);
    event AssetOwnerRemoved(address indexed self, bytes32 symbol, address owner);

    function emitError(uint errorCode) {
        Error(_self(), errorCode);
    }

    function emitAssetAdded(address asset, bytes32 symbol, address owner) {
        AssetAdded(_self(), asset, symbol, owner);
    }

    function emitAssetCreated(bytes32 symbol, address token) {
        AssetCreated(_self(), symbol, token);
    }

    function emitAssetOwnerAdded(bytes32 symbol, address owner) {
        AssetOwnerAdded(_self(), symbol, owner);
    }

    function emitAssetOwnerRemoved(bytes32 symbol, address owner) {
        AssetOwnerRemoved(_self(), symbol, owner);
    }
}
