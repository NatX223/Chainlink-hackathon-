// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity = 0.8.7;
pragma abicoder v2;

import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/token/ERC20/IERC20.sol";
import "https://github.com/Uniswap/v3-periphery/blob/main/contracts/libraries/TransferHelper.sol";
import "https://github.com/Uniswap/v3-periphery/blob/main/contracts/interfaces/ISwapRouter.sol";

contract XanaContract {

    ISwapRouter public immutable swapRouter;

    //the transaction event that is emmitted everytime a transaction is made
    event transaction(address payer, address receiver, uint _price, uint time);

    address public constant Router = 0xE592427A0AEce92De3Edee1F18E0157C05861564; // the router contract address

    // For this example, we will set the pool fee to 0.3%.
    uint24 public constant poolFee = 3000;

    constructor(ISwapRouter _swapRouter) {
        swapRouter = _swapRouter;
    }

    // this funnction to pay a certain amount specified by a receiver or merchant
    function sendTokenPrice (
        // the token the user is paying with
        address _paymenttoken,
        // the token the merchant or receiver approves
        address _acceptedtoken,
        // the price of the token to be paid by the user
        // the equivalent of the price of the token the merchant/user accepts 
        uint _amount,
        // the merchants/receivers address
        address _receiveraddress) external {
            IERC20 tokenIn = IERC20(_paymenttoken);
            // the price is actually to be calculated using an oracle
            tokenIn.transferFrom(msg.sender, address(this), /*price from oracle*/);
            tokenIn.approve(address(swapRouter), /*price from oracle*/);

        ISwapRouter.ExactOutputSingleParams memory params =
            ISwapRouter.ExactOutputSingleParams({
                tokenIn: _paymenttoken,
                tokenOut: _acceptedtoken,
                fee: poolFee,
                recipient: _receiveraddress,
                deadline: block.timestamp + 1 minute,
                amountOut: _ammount,
                amountInMaximum: /*price to be gotten by the oracle + a bit more*/,
                sqrtPriceLimitX96: 0
            });

            amountIn = swapRouter.exactOutputSingle(params);

            if (amountIn < amountInMaximum) {
                TransferHelper.safeApprove(tokenIn, address(swapRouter), 0);
                TransferHelper.safeTransfer(tokenIn, , amountInMaximum - amountIn);
            }

            emit transaction(msg.sender, receiver, _amount, block.timestamp);
        }

    function sendToken (
        // the token the user is paying with
        address _paymenttoken,
        // the token the merchant or receiver approves
        address _acceptedtoken,
        // the price of the token to be paid by the user
        // the equivalent of the price of the token the merchant/user accepts 
        uint _amount,
        // the merchants/receivers address
        address _receiver
        ) external returns (uint256 amountOut) {

            IERC20 tokenIn = IERC20(_paymenttoken);
            // the price is actually to be calculated using an oracle
            tokenIn.transferFrom(msg.sender, address(this), /*price from oracle*/);
            tokenIn.approve(address(swapRouter), /*price from oracle*/);

        ISwapRouter.ExactInputSingleParams memory params =
            ISwapRouter.ExactInputSingleParams({
                tokenIn: _paymenttoken,
                tokenOut: _acceptedtoken,
                fee: poolFee,
                recipient: _receiver,
                deadline: block.timestamp + 1 minute,
                amountIn: _amount,
                amountOutMinimum: /* the amount that will gotten from an oracle*/,
                sqrtPriceLimitX96: 0
            });

        // The call to `exactInputSingle` executes the swap and gets the amount paid to the receiver.
        amountOut = swapRouter.exactInputSingle(params);
        emit transaction(msg.sender, receiver, amountOut, block.timestamp);       
    }

}