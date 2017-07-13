pragma solidity ^0.4.8;

import "./TimeHolderEmmiter.sol";
import "./Owned.sol";
import "./ListenerInterface.sol";
import "./ContractsManagerInterface.sol";
import {ERC20Interface as Asset} from "./ERC20Interface.sol";

contract TimeHolder is Owned, TimeHolderEmmiter {

    uint constant ERROR_TIMEHOLDER_ALREADY_ADDED = 12000;
    uint constant ERROR_TIMEHOLDER_INVALID_INVOCATION = 12001;
    uint constant ERROR_TIMEHOLDER_INVALID_STATE = 12002;
    uint constant ERROR_TIMEHOLDER_TRANSFER_FAILED = 12003;
    uint constant ERROR_TIMEHOLDER_WITHDRAWN_FAILED = 12004;
    uint constant ERROR_TIMEHOLDER_DEPOSIT_FAILED = 12005;
    uint constant ERROR_TIMEHOLDER_INSUFFICIENT_BALANCE = 12006;

    mapping(address => uint) public shares;
    mapping(uint => address)  public shareholders;
    mapping(address => uint)  public shareholdersId;
    uint public shareholdersCount = 1;

    mapping(address => uint) listenerIndex;
    mapping(uint => address) public listeners;
    uint public listenersCount = 1;
    uint public totalShares;

    // ERC20 token that acts as shares.
    Asset public sharesContract;

    address public contractsManager;

    /**
     * Init TimeHolder contract.
     *
     *
     * @param _contractsManager address.
     * @param _sharesContract ERC20 token address to act as shares.
     *
     * @return success.
     */
    function init(address _contractsManager, Asset _sharesContract) returns (uint) {
        if(contractsManager != 0x0) {
            return ERROR_TIMEHOLDER_INVALID_INVOCATION;
        }

        uint e = ContractsManagerInterface(_contractsManager).addContract(this,bytes32("TimeHolder"));
        if(OK != e) {
            return e;
        }

        contractsManager = _contractsManager;
        sharesContract = _sharesContract;

        return OK;
    }
/*
    function setupEventsHistory(address _eventsHistory) onlyContractOwner returns (uint) {
        if (getEventsHistory() != 0x0) {
            return ERROR_TIMEHOLDER_INVALID_INVOCATION;
        }

        _setEventsHistory(_eventsHistory);
        return OK;
    }*/

    function addListener(address _listener) onlyContractOwner returns (uint) {
        if(listenerIndex[_listener] != uint(0x0)) {
            return _emitError(ERROR_TIMEHOLDER_INVALID_INVOCATION);
        }

        ListenerInterface(_listener).deposit(this,0,0);
        ListenerInterface(_listener).withdrawn(this,0,0);
        listeners[listenersCount] = _listener;
        listenerIndex[_listener] = listenersCount;
        listenersCount++;

        _emitListenerAdded(_listener);
        return OK;
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
        if (_amount != 0 && !sharesContract.transferFrom(msg.sender, this, _amount)) {
            return _emitError(ERROR_TIMEHOLDER_TRANSFER_FAILED);
        }

        if(shareholdersId[_address] == 0) {
            shareholders[shareholdersCount] = _address;
            shareholdersId[_address] = shareholdersCount++;
        }
        shares[_address] += _amount;
        totalShares += _amount;

        uint errorCode;
        for(uint i = 1; i < listenersCount; i++) {
            errorCode = ListenerInterface(listeners[i]).deposit(_address, _amount, shares[_address]);
            if (OK != errorCode) {
                _emitError(ERROR_TIMEHOLDER_DEPOSIT_FAILED);
            }
        }

        _emitDeposit(_address, _amount);
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
        // Provide latest possesion proof.
        //deposit(0);
        if (_amount > shares[msg.sender]) {
            return _emitError(ERROR_TIMEHOLDER_INSUFFICIENT_BALANCE);
        }

        shares[msg.sender] -= _amount;
        totalShares -= _amount;

        uint errorCode;
        for(uint i = 1; i < listenersCount; i++) {
            errorCode = ListenerInterface(listeners[i]).withdrawn(msg.sender, _amount, shares[msg.sender]);
            if (OK != errorCode) {
                _emitError(ERROR_TIMEHOLDER_WITHDRAWN_FAILED);
            }
        }

        if (!sharesContract.transfer(msg.sender, _amount)) {
            throw;
        }

        _emitWithdrawShares(msg.sender, _amount);
        return OK;
    }

    /**
     * Returns shares amount deposited by a particular shareholder.
     *
     * @param _address shareholder address.
     *
     * @return shares amount.
     */
    function depositBalance(address _address) constant returns(uint) {
        return shares[_address];
    }

    function totalSupply() constant returns (uint) {
        return sharesContract.totalSupply();
    }

    function _emitDeposit(address who, uint amount) private {
        //TimeHolder(getEventsHistory()).emitDeposit(who, amount);
        emitDeposit(who, amount);
    }

    function _emitWithdrawShares(address who, uint amount) private {
        //TimeHolder(getEventsHistory()).emitWithdrawShares(who, amount);
        emitWithdrawShares(who, amount);
    }

    function _emitListenerAdded(address listener) private {
        //TimeHolder(getEventsHistory()).emitListenerAdded(listener);
        emitListenerAdded(listener);
    }

    function _emitError(uint e) private returns (uint) {
        //TimeHolder(getEventsHistory()).emitError(e);
        emitError(e);
        return e;
    }

    function() {
        throw;
    }
}
