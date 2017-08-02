pragma solidity ^0.4.11;

import "../common/Object.sol";
import "../storage/StorageAdapter.sol";
import "../common/OwnedInterface.sol";
import "./ContractsManagerInterface.sol";

/**
*  @title ContractsManager
*/
contract ContractsManager is Object, StorageAdapter, ContractsManagerInterface {
    uint constant ERROR_CONTRACT_EXISTS = 10000;
    uint constant ERROR_CONTRACT_NOT_EXISTS = 10001;

    StorageInterface.AddressesSet contractsAddresses;
    StorageInterface.Bytes32AddressMapping contractsTypes;

    event LogAddContract(address indexed contractAddress, bytes32 t);
    event LogContractAddressChange(address indexed contractAddress, bytes32 t);
    event Error(address indexed self, uint errorCode);

    /**
    *  @notice Constructor that sets `storage` and `crate` to given values.
    */
    function ContractsManager(Storage _store, bytes32 _crate) StorageAdapter(_store, _crate) {
        contractsAddresses.init('contracts');
        contractsTypes.init('contractTypes');
    }

    /**
    *   @dev Returns an array containing all contracts addresses.
    *   @return Array of token addresses.
    */
    function getContractAddresses() constant returns (address[]) {
        return store.get(contractsAddresses);
    }

    /**
    *   @dev Returns a contracts address by given type.
    *   @return contractAddress
    */
    function getContractAddressByType(bytes32 _type) constant returns (address contractAddress) {
        return store.get(contractsTypes, _type);
    }

    /**
    *  @dev Allow owner to add new contract
    *
    *  @param _contract contacts address
    *  @param _type contracts type
    *
    *  @return result code, 1 if success, otherwise error code
    */
    function addContract(address _contract, bytes32 _type) onlyAllowed() returns (uint) {
        if (isExists(_contract)) {
            return emitError(ERROR_CONTRACT_EXISTS);
        }

        if (store.get(contractsTypes, _type) == 0x0) {
            store.add(contractsAddresses, _contract);
        } else {
            store.set(contractsAddresses, store.get(contractsTypes, _type), _contract);
        }

        store.set(contractsTypes, _type, _contract);

        LogAddContract(_contract, _type);
        return OK;
    }

    /**
    *  @dev Allow owner to add new contract
    *
    *  @param _contract contacts address
    *
    *  @return result code, 1 if success, otherwise error code
    */
    function removeContract(address _contract) onlyAllowed() returns (uint) {
        if (!isExists(_contract)) {
            return emitError(ERROR_CONTRACT_NOT_EXISTS);
        }

        store.remove(contractsAddresses, _contract);
        //store.set(contractsTypes, _type, 0x0); TODO: ahiatsevich: remove type

        return OK;
    }

    /**
    *  @dev Tells whether a contract wit a given address exists.
    *
    *  @return `true` if a contract has been registers, otherwise `false`
    */
    function isExists(address _contract) constant returns (bool) {
        return store.includes(contractsAddresses, _contract);
    }

    /**
    *  @dev Util function which throws error event with a given error
    */
    function emitError(uint e) private returns (uint)  {
        Error(msg.sender, e);
        return e;
    }

    /**
    *  @return true if `caller` is  a contact owner or authorized to make changes in Storage
    */
    modifier onlyAllowed() {
        if (contractOwner == msg.sender ||
                store.store.manager().hasAccess(msg.sender)) {
            _;
        }
    }

    /**
    *  Default fallback function.
    */
    function() {
        throw;
    }
}
