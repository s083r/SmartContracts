pragma solidity ^0.4.11;

import "../core/common/BaseManager.sol";
import "./Wallet.sol";
import "./WalletsManagerEmitter.sol";

contract WalletsManager is WalletsManagerEmitter, BaseManager {

    uint constant ERROR_WALLET_INVALID_INVOCATION = 14000;
    uint constant ERROR_WALLET_EXISTS = 14001;
    uint constant ERROR_WALLET_OWNER_ONLY = 14002;
    uint constant ERROR_WALLET_CANNOT_ADD_TO_REGISTRY = 14003;
    uint constant ERROR_WALLET_UNKNOWN = 14004;

StorageInterface.OrderedAddressesSet wallets;

    function isWalletOwner(address _wallet, address _owner) internal returns (bool) {
        return Wallet(_wallet).isOwner(_owner);
    }

    function WalletsManager(Storage _store, bytes32 _crate) BaseManager(_store, _crate) {
        wallets.init('wallets');
    }

    function init(address _contractsManager) onlyContractOwner returns (uint) {
        BaseManager.init(_contractsManager, "WalletsManager");
        return OK;
    }

    function kill(address[] tokens) onlyAuthorized returns (uint) {
        withdrawnTokens(tokens,msg.sender);
        selfdestruct(msg.sender);
        return OK;
    }

    function getWallets() constant returns (address[] result) {
        StorageInterface.Iterator memory iterator = store.listIterator(wallets);
        address wallet;
        result = new address[](store.count(wallets));
        for(uint j = 0; store.canGetNextWithIterator(wallets, iterator);) {
            wallet = store.getNextWithIterator(wallets, iterator);
            if (isWalletOwner(wallet,msg.sender)) {
                result[j++] = wallet;
            }
        }
    }

    function addWallet(address _wallet) returns (uint) {
        bool r = _wallet.call.gas(3000).value(0)(bytes4(sha3("isOwner(address)")),msg.sender);
        if(!r) {
            return _emitError(ERROR_WALLET_UNKNOWN);
        }
        if(store.includes(wallets,_wallet)) {
            return _emitError(ERROR_WALLET_EXISTS);
        }
        if(!isWalletOwner(_wallet,msg.sender)) {
            return _emitError(ERROR_WALLET_CANNOT_ADD_TO_REGISTRY);
        }

        store.add(wallets, _wallet);

        _emitWalletAdded(_wallet);

        return OK;
    }

    function removeWallet() returns (uint) {
        if(store.includes(wallets,msg.sender)) {
            store.remove(wallets,msg.sender);
            return OK;
        }
        return _emitError(ERROR_WALLET_UNKNOWN);
    }

    function createWallet(address[] _owners, uint _required, bytes32 _name) returns (uint errorCode) {
        address _wallet = new Wallet(_owners,_required, contractsManager, _name);
        store.add(wallets, _wallet);
        _emitWalletCreated(_wallet);
        return OK;
    }

    function _emitError(uint error) internal returns (uint) {
        WalletsManager(getEventsHistory()).emitError(error);
        return error;
    }

    function _emitWalletAdded(address wallet) internal {
        WalletsManager(getEventsHistory()).emitWalletAdded(wallet);
    }

    function _emitWalletCreated(address wallet) internal {
        WalletsManager(getEventsHistory()).emitWalletCreated(wallet);
    }

    function()
    {
        throw;
    }
}
