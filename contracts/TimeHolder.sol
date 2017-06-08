pragma solidity ^0.4.8;

import "./Owned.sol";
import "./ListenerInterface.sol";
import "./ContractsManagerInterface.sol";
import {ERC20Interface as Asset} from "./ERC20Interface.sol";

contract TimeHolder is Owned {

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

    // User deposited into current period.
    event Deposit(address indexed who, uint indexed amount);
    // Shares withdrawn by a shareholder.
    event WithdrawShares(address indexed who, uint amount);
    // Something went wrong.
    event Error(bytes32 message);

    /**
     * Init TimeHolder contract.
     *
     *
     * @param _contractsManager address.
     * @param _sharesContract ERC20 token address to act as shares.
     *
     * @return success.
     */

    function init(address _contractsManager, Asset _sharesContract) returns(bool) {
        if(contractsManager != 0x0)
            return false;
        if(!ContractsManagerInterface(_contractsManager).addContract(this,ContractsManagerInterface.ContractType.TimeHolder))
            return false;
        contractsManager = _contractsManager;
        sharesContract = _sharesContract;
        return true;
    }

    function addListener(address _listener) onlyContractOwner returns(bool) {
        if(listenerIndex[_listener] == uint(0x0)) {
            ListenerInterface(_listener).deposit(this,0,0);
            ListenerInterface(_listener).withdrawn(this,0,0);
            listeners[listenersCount] = _listener;
            listenerIndex[_listener] = listenersCount;
            listenersCount++;
            return true;
        }
        return false;
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
    function deposit(uint _amount) returns(bool) {
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
    function depositFor(address _address, uint _amount) returns(bool) {
        if (_amount != 0 && !sharesContract.transferFrom(msg.sender, this, _amount)) {
            Error("Shares transfer failed");
            return false;
        }
        if(shareholdersId[_address] == 0) {
            shareholders[shareholdersCount] = _address;
            shareholdersId[_address] = shareholdersCount++;
        }
        shares[_address] += _amount;
        totalShares += _amount;

        for(uint i = 1; i < listenersCount; i++) {
            ListenerInterface(listeners[i]).deposit(_address, _amount, shares[_address]);
        }

        Deposit(_address, _amount);
        return true;
    }

    /**
    * Withdraw shares from the contract, updating the possesion proof in active period.
    *
    * @param _amount amount of shares to withdraw.
    *
    * @return success.
    */
    function withdrawShares(uint _amount) returns(bool) {
        // Provide latest possesion proof.
        //deposit(0);
        if (_amount > shares[msg.sender]) {
            Error("Insufficient balance");
            return false;
        }

        shares[msg.sender] -= _amount;
        totalShares -= _amount;

        for(uint i = 1; i < listenersCount; i++) {
            ListenerInterface(listeners[i]).withdrawn(msg.sender, _amount, shares[msg.sender]);
        }

        if (!sharesContract.transfer(msg.sender, _amount)) {
            throw;
        }

        WithdrawShares(msg.sender, _amount);
        return true;
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

    function totalSupply() constant returns(uint) {
        return sharesContract.totalSupply();
    }

    function()
    {
        throw;
    }
}
