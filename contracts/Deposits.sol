pragma solidity ^0.4.11;

import "./Managed.sol";

contract Deposits is Managed {

    StorageInterface.OrderedAddressesSet shareholders;
    StorageInterface.UIntOrderedSetMapping deposits;
    StorageInterface.UInt depositsIdCounter;
    StorageInterface.AddressUIntUIntMapping amounts;
    StorageInterface.AddressUIntUIntMapping timestamps;
    StorageInterface.UInt totalSharesStorage;
    StorageInterface.Address sharesContractStorage;

    function _init() internal {
        shareholders.init('shareholders');
        deposits.init('deposits');
        depositsIdCounter.init('depositsIdCounter');
        amounts.init('amounts');
        timestamps.init('timestamps');
        totalSharesStorage.init('totalSharesStorage');
        sharesContractStorage.init('sharesContractStorage');
    }

    /**
     * Returns shares amount deposited by a particular shareholder.
     *
     * @param _address shareholder address.
     *
     * @return shares amount.
     */
    function depositBalance(address _address) constant returns(uint) {
        uint balance;
        StorageInterface.Iterator memory iterator = store.listIterator(deposits,bytes32(_address));
        for(uint i = 0; store.canGetNextWithIterator(deposits,iterator); i++) {
            uint _cur_amount = store.get(amounts,_address,store.getNextWithIterator(deposits,iterator));
            balance += _cur_amount;
        }
        return balance;
    }

}