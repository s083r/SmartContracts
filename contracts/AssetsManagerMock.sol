pragma solidity ^0.4.11;

import "./ContractsManagerInterface.sol";

contract AssetsManagerMock {

    address contractsManager;
    bytes32[] symbols;
    mapping(bytes32 => address) assets;

    function init(address _contractsManager) returns(bool) {
        if(contractsManager != 0x0) {
            return false;
        }

        uint errorCode = ContractsManagerInterface(_contractsManager).addContract(this, bytes32("AssetsManager"));
        if(1 != errorCode) {
            return false;
        }

        contractsManager = _contractsManager;
        return true;
    }

    function getAssetBySymbol(bytes32 symbol) constant returns (address) {
        return assets[symbol];
    }

    function getAssetsCount() constant returns (uint) {
        return symbols.length;
    }

    function getSymbolById(uint _id) constant returns (bytes32) {
        return symbols[_id];
    }

    function addAsset(address asset, bytes32 _symbol, address owner) returns (bool) {
        symbols.push(_symbol);
        assets[_symbol] = asset;
    }

    function isAssetOwner(bytes32 _symbol, address _owner) returns (bool) {
        return true;
    }

    function() {
        throw;
    }
}
