pragma solidity ^0.4.8;

import "./Owned.sol";
import {ERC20Interface as Asset} from "./ERC20Interface.sol";

contract ExchangeEmitter {
    function emitError(bytes32 _message);
}

/**
 * @title ERC20-Ether exchange contract.
 *
 * Users are able to buy/sell assigned ERC20 token for ether, as long as there is available
 * supply. Contract owner maintains sufficient token and ether supply, and sets buy/sell prices.
 *
 * In order to be able to sell tokens, user needs to create allowance for this contract, using
 * standard ERC20 approve() function, so that exchange can take tokens from the user, when user
 * orders a sell.
 *
 * Note: all the non constant functions return false instead of throwing in case if state change
 * didn't happen yet.
 */
contract Exchange is Owned {
    // Assigned ERC20 token.
    Asset public asset;

    address rewards;

    address delegate;

    //Switch for turn on and off the exchange operations
    bool public isActive;

    // Price in wei at which exchange buys tokens.
    uint public buyPrice = 1;

    // Price in wei at which exchange sells tokens.
    uint public sellPrice = 2;

    uint public minAmount;

    uint public maxAmount;

    // Fee value for operations 10000 is 0.01.
    uint public feePercent = 10000;

    // User sold tokens and received wei.
    event Sell(address indexed who, uint token, uint eth);

    // User bought tokens and payed wei.
    event Buy(address indexed who, uint token, uint eth);
    event WithdrawTokens(address indexed recipient, uint amount);
    event WithdrawEth(address indexed recipient, uint amount);
    event Error(bytes32 message);

    /**
     * @dev On received ethers
     * @param sender Ether sender
     * @param amount Ether value
     */
    event ReceivedEther(address indexed sender,
    uint256 indexed amount);


    // Should use interface of the emitter, but address of events history.
    ExchangeEmitter public eventsHistory;

    /**
     * Emits Error event with specified error message.
     *
     * Should only be used if no state changes happened.
     *
     * @param _message error message.
     */
    function _error(bytes32 _message) internal {
        eventsHistory.emitError(_message);
    }
    /**
     * Sets EventsHstory contract address.
     *
     * Can be set only once, and only by contract owner.
     *
     * @param _eventsHistory EventsHistory contract address.
     *
     * @return success.
     */
    function setupEventsHistory(address _eventsHistory) onlyContractOwner returns(bool) {
        if (address(eventsHistory) != 0) {
            return false;
        }
        eventsHistory = ExchangeEmitter(_eventsHistory);
        return true;
    }

    /**
     * Assigns ERC20 token for exchange.
     *
     * Can be set only once, and only by contract owner.
     *
     * @param _asset ERC20 token address.
     *
     * @return success.
     */
    function init(Asset _asset, address _rewards, address _delegate, uint _fee) onlyContractOwner() returns(bool) {
        if (address(asset) != 0x0) {
            return false;
        }
        if (rewards != 0x0) {
            return false;
        }
        asset = _asset;
        rewards = _rewards;
        delegate = _delegate;
        setFee(_fee);
        isActive = true;
        return true;
    }

    function setFee(uint _feePercent) internal returns(bool) {
        if(feePercent < 1 || feePercent > 10000) {
            return false;
        }
        feePercent = _feePercent;
        return true;
    }

    function setActive(bool _active) onlyContractOwner() returns(bool) {
        isActive = _active;
    }



    /**
     * Set exchange operation prices.
     * Sell price cannot be less than buy price.
     *
     * Can be set only by contract owner.
     *
     * @param _buyPrice price in wei at which exchange buys tokens.
     * @param _sellPrice price in wei at which exchange sells tokens.
     *
     * @return success.
     */
    function setPrices(uint _buyPrice, uint _sellPrice) onlyContractOwner() returns(bool) {
        if (_sellPrice < _buyPrice) {
            _error("Incorrect price");
            return false;
        }
        buyPrice = _buyPrice;
        sellPrice = _sellPrice;
        return true;
    }

    /**
     * Returns assigned token address balance.
     *
     * @param _address address to get balance.
     *
     * @return token balance.
     */
    function _balanceOf(address _address) constant internal returns(uint) {
        return asset.balanceOf(_address);
    }

    /**
     * Sell tokens for ether at specified price. Tokens are taken from caller
     * though an allowance logic.
     * Amount should be less than or equal to current allowance value.
     * Price should be less than or equal to current exchange buyPrice.
     *
     * @param _amount amount of tokens to sell.
     * @param _price price in wei at which sell will happen.
     *
     * @return success.
     */
    function sell(uint _amount, uint _price) returns(bool) {
        if(!isActive) {
            _error("Maintenance mode");
        }

        if (_price > buyPrice) {
            _error("Price is too high");
            return false;
        }
        if (_balanceOf(msg.sender) < _amount) {
            _error("Insufficient token balance");
            return false;
        }

        uint total = _mul(_amount, _price);
        if (this.balance < total) {
            _error("Insufficient ether supply");
            return false;
        }
        if (!asset.transferFrom(msg.sender, this, _amount)) {
            _error("Payment failed");
            return false;
        }
        if (!msg.sender.send(total)) {
            throw;
        }

        Sell(msg.sender, _amount, total);
        return true;
    }

    /**
     * Buy tokens for ether at specified price. Payment needs to be sent along
     * with the call, and should equal amount * price.
     * Price should be greater than or equal to current exchange sellPrice.
     *
     * @param _amount amount of tokens to buy.
     * @param _price price in wei at which buy will happen.
     *
     * @return success.
     */
    function buy(uint _amount, uint _price) payable returns(bool) {
        if(!isActive) {
            _error("Maintenance mode");
        }

        if (_price < sellPrice) {
            _error("Price is to low");
            throw;
        }
        if (_balanceOf(this) < _amount) {
            _error("Insufficient token balance");
            throw;
        }

        uint total = _mul(_amount, _price);
        if (msg.value != total) {
            _error("Insufficient ether supply");
            throw;
        }
        if (!asset.transfer(msg.sender, _amount)) {
            _error("Payment failed");
            throw;
        }

        Buy(msg.sender, _amount, total);
        return true;
    }

    /**
     * Transfer specified amount of tokens from exchange to specified address.
     *
     * Can be called only by contract owner.
     *
     * @param _recipient address to transfer tokens to.
     * @param _amount amount of tokens to transfer.
     *
     * @return success.
     */
    function withdrawTokens(address _recipient, uint _amount) onlyContractOwner() returns(bool) {
        if (_balanceOf(this) < _amount) {
            _error("Insufficient token supply");
            return false;
        }

        uint amount = (_amount * 10000)/(10000 + feePercent);

        if (!asset.transfer(_recipient, amount)) {
            _error("Transfer failed");
            return false;
        }

        WithdrawTokens(_recipient, amount);

        if(!asset.transfer(rewards, _amount - amount)) {
            _error("Fee transfer failed");
        }

        return true;
    }

    /**
     * Transfer all tokens from exchange to specified address.
     *
     * Can be called only by contract owner.
     *
     * @param _recipient address to transfer tokens to.
     *
     * @return success.
     */
    function withdrawAllTokens(address _recipient) onlyContractOwner() returns(bool) {
        return withdrawTokens(_recipient, _balanceOf(this));
    }

    /**
     * Transfer specified amount of wei from exchange to specified address.
     *
     * Can be called only by contract owner.
     *
     * @param _recipient address to transfer wei to.
     * @param _amount amount of wei to transfer.
     *
     * @return success.
     */
    function withdrawEth(address _recipient, uint _amount) onlyContractOwner() returns(bool) {
        if (this.balance < _amount) {
            _error("Insufficient ether supply");
            return false;
        }

        uint amount = (_amount * 10000)/(10000 + feePercent);

        if (!_recipient.send(amount)) {
            _error("Transfer failed");
            return false;
        }

        WithdrawEth(_recipient, amount);

        if(!rewards.send(_amount - amount)) {
            _error("Fee transfer failed");
        }

        return true;
    }

    /**
     * Transfer all wei from exchange to specified address.
     *
     * Can be called only by contract owner.
     *
     * @param _recipient address to transfer wei to.
     *
     * @return success.
     */
    function withdrawAllEth(address _recipient) onlyContractOwner() returns(bool) {
        return withdrawEth(_recipient, this.balance);
    }

    /**
     * Transfer all tokens and wei from exchange to specified address.
     *
     * Can be called only by contract owner.
     *
     * @param _recipient address to transfer tokens and wei to.
     *
     * @return success.
     */
    function withdrawAll(address _recipient) onlyContractOwner() returns(bool) {
        if (!withdrawAllTokens(_recipient)) {
            return false;
        }
        if (!withdrawAllEth(_recipient)) {
            throw;
        }
        return true;
    }

    /**
     * Overflow-safe multiplication.
     *
     * Throws in case of value overflow.
     *
     * @param _a first operand.
     * @param _b second operand.
     *
     * @return multiplication result.
     */
    function _mul(uint _a, uint _b) internal constant returns(uint) {
        uint result = _a * _b;
        if (_a != 0 && result / _a != _b) {
            throw;
        }
        return result;
    }

    /**
     * Accept all ether to maintain exchange supply.
     */
    function () payable {
        if(msg.value != 0)
            ReceivedEther(msg.sender, msg.value);
        else
            throw;
    }

}
