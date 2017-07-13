pragma solidity ^0.4.11;

import "../ContractsManagerInterface.sol";
import "../AssetsManager.sol";

/**
*  @title AssetDonator
*
*  @notice Created only for test purposes! Do not allow to deploy this contract
*  in production network.
*
*/
contract AssetDonator {
    address contractManager;
    mapping (address => bool) timeDonations;

    function init(address _contractManager) {
        if (_contractManager == 0x0) {
            throw;
        }

        contractManager = _contractManager;
    }

    /**
    *  @notice Sends 1000 TIME to caller.
    *  @notice It is permitted to send TIMEs only once.
    *
    *  @return success or not
    */
    function sendTime() returns (bool) {
        if (timeDonations[msg.sender]) {
           return false;
        }

        address assetManager = ContractsManagerInterface(contractManager)
              .getContractAddressByType(bytes32("AssetsManager"));

        if (!AssetsManager(assetManager).sendAsset(bytes32("TIME"), msg.sender, 1000000000)) {
            return false;
        }

        timeDonations[msg.sender] = true;
        return true;
    }
}
