pragma solidity ^0.4.11;

import "./Managed.sol";
import "./Wallet.sol";
import "./WalletsManagerEmitter.sol";

contract WalletsManager is Managed,WalletsManagerEmitter {

    uint constant ERROR_WALLET_INVALID_INVOCATION = 14000;
    uint constant ERROR_WALLET_EXISTS = 14001;
    uint constant ERROR_WALLET_OWNER_ONLY = 14002;
    uint constant ERROR_WALLET_CANNOT_ADD_TO_REGISTRY = 14003;
    uint constant ERROR_WALLET_UNKNOWN = 14004;

    event Err(bool error);

StorageInterface.OrderedAddressesSet wallets;

    function isWalletOwner(address _wallet, address _owner) internal returns (bool) {
        return Wallet(_wallet).isOwner(_owner);
    }

    function WalletsManager(Storage _store, bytes32 _crate) StorageAdapter(_store, _crate) {
        wallets.init('wallets');
    }

    function init(address _contractsManager) returns (uint) {
        if (store.get(contractsManager) != 0x0) {
            return ERROR_WALLET_INVALID_INVOCATION;
        }

        uint e = ContractsManagerInterface(_contractsManager).addContract(this, bytes32("WalletsManager"));
        if (OK != e) {
            return e;
        }

        store.set(contractsManager, _contractsManager);
        return OK;
    }

    function kill(address[] tokens) onlyAuthorized returns (uint) {
        withdrawnTokens(tokens);
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

    function setupEventsHistory(address _eventsHistory) onlyAuthorized returns (uint) {
        if (getEventsHistory() != 0x0) {
            return ERROR_WALLET_INVALID_INVOCATION;
        }

        _setEventsHistory(_eventsHistory);
        return OK;
    }

    function addWallet(address _wallet) returns (uint) {
        bool r = _wallet.call.gas(3000).value(0)(bytes4(sha3("isOwner(address)")),msg.sender);
        Err(r);
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

    function createWallet(address[] _owners, uint _required) returns (uint errorCode) {
        address _wallet = new Wallet(_owners,_required,store.get(contractsManager));
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
