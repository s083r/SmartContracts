pragma solidity ^0.4.11;

import "./Managed.sol";
import {ERC20ManagerInterface as ERC20Manager} from "./ERC20ManagerInterface.sol";
import "./ChronoBankPlatformInterface.sol";
import "./ChronoBankAssetInterface.sol";
import "./ChronoBankAssetProxyInterface.sol";
import "./ERC20Interface.sol";
import "./OwnedInterface.sol";
import "./AssetsManagerEmitter.sol";

contract ChronoBankAsset {
    function init(ChronoBankAssetProxyInterface _proxy) returns (bool);
}


contract ProxyFactory {
    function createProxy() returns (address);
    function createAsset() returns (address);
    function createAssetWithFee() returns (address);
}


contract CrowdsaleManager {
    function createCompain(address _fund,
    bytes32 _symbol,
    string _reference,
    uint256 _startBlock,
    uint256 _stopBlock,
    uint256 _minValue,
    uint256 _maxValue,
    uint256 _scale,
    uint256 _startRatio,
    uint256 _reductionStep,
    uint256 _reductionValue) returns (address);
}


contract AssetsManager is Managed, AssetsManagerEmitter {

    uint constant ERROR_ASSETS_INVALID_INVOCATION = 11000;
    uint constant ERROR_ASSETS_EXISTS = 11001;
    uint constant ERROR_ASSETS_TOKEN_EXISTS = 11002;
    uint constant ERROR_ASSETS_CANNON_CLAIM_PLATFORM_OWNERSHIP = 11003;
    uint constant ERROR_ASSETS_WRONG_PLATFORM = 11004;
    uint constant ERROR_ASSETS_NOT_A_PROXY = 11005;
    uint constant ERROR_ASSETS_OWNER_ONLY = 11006;
    uint constant ERROR_ASSETS_CANNOT_ADD_TO_REGISTRY = 11007;

    StorageInterface.Address platform;
    StorageInterface.Address proxyFactory;
    StorageInterface.Set assetsSymbols;
    StorageInterface.Bytes32AddressMapping assets;
    StorageInterface.AddressAddressUIntMapping owners;
    StorageInterface.AddressesSet allOwners;

    //mapping (address => bool) timeHolder;

    modifier onlyAssetOwner(bytes32 _symbol) {
        if (isAssetOwner(_symbol, msg.sender)) {
            _;
        }
    }

    function isAssetSymbolExists(bytes32 _symbol) private constant returns (bool) {
        return store.get(assets, _symbol) != address(0);
    }

    function isAssetOwner(bytes32 _symbol, address _owner) constant returns (bool) {
        return store.get(owners, store.get(assets, _symbol), _owner) == 1;
    }

    function AssetsManager(Storage _store, bytes32 _crate) StorageAdapter(_store, _crate) {
        platform.init('platform');
        proxyFactory.init('proxyFactory');
        assetsSymbols.init('assetsSymbols');
        assets.init('assets');
        owners.init('owners');
        allOwners.init('allOwners');
    }

    function init(address _platform, address _contractsManager, address _proxyFactory) returns (uint) {
        if (store.get(platform) != 0x0 || store.get(contractsManager) != 0x0 || store.get(contractsManager) != 0x0) {
            return ERROR_ASSETS_INVALID_INVOCATION;
        }

        uint e = ContractsManagerInterface(_contractsManager).addContract(this, bytes32("AssetsManager"));
        if (OK != e) {
            return e;
        }

        store.set(contractsManager, _contractsManager);
        store.set(platform, _platform);
        store.set(proxyFactory, _proxyFactory);
        return OK;
    }

    function setupEventsHistory(address _eventsHistory) onlyAuthorized returns (uint) {
        if (getEventsHistory() != 0x0) {
            return ERROR_ASSETS_INVALID_INVOCATION;
        }

        _setEventsHistory(_eventsHistory);
        return OK;
    }

    function claimPlatformOwnership() returns (uint errorCode) {
        if (OwnedInterface(store.get(platform)).claimContractOwnership()) {
            return OK;
        }
        //platform = address(0);
        return _emitError(ERROR_ASSETS_CANNON_CLAIM_PLATFORM_OWNERSHIP);
    }

    function getAssetBalance(bytes32 symbol) constant returns (uint) {
        return ERC20Interface(store.get(assets, symbol)).balanceOf(this);
    }

    function getAssetBySymbol(bytes32 symbol) constant returns (address) {
        return store.get(assets, symbol);
    }

    function getSymbolById(uint _id) constant returns (bytes32) {
        return store.get(assetsSymbols, _id);
    }

    function getAssets() constant returns (bytes32[]) {
        return store.get(assetsSymbols);
    }

    function getAssetsCount() constant returns (uint) {
        return store.count(assetsSymbols);
    }

    function sendAsset(bytes32 _symbol, address _to, uint _value) onlyAssetOwner(_symbol) returns (bool) {
        return ERC20Interface(store.get(assets, _symbol)).transfer(_to, _value);
    }

    function reissueAsset(bytes32 _symbol, uint _value) onlyAssetOwner(_symbol) returns (bool) {
        return ChronoBankPlatformInterface(store.get(platform)).reissueAsset(_symbol, _value);
    }

    function revokeAsset(bytes32 _symbol, uint _value) onlyAssetOwner(_symbol) returns (bool) {
        return ChronoBankPlatformInterface(store.get(platform)).revokeAsset(_symbol, _value);
    }

    function addAsset(address asset, bytes32 _symbol, address owner) returns (uint errorCode) {
        if (isAssetSymbolExists(_symbol)) {
            return _emitError(ERROR_ASSETS_EXISTS);
        }

        address _platform = store.get(platform);
        if (ChronoBankAssetProxyInterface(asset).chronoBankPlatform() != _platform) {
            return _emitError(ERROR_ASSETS_WRONG_PLATFORM);
        }

        if (ChronoBankPlatformInterface(_platform).proxies(_symbol) != asset) {
            return _emitError(ERROR_ASSETS_NOT_A_PROXY);
        }

        if (!ChronoBankPlatformInterface(_platform).isOwner(this, _symbol)) {
            return _emitError(ERROR_ASSETS_OWNER_ONLY);
        }

        uint8 decimals = ChronoBankPlatformInterface(_platform).baseUnit(_symbol);
        address erc20Manager = ContractsManagerInterface(store.get(contractsManager)).getContractAddressByType(bytes32("ERC20Manager"));
        if (!ERC20Manager(erc20Manager).addToken(asset, _symbol, _symbol, bytes32(0), decimals, bytes32(0), bytes32(0))) {
            return _emitError(ERROR_ASSETS_CANNOT_ADD_TO_REGISTRY);
        }

        store.set(assets, _symbol, asset);
        store.add(assetsSymbols, _symbol);
        store.set(owners, asset, owner, 1);
        store.add(allOwners, owner);

        _emitAssetAdded(asset, _symbol, owner);

        return OK;
    }

    function createAsset(bytes32 symbol, string name, string description, uint value, uint8 decimals, bool isMint, bool withFee) returns (uint errorCode) {
        if (isAssetSymbolExists(symbol)) {
            return _emitError(ERROR_ASSETS_EXISTS);
        }

        address erc20Manager = ContractsManagerInterface(store.get(contractsManager)).getContractAddressByType(bytes32("ERC20Manager"));
        address token = ERC20Manager(erc20Manager).getTokenAddressBySymbol(symbol);
        if (token != address(0)) {
            return _emitError(ERROR_ASSETS_TOKEN_EXISTS);
        }

        token = ProxyFactory(store.get(proxyFactory)).createProxy();
        address asset;
        ChronoBankPlatformInterface(store.get(platform)).issueAsset(symbol, value, name, description, decimals, isMint);
        if (withFee) {
            asset = ProxyFactory(store.get(proxyFactory)).createAssetWithFee();
        }
        else {
            asset = ProxyFactory(store.get(proxyFactory)).createAsset();
        }
        ChronoBankPlatformInterface(store.get(platform)).setProxy(token, symbol);
        ChronoBankAssetProxyInterface(token).init(store.get(platform), bytes32ToString(symbol), name);
        ChronoBankAssetProxyInterface(token).proposeUpgrade(asset);
        ChronoBankAsset(asset).init(ChronoBankAssetProxyInterface(token));
        if (!ERC20Manager(erc20Manager).addToken(token, bytes32(0), symbol, bytes32(0), decimals, bytes32(0), bytes32(0))) {
            return _emitError(ERROR_ASSETS_CANNOT_ADD_TO_REGISTRY);
        }

        store.set(assets, symbol, token);
        store.add(assetsSymbols, symbol);
        store.set(owners, token, msg.sender, 1);
        store.add(allOwners, msg.sender);
        _emitAssetCreated(symbol, token);
        return OK;
    }

    function startCompain() {

    }

    function addAssetOwner(bytes32 _symbol, address _owner) returns (uint errorCode) {
        if (!isAssetOwner(_symbol, msg.sender)) {
            return _emitError(ERROR_ASSETS_OWNER_ONLY);
        }

        store.set(owners, store.get(assets, _symbol), _owner, 1);
        store.add(allOwners, _owner);
        _emitAssetOwnerAdded(_symbol, _owner);
        return OK;
    }

    function deleteAssetOwner(bytes32 _symbol, address _owner) returns (uint errorCode) {
        if (!isAssetOwner(_symbol, msg.sender)) {
            return _emitError(ERROR_ASSETS_OWNER_ONLY);
        }

        store.set(owners, store.get(assets, _symbol), _owner, 0);
        store.remove(allOwners, _owner);
        _emitAssetOwnerRemoved(_symbol, _owner);
        return OK;
    }

    function getAssetOwners(bytes32 _symbol) constant returns (address[]) {
        uint counter;
        uint i;
        for (i = 0; i < store.count(allOwners); i++) {
            if (isAssetOwner(_symbol, store.get(allOwners, i))) {
                counter++;
            }
        }
        address[] memory result = new address[](counter);
        counter = 0;
        for (i = 0; i < store.count(allOwners); i++) {
            if (isAssetOwner(_symbol, store.get(allOwners, i))) {
                result[i] = store.get(allOwners, i);
                counter++;
            }
        }
        return result;
    }

    function getAssetsForOwner(address owner) constant returns (bytes32[] result) {
        uint counter;
        uint i;
        for (i = 0; i < store.count(assetsSymbols); i++) {
            if (isAssetOwner(store.get(assetsSymbols, i), owner))
            counter++;
        }
        result = new bytes32[](counter);
        counter = 0;
        for (i = 0; i < store.count(assetsSymbols); i++) {
            if (isAssetOwner(store.get(assetsSymbols, i), owner)) {
                result[counter] = store.get(assetsSymbols, i);
                counter++;
            }
        }
        return result;
    }

    function bytes32ToString(bytes32 x) constant returns (string) {
        bytes memory bytesString = new bytes(32);
        uint charCount = 0;
        for (uint j = 0; j < 32; j++) {
            byte char = byte(bytes32(uint(x) * 2 ** (8 * j)));
            if (char != 0) {
                bytesString[charCount] = char;
                charCount++;
            }
        }
        bytes memory bytesStringTrimmed = new bytes(charCount);
        for (j = 0; j < charCount; j++) {
            bytesStringTrimmed[j] = bytesString[j];
        }
        return string(bytesStringTrimmed);
    }

    function _emitError(uint error) internal returns (uint) {
        AssetsManager(getEventsHistory()).emitError(error );
        return error;
    }

    function _emitAssetAdded(address asset, bytes32 symbol, address owner) internal {
        AssetsManager(getEventsHistory()).emitAssetAdded(asset, symbol, owner);
    }

    function _emitAssetCreated(bytes32 symbol, address token) internal {
        AssetsManager(getEventsHistory()).emitAssetCreated(symbol, token);
    }

    function _emitAssetOwnerAdded(bytes32 symbol, address owner) internal {
        AssetsManager(getEventsHistory()).emitAssetOwnerAdded(symbol, owner);
    }

    function _emitAssetOwnerRemoved(bytes32 symbol, address owner) internal {
        AssetsManager(getEventsHistory()).emitAssetOwnerRemoved(symbol, owner);
    }

    function()
    {
        throw;
    }
}
