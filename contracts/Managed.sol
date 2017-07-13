pragma solidity ^0.4.8;

import {PendingManagerInterface as Shareable} from "./PendingManagerInterface.sol";
import "./UserManagerInterface.sol";
import "./ContractsManagerInterface.sol";
import "./StorageAdapter.sol";

contract Managed is StorageAdapter {

    StorageInterface.Address contractsManager;

    uint constant OK = 1;
    uint constant MULTISIG_ADDED = 3;

    function Managed() {
        contractsManager.init('contractsManager');
    }

    function getContractsManager() constant returns(address) {
        return store.get(contractsManager);
    }

    modifier onlyAuthorized() {
        if (isAuthorized(msg.sender)) {
            _;
        }
    }

    modifier onlyAuthorizedContract(address key) {
        address shareable = ContractsManagerInterface(store.get(contractsManager)).getContractAddressByType(bytes32("PendingManager"));
        if (msg.sender == shareable || isAuthorized(key)) {
            _;
        }
    }

    function multisig() internal returns (uint errorCode) {
        address shareable = ContractsManagerInterface(store.get(contractsManager)).getContractAddressByType(bytes32("PendingManager"));
        if (msg.sender != shareable) {
            bytes32 _r = sha3(msg.data);
            errorCode = Shareable(shareable).addTx(_r, msg.data, this, msg.sender);

            return (errorCode == OK) ? MULTISIG_ADDED : errorCode;
        }

        return OK;
    }

    function isAuthorized(address key) constant returns (bool) {
        address userManager = ContractsManagerInterface(store.get(contractsManager)).getContractAddressByType(bytes32("UserManager"));
        return UserManagerInterface(userManager).getCBE(key);
    }
}
