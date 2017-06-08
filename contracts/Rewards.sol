pragma solidity ^0.4.11;

import {TimeHolderInterface as TimeHolder} from "./TimeHolderInterface.sol";
import {ERC20Interface as Asset} from "./ERC20Interface.sol";
import "./AssetsManagerInterface.sol";
import "./Managed.sol";
import "./RewardsEmitter.sol";

/**
 * @title Universal decentralized ERC20 tokens rewards contract.
 *
 * One ERC20 token serves as a shares, and any number of other ERC20 tokens serve as rewards(assets).
 * Rewards distribution are divided in periods, the only thing that shareholder needs to do in
 * order to take part in distribution is prove to rewards contract that he possess certain amount
 * of shares before period closes. Prove is made through allowing rewards contract to take shares
 * from the shareholder, and then depositing it through a call to rewards contract. Proof is needed
 * for every period.
 *
 * When calculating rewards distribution, resulting amount is always rounded down.
 *
 * In order to be able to deposit shares, user needs to create allowance for this contract, using
 * standard ERC20 approve() function, so that contract can take shares from the user, when user
 * makes a dpeosit.
 *
 * Users can withdraw their shares at any moment, but only remaining shares will be used for
 * rewards distribution.
 * Users can withdraw their accumulated rewards at any moment.
 *
 * State flow:
 *   1. Period closed, next period started;
 *   2. Reward assets registered for last closed preiod;
 *   3. Rewards distributed for closed period;
 *   4. Shares deposited into current period;
 *   5. Repeat.
 *
 * Note: all the non constant functions return false instead of throwing in case if state change
 * didn't happen yet.
 */
contract Rewards is Managed, RewardsEmitter {

    StorageInterface.UInt closeInterval;
    StorageInterface.UInt maxSharesTransfer;
    StorageInterface.AddressAddressUIntMapping rewards;
    StorageInterface.AddressUIntMapping rewardsLeft;
    StorageInterface.UInt periods;
    StorageInterface.UIntBoolMapping closed;
    StorageInterface.UIntUIntMapping startDate;
    StorageInterface.UIntUIntMapping totalShares;
    StorageInterface.UIntUIntMapping shareholdersCount;
    StorageInterface.UIntUIntAddressMapping shareholders;
    StorageInterface.UIntAddressUIntMapping shares;
    StorageInterface.UIntAddressUIntMapping shareholdersId;
    StorageInterface.UIntAddressUIntMapping assetBalances;
    StorageInterface.UIntAddressAddressBoolMapping calculated;

    function Rewards(Storage _store, bytes32 _crate) StorageAdapter(_store, _crate) {
        closeInterval.init('closeInterval');
        maxSharesTransfer.init('maxSharesTransfer');
        rewards.init('rewards');
        rewardsLeft.init('rewardsLeft');
        periods.init('periods');
        closed.init('closed');
        startDate.init('startDate');
        totalShares.init('totalShares');
        shareholdersCount.init('shareholdersCount');
        shareholders.init('shareholders');
        shares.init('shares');
        shareholdersId.init('shareholdersId');
        assetBalances.init('assetBalances');
        calculated.init('calculated');
    }

    /**
     * Sets ContractManager contract and period minimum length.
     * Starts the first period.
     *
     * Can be set only once.
     *
     * @param _contractsManager contracts Manager contract address.
     * @param _closeIntervalDays period minimum length, in days.
     *
     * @return success.
     */

    function init(address _contractsManager, uint _closeIntervalDays) returns(bool) {
        if (store.get(periods) > 0) {
            return false;
        }
        if(store.get(contractsManager) != 0x0)
            return false;
        if(!ContractsManagerInterface(_contractsManager).addContract(this,ContractsManagerInterface.ContractType.Rewards))
            return false;
        store.set(periods,store.get(periods)+1);
        store.set(contractsManager,_contractsManager);
        store.set(closeInterval,_closeIntervalDays);
        store.set(shareholdersCount,0,1);
        store.set(startDate,0,now);
        store.set(maxSharesTransfer,30);
        return true;
    }

    function setupEventsHistory(address _eventsHistory) onlyAuthorized returns(bool) {
        if (getEventsHistory() != 0x0) {
            return false;
        }
        _setEventsHistory(_eventsHistory);
        return true;
    }

    function getCloseInterval() constant returns(uint) {
        return store.get(closeInterval);
    }

    function setCloseInterval(uint _closeInterval) onlyAuthorized returns(bool) {
        store.set(closeInterval,_closeInterval);
        return true;
    }

    function getMaxSharesTransfer() constant returns(uint) {
        return store.get(maxSharesTransfer);
    }

    function setMaxSharesTransfer(uint _maxSharesTransfer) onlyAuthorized returns(bool) {
        store.set(maxSharesTransfer,_maxSharesTransfer);
        return true;
    }

    function getRewardsLeft(address shareholder) constant returns(uint) {
        return store.get(rewardsLeft,shareholder);
    }

    function periodsLength() constant returns(uint) {
        return store.get(periods);
    }

    function periodUnique(uint _period) constant returns(uint) {
        if(_period == lastPeriod()) {
            address timeHolder = ContractsManagerInterface(store.get(contractsManager)).getContractAddressByType(ContractsManagerInterface.ContractType.TimeHolder);
            return TimeHolder(timeHolder).shareholdersCount() - 1;
        }
        else
            return store.get(shareholdersCount,_period) - 1;
    }

    modifier onlyTimeHolder() {
        address timeHolder = ContractsManagerInterface(store.get(contractsManager)).getContractAddressByType(ContractsManagerInterface.ContractType.TimeHolder);
        if (msg.sender == timeHolder) {
            _;
        }
    }

    function getAssets() constant returns(address[] result) {
        address assetsManager = ContractsManagerInterface(store.get(contractsManager)).getContractAddressByType(ContractsManagerInterface.ContractType.AssetsManager);
        address chronoMint = ContractsManagerInterface(store.get(contractsManager)).getContractAddressByType(ContractsManagerInterface.ContractType.LOCManager);
        uint counter;
        uint i;
        uint assetsCount = AssetsManagerInterface(assetsManager).getAssetsCount();
        for(i=0;i<assetsCount;i++) {
            if(AssetsManagerInterface(assetsManager).isAssetOwner(AssetsManagerInterface(assetsManager).getSymbolById(i),chronoMint))
            counter++;
        }
        result = new address[](counter);
        counter = 0;
        for(i=0;i<assetsCount;i++) {
            if(AssetsManagerInterface(assetsManager).isAssetOwner(AssetsManagerInterface(assetsManager).getSymbolById(i),chronoMint)) {
                bytes32 symbol = AssetsManagerInterface(assetsManager).getSymbolById(i);
                result[counter] = AssetsManagerInterface(assetsManager).getAssetBySymbol(symbol);
                counter++;
            }
        }
        return result;
    }
    /**
     * Close current active period and start the new period.
     *
     * Can only be done if period was active longer than minimum length.
     *
     * @return success.
     */
    function closePeriod() returns(bool) {

        uint period = lastPeriod();
        if ((store.get(startDate,period) + (store.get(closeInterval) * 1 days)) > now) {
            _emitError("Cannot close period yet");
            return false;
        }
        address timeHolder = ContractsManagerInterface(store.get(contractsManager)).getContractAddressByType(ContractsManagerInterface.ContractType.TimeHolder);
        // Add new period.
        store.set(periods,store.get(periods)+1);
        store.set(startDate,lastPeriod(),now);
        store.set(shareholdersCount,lastClosedPeriod(),TimeHolder(timeHolder).shareholdersCount());
        address[] memory assets = getAssets();
        if(assets.length != 0) {
            for(uint i = 0;i<assets.length;i++) {
                registerAsset(Asset(assets[i]));
            }
        }

        return storeDeposits(0);
    }

    function getPartsCount() constant returns(uint) {
        uint period = lastClosedPeriod();
        uint _shareholdersCount = store.get(shareholdersCount,period);
        uint _maxSharesTransfer = store.get(maxSharesTransfer);
        if(!store.get(closed,period) && _shareholdersCount > _maxSharesTransfer) {
            if(_shareholdersCount % _maxSharesTransfer == 0)
                return _shareholdersCount / _maxSharesTransfer;
            else
                return _shareholdersCount / _maxSharesTransfer + 1;
        }
        return 0;
    }

    function storeDeposits(uint _part) returns(bool) {
        uint period = lastClosedPeriod();
        uint _maxSharesTransfer = store.get(maxSharesTransfer);
        uint _shareholdersCount = store.get(shareholdersCount,period);
        uint first = _part * _maxSharesTransfer + 1;
        if(first > _shareholdersCount)
            throw;
        uint last = first + _maxSharesTransfer;
        if(last >= _shareholdersCount)
            last = _shareholdersCount;
        address holder;
        address timeHolder = ContractsManagerInterface(store.get(contractsManager)).getContractAddressByType(ContractsManagerInterface.ContractType.TimeHolder);
        for(;first < last;first++) {
            holder = TimeHolder(timeHolder).shareholders(first);
            if(store.get(shares,period,holder) == 0) {
                uint holderShares = TimeHolder(timeHolder).shares(holder);
                store.set(shares,period,holder,holderShares);
                store.set(totalShares,period,store.get(totalShares,period)+holderShares);
            }
        }
        first = _part * _maxSharesTransfer + 1;
        address[] memory assets = getAssets();
        for(;first < last;first++) {
            holder = TimeHolder(timeHolder).shareholders(first);
            for(uint i = 0;i<assets.length;i++) {
                calculateRewardFor(Asset(assets[i]),holder);
            }
        }
        if(store.get(totalShares,period) == TimeHolder(timeHolder).totalShares()) {
            store.set(closed,period,true);
            //eventsHistory.periodClosed(lastClosedPeriod());

            return true;
        }
        return false;
    }

    function registerAsset(Asset _asset) returns(bool) {
        address timeHolder = ContractsManagerInterface(store.get(contractsManager)).getContractAddressByType(ContractsManagerInterface.ContractType.TimeHolder);
        if (TimeHolder(timeHolder).sharesContract() == _asset) {
            _emitError("Asset is already registered");
            return false;
        }
        uint period = lastClosedPeriod();
        if (store.get(assetBalances,period,_asset) != 0) {
            _emitError("Asset is already registered");
            return false;
        }

        store.set(assetBalances,period,_asset,_asset.balanceOf(this) - store.get(rewardsLeft,_asset));
        store.set(rewardsLeft,_asset,store.get(rewardsLeft,_asset) + store.get(assetBalances,period,_asset));

        //eventsHistory.assetRegistration(_asset, period.assetBalances[_asset]);
        return true;
    }

    function deposit(address _address, uint _amount, uint _total) onlyTimeHolder returns(bool) {
        if (store.get(periods) == 1) {
            return false;
        }
        uint period = lastClosedPeriod();
        if(!store.get(closed,period)) {
            store.set(totalShares,period,store.get(totalShares,period) + _amount);
            if(store.get(shareholdersId,period,_address) > 0) {
                store.set(shares,period,_address,_total);
            }
            return true;
        }
        return false;
    }

    /**
     * Calculate and distribute reward of a specified registered rewards asset.
     *
     * Distribution is made for caller and last closed period.
     *
     * Can only be done once per asset per closed period.
     *
     * @param _assetAddress registered rewards asset contract address.
     *
     * @return success.
     */

    function calculateReward(address _assetAddress) internal returns(bool) {
        return calculateRewardForAddressAndPeriod(_assetAddress, msg.sender, lastClosedPeriod());
    }


    /**
     * Calculate and distribute reward of a specified registered rewards asset.
     *
     * Distribution is made for specified shareholder and last closed period.
     *
     * Can only be done once per asset per shareholder per closed period.
     *
     * This function meant to be used by some backend application to calculate rewards
     * for arbitrary shareholders.
     *
     * @param _assetAddress registered rewards asset contract address.
     * @param _address shareholder address.
     *
     * @return success.
     */

    function calculateRewardFor(address _assetAddress, address _address) internal returns(bool) {
        return calculateRewardForAddressAndPeriod(_assetAddress, _address, lastClosedPeriod());
    }

    /**
     * Calculate and distribute reward of a specified registered rewards asset.
     *
     * Distribution is made for caller and specified closed period.
     *
     * Can only be done once per asset per closed period.
     *
     * @param _assetAddress registered rewards asset contract address.
     * @param _period closed period to calculate.
     *
     * @return success.
     */

    function calculateRewardForPeriod(address _assetAddress, uint _period) internal returns(bool) {
        return calculateRewardForAddressAndPeriod(_assetAddress, msg.sender, _period);
    }


    /**
     * Calculate and distribute reward of a specified registered rewards asset.
     *
     * Distribution is made for specified shareholder and closed period.
     *
     * Can only be done once per asset per shareholder per closed period.
     *
     * @param _assetAddress registered rewards asset contract address.
     * @param _address shareholder address.
     * @param _period closed period to calculate.
     *
     * @return success.
     */
    function calculateRewardForAddressAndPeriod(address _assetAddress, address _address, uint _period) internal returns(bool) {
        //if(period.isClosed) {
        if (store.get(assetBalances,_period,_assetAddress) == 0) {
            _emitError("Reward calculation failed");
            return false;
        }

        if (store.get(calculated,_period,_assetAddress,_address)) {
            _emitError("Reward is already calculated");
            return false;
        }

        uint reward = store.get(assetBalances,_period,_assetAddress) * store.get(shares,_period,_address) / store.get(totalShares,_period);
        store.set(rewards,_assetAddress,_address,store.get(rewards,_assetAddress,_address) + reward);
        store.set(calculated,_period,_assetAddress,_address,true);


        //eventsHistory.calculateReward(_assetAddress, _address, reward);
        return true;
        //}
        //return false;
    }

    /**
     * Withdraw accumulated reward of a specified rewards asset.
     *
     * Withdrawal is made for caller and total amount.
     *
     * @param _asset registered rewards asset contract address.
     *
     * @return success.
     */
    function withdrawRewardTotal(Asset _asset) returns(bool) {
        return withdrawRewardFor(_asset, msg.sender, rewardsFor(_asset, msg.sender));
    }

    /**
     * Withdraw accumulated reward of a specified rewards asset.
     *
     * Withdrawal is made for specified shareholder and total amount.
     *
     * This function meant to be used by some backend application to send rewards
     * for arbitrary shareholders.
     *
     * @param _asset registered rewards asset contract address.
     * @param _address shareholder address to withdraw for.
     *
     * @return success.
     */
    function withdrawRewardTotalFor(Asset _asset, address _address) returns(bool) {
        return withdrawRewardFor(_asset, _address, rewardsFor(_asset, _address));
    }

    /**
     * Withdraw accumulated reward of a specified rewards asset.
     *
     * Withdrawal is made for caller and specified amount.
     *
     * @param _asset registered rewards asset contract address.
     * @param _amount amount to withdraw.
     *
     * @return success.
     */
    function withdrawReward(Asset _asset, uint _amount) returns(bool) {
        return withdrawRewardFor(_asset, msg.sender, _amount);
    }

    /**
     * Withdraw accumulated reward of a specified rewards asset.
     *
     * Withdrawal is made for specified shareholder and specified amount.
     *
     * @param _asset registered rewards asset contract address.
     * @param _address shareholder address to withdraw for.
     * @param _amount amount to withdraw.
     *
     * @return success.
     */
    function withdrawRewardFor(Asset _asset, address _address, uint _amount) returns(bool) {
        if (store.get(rewardsLeft,_asset) == 0) {
            _emitError("No rewards left");
            return false;
        }

        // Assuming that transfer(amount) of unknown asset may not result in exactly
        // amount being taken from rewards contract(i. e. fees taken) we check contracts
        // balance before and after transfer, and proceed with the difference.
        uint startBalance = _asset.balanceOf(this);
        if (!_asset.transfer(_address, _amount)) {
            _emitError("Asset transfer failed");
            return false;
        }

        uint endBalance = _asset.balanceOf(this);
        uint diff = startBalance - endBalance;
        if (rewardsFor(_asset, _address) < diff) {
            throw;
        }

        store.set(rewards,_asset,_address,store.get(rewards,_asset,_address) - diff);
        store.set(rewardsLeft,_asset, store.get(rewardsLeft,_asset) - diff);

        //eventsHistory.withdrawReward(_asset, _address, _amount);
        return true;
    }

    function withdrawn(address _address, uint _amount, uint _total) onlyTimeHolder returns(bool) {

        if (store.get(periods) == 1) {
            return false;
        }
        uint period = lastClosedPeriod();
        if(!store.get(closed,period)) {

            store.set(totalShares,period,store.get(totalShares,period) - _amount);
            if(store.get(shareholdersId,period,_address) > 0) {
                store.set(shares,period,_address,_total);
            }
            return true;
        }
        return false;
    }


    /**
     * Returns proven amount of shares possessed by a shareholder in a period.
     *
     * @param _address shareholder address.
     * @param _period period.
     *
     * @return shares amount.
     */
    function depositBalanceInPeriod(address _address, uint _period) constant returns(uint) {
        if(_period == lastPeriod()) {
            address timeHolder = ContractsManagerInterface(store.get(contractsManager)).getContractAddressByType(ContractsManagerInterface.ContractType.TimeHolder);
            return TimeHolder(timeHolder).shares(_address);
        }
        return store.get(shares,_period,_address);
    }

    /**
     * Returns total proven amount of shares possessed by shareholders in a period.
     *
     * @param _period period.
     *
     * @return shares amount.
     */
    function totalDepositInPeriod(uint _period) constant returns(uint) {
        if(_period == lastPeriod()) {
            address timeHolder = ContractsManagerInterface(store.get(contractsManager)).getContractAddressByType(ContractsManagerInterface.ContractType.TimeHolder);
            return TimeHolder(timeHolder).totalShares();
        }
        return store.get(totalShares,_period);
    }

    /**
     * Returns current active period.
     *
     * @return period.
     */
    function lastPeriod() constant returns(uint) {
        return store.get(periods) - 1;
    }

    /**
     * Returns last closed period.
     *
     * @dev throws in case if there is no closed periods yet.
     *
     * @return period.
     */
    function lastClosedPeriod() constant returns(uint) {
        if (store.get(periods) == 1) {
            throw;
        }
        return store.get(periods) - 2;
    }

    /**
     * Check if period is closed or not.
     *
     * @param _period period.
     *
     * @return period closing state.
     */
    function isClosed(uint _period) constant returns(bool) {
        return store.get(closed,_period);
    }

    /**
     * Returns amount of accumulated rewards assets in a period.
     * Always 0 for active period.
     *
     * @param _assetAddress rewards asset contract address.
     * @param _period period.
     *
     * @return assets amount.
     */
    function assetBalanceInPeriod(address _assetAddress, uint _period) constant returns(uint) {
        return store.get(assetBalances,_period,_assetAddress);
    }

    /**
     * Check if shareholder have calculated rewards in a period.
     *
     * @param _assetAddress rewards asset contract address.
     * @param _address shareholder address.
     * @param _period period.
     *
     * @return reward calculation state.
     */
    function isCalculatedFor(address _assetAddress, address _address, uint _period) constant returns(bool) {
        return store.get(calculated,_period,_assetAddress,_address);
    }

    /**
     * Returns accumulated asset rewards available for withdrawal for shareholder.
     *
     * @param _assetAddress rewards asset contract address.
     * @param _address shareholder address.
     *
     * @return rewards amount.
     */
    function rewardsFor(address _assetAddress, address _address) constant returns(uint) {
        return store.get(rewards,_assetAddress,_address);
    }

    function _emitError(bytes32 _error) {
        Rewards(getEventsHistory()).emitError(_error);
    }

    function()
    {
        throw;
    }
}
