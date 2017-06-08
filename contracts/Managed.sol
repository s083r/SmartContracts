pragma solidity ^0.4.8;

import {PendingManagerInterface as Shareable} from "./PendingManagerInterface.sol";
import "./UserManagerInterface.sol";
import "./ContractsManagerInterface.sol";
import './StorageAdapter.sol';

contract Managed is StorageAdapter {

    StorageInterface.Address contractsManager;

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

    modifier multisig() {
        address shareable = ContractsManagerInterface(store.get(contractsManager)).getContractAddressByType(ContractsManagerInterface.ContractType.PendingManager);
        if (msg.sender != shareable) {
            bytes32 _r = sha3(msg.data);
            Shareable(shareable).addTx(_r, msg.data, this, msg.sender);
        }
        else {
            _;
        }
    }

    function isAuthorized(address key) returns (bool) {
        address userManager = ContractsManagerInterface(store.get(contractsManager)).getContractAddressByType(ContractsManagerInterface.ContractType.UserManager);
        return UserManagerInterface(userManager).getCBE(key);
    }

}
