pragma solidity ^0.4.11;

import "./TimeHolderEmmiter.sol";
import "../core/common/BaseManager.sol";
import "../core/common/ListenerInterface.sol";
import "../core/common/Deposits.sol";
import "../core/contracts/ContractsManagerInterface.sol";
import {ERC20Interface as Asset} from "../core/erc20/ERC20Interface.sol";


contract TimeHolder is Deposits, TimeHolderEmmiter {

    uint constant ERROR_TIMEHOLDER_ALREADY_ADDED = 12000;
    uint constant ERROR_TIMEHOLDER_INVALID_INVOCATION = 12001;
    uint constant ERROR_TIMEHOLDER_INVALID_STATE = 12002;
    uint constant ERROR_TIMEHOLDER_TRANSFER_FAILED = 12003;
    uint constant ERROR_TIMEHOLDER_WITHDRAWN_FAILED = 12004;
    uint constant ERROR_TIMEHOLDER_DEPOSIT_FAILED = 12005;
    uint constant ERROR_TIMEHOLDER_INSUFFICIENT_BALANCE = 12006;

    StorageInterface.OrderedAddressesSet listeners;

    function TimeHolder(Storage _store, bytes32 _crate) Deposits(_store, _crate) {
        listeners.init('listeners');
    }

    /**
     * Init TimeHolder contract.
     *
     *
     * @param _contractsManager address.
     * @param _sharesContract ERC20 token address to act as shares.
     *
     * @return success.
     */
    function init(address _contractsManager, address _sharesContract) onlyContractOwner returns (uint) {
        BaseManager.init(_contractsManager, "TimeHolder");

        store.set(sharesContractStorage,_sharesContract);

        return OK;
    }

    function destroy(address[] tokens) onlyAuthorized returns (uint) {
        withdrawnTokens(tokens, msg.sender);
        selfdestruct(msg.sender);
        return OK;
    }

    function addListener(address _listener) onlyAuthorized returns (uint) {
        //if(store.includes(listeners,_listener) || !_listener.call.gas(3000).value(0)(bytes4(sha3("deposit(address,uint256,uint256)")),this,0,0) || !_listener.call.gas(3000).value(0)(bytes4(sha3("withdrawn(address,uint256,uint256)")),this,0,0)) {
        //    return _emitError(ERROR_TIMEHOLDER_INVALID_INVOCATION);
        //}
        ListenerInterface(_listener).deposit(this,0,0);
        ListenerInterface(_listener).withdrawn(this,0,0);
        if(store.includes(listeners,_listener)) {
            return _emitError( ERROR_TIMEHOLDER_ALREADY_ADDED);
        }

        store.add(listeners,_listener);

        _emitListenerAdded(_listener);

        return OK;
    }

    /**
    * Total amount of shares
    *
    * @return total amount of shares
    */
    function totalShares() constant returns (uint) {
        return store.get(totalSharesStorage);
    }

    /**
    * Contract address of shares
    *
    * @return address of shares contract
    */
    function sharesContract() constant returns (address) {
        return store.get(sharesContractStorage);
    }

    /**
    * Number of shareholders
    *
    * @return number of shareholders
    */
    function shareholdersCount() constant returns (uint) {
        return store.count(shareholders);
    }

    /**
     * Deposit shares and prove possession.
     * Amount should be less than or equal to current allowance value.
     *
     * Proof should be repeated for each active period. To prove possesion without
     * depositing more shares, specify 0 amount.
     *
     * @param _amount amount of shares to deposit, or 0 to just prove.
     *
     * @return success.
     */
    function deposit(uint _amount) returns (uint) {
        return depositFor(msg.sender, _amount);
    }

    /**
     * Deposit own shares and prove possession for arbitrary shareholder.
     * Amount should be less than or equal to caller current allowance value.
     *
     * Proof should be repeated for each active period. To prove possesion without
     * depositing more shares, specify 0 amount.
     *
     * This function meant to be used by some backend application to prove shares possesion
     * of arbitrary shareholders.
     *
     * @param _address to deposit and prove for.
     * @param _amount amount of shares to deposit, or 0 to just prove.
     *
     * @return success.
     */
    function depositFor(address _address, uint _amount) returns (uint) {
        address asset = store.get(sharesContractStorage);
        if (_amount != 0 && !ERC20Interface(asset).transferFrom(msg.sender, this, _amount)) {
            return _emitError(ERROR_TIMEHOLDER_TRANSFER_FAILED);
        }

        if(!store.includes(shareholders,_address)) {
            store.add(shareholders,_address);
        }

        uint prevId = store.get(depositsIdCounter);
        uint id = prevId + 1;
        store.set(depositsIdCounter, id);
        store.add(deposits,bytes32(_address),id);
        store.set(amounts,_address,id,_amount);
        store.set(timestamps,_address,id,now);

        uint balance = depositBalance(_address);
        uint errorCode;
        StorageInterface.Iterator memory iterator = store.listIterator(listeners);
        for(uint i = 0; store.canGetNextWithIterator(listeners,iterator); i++) {
            address listener = store.getNextWithIterator(listeners,iterator);
            errorCode = ListenerInterface(listener).deposit(_address, _amount, balance);
            if (OK != errorCode) {
                _emitError(errorCode);
            }
        }

        _emitDeposit(_address, _amount);

        uint prevAmount = store.get(totalSharesStorage);
        _amount += prevAmount;
        store.set(totalSharesStorage,_amount);

        return OK;
    }

    /**
    * Withdraw shares from the contract, updating the possesion proof in active period.
    *
    * @param _amount amount of shares to withdraw.
    *
    * @return success.
    */
    function withdrawShares(uint _amount) returns (uint) {


        if (_amount > depositBalance(msg.sender)) {
            return _emitError(ERROR_TIMEHOLDER_INSUFFICIENT_BALANCE);
        }

        if (!ERC20Interface(store.get(sharesContractStorage)).transfer(msg.sender, _amount)) {
            return _emitError(ERROR_TIMEHOLDER_TRANSFER_FAILED);
        }

        uint _original_amount = _amount;

        uint i;

        StorageInterface.Iterator memory iterator;

        if(depositBalance(msg.sender) != 0) {
            iterator = store.listIterator(deposits,bytes32(msg.sender));
            uint deposits_count = iterator.count();
            if(deposits_count != 0) {
                for(i = 0; store.canGetNextWithIterator(deposits,iterator); i++) {
                    uint _id = store.getNextWithIterator(deposits,iterator);
                    uint _cur_amount = store.get(amounts,msg.sender,_id);
                    if(_amount < _cur_amount) {
                        store.set(amounts,msg.sender,_id,_cur_amount-_amount);
                        break;
                    }
                    if(_amount == _cur_amount) {
                        store.remove(deposits,bytes32(msg.sender),_id);
                        deposits_count--;
                        break;
                    }
                    if(_amount > _cur_amount) {
                        _amount -= _cur_amount;
                        store.remove(deposits,bytes32(msg.sender),_id);
                        deposits_count--;
                    }
                }
            }
            if(deposits_count == 0) {
                store.remove(shareholders,msg.sender);
            }
        }

        uint errorCode;
        uint balance = depositBalance(msg.sender);

        iterator = store.listIterator(listeners);
        for(i = 0; store.canGetNextWithIterator(listeners,iterator); i++) {
            address listener = store.getNextWithIterator(listeners,iterator);
            errorCode = ListenerInterface(listener).withdrawn(msg.sender, _original_amount, balance);
            if (OK != errorCode) {
                _emitError(errorCode);
            }
        }

        _emitWithdrawShares(msg.sender, _original_amount);

        store.set(totalSharesStorage,store.get(totalSharesStorage)-_original_amount);

        return OK;
    }

    function totalSupply() constant returns (uint) {
        address asset = store.get(sharesContractStorage);
        return ERC20Interface(asset).totalSupply();
    }

    function _emitDeposit(address who, uint amount) private {
        TimeHolder(getEventsHistory()).emitDeposit(who, amount);
    }

    function _emitWithdrawShares(address who, uint amount) private {
        TimeHolder(getEventsHistory()).emitWithdrawShares(who, amount);
    }

    function _emitListenerAdded(address listener) private {
        TimeHolder(getEventsHistory()).emitListenerAdded(listener);
    }

    function _emitError(uint e) private returns (uint) {
        TimeHolder(getEventsHistory()).emitError(e);
        return e;
    }

    function() {
        throw;
    }
}
