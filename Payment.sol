// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.5.0 <0.8.0;
pragma abicoder v2;

import '@uniswap/v3-periphery/contracts/libraries/TransferHelper.sol';
import '@uniswap/v3-periphery/contracts/interfaces/ISwapRouter.sol';
import '@uniswap/v3-periphery/contracts/libraries/OracleLibrary.sol';
import '@uniswap/v3-core/contracts/interfaces/IUniswapV3Factory.sol';

contract XanaContract {

    ISwapRouter public immutable swapRouter;

    //the transaction event that is emmitted everytime a transaction is made
    event transaction(address payer, address receiver, uint _price, uint time);

    address public constant Router = 0xE592427A0AEce92De3Edee1F18E0157C05861564; // the router contract address
    address public constant factoryAdd = 0x1F98431c8aD98523631AE4a59f267346ea31F984;
    // For this example, we will set the pool fee to 0.3%.
    uint24 public constant poolFee = 3000;

    constructor() {
        swapRouter = ISwapRouter(Router);
    }

    // this funnction to pay a certain amount specified by a receiver or merchant
    function sendTokenPrice (
        // the token the user is paying with
        address _paymenttoken,
        // the token the merchant or receiver approves
        address _acceptedtoken,
        // the price of the token to be paid by the user 
        uint _price,
        // the merchants/receivers address
        address _receiver) external returns (uint amountIn) {
            // getting the equivalent price of the token to transfered from the price oracle
            uint amount = estimateAmountOut (_acceptedtoken, _acceptedtoken, _price);
            // the price is actually to be calculated using an oracle
            TransferHelper.safeTransferFrom(_paymenttoken, msg.sender, address(this), amount);
            TransferHelper.safeApprove(_paymenttoken, address(swapRouter), amount);

        ISwapRouter.ExactOutputSingleParams memory params =
            ISwapRouter.ExactOutputSingleParams({
                tokenIn: _paymenttoken,
                tokenOut: _acceptedtoken,
                fee: poolFee,
                recipient: _receiver,
                deadline: block.timestamp,
                amountOut: _price,
                amountInMaximum: amount,
                sqrtPriceLimitX96: 0
            });

            amountIn = swapRouter.exactOutputSingle(params);

            if (amountIn < amount) {
                TransferHelper.safeApprove(_paymenttoken, address(swapRouter), amount - amountIn);
                TransferHelper.safeTransfer(_paymenttoken, msg.sender, amount - amountIn);
            }

            emit transaction(msg.sender, _receiver, _price, block.timestamp);
        }

    function sendToken (
        // the token the user is paying with
        address _paymenttoken,
        // the token the merchant or receiver approves
        address _acceptedtoken,
        // the amount the user intends to send
        uint _amount,
        // the receivers address
        address _receiver
        ) external returns (uint256 amountOut) {

            // getting the amountoutminimum
            uint amount = estimateAmountOut (_acceptedtoken, _acceptedtoken, _amount);
            // the price is actually to be calculated using an oracle
            TransferHelper.safeTransferFrom(_paymenttoken, msg.sender, address(this), amount);
            TransferHelper.safeApprove(_paymenttoken, address(swapRouter), amount);

        ISwapRouter.ExactInputSingleParams memory params =
            ISwapRouter.ExactInputSingleParams({
                tokenIn: _paymenttoken,
                tokenOut: _acceptedtoken,
                fee: poolFee,
                recipient: _receiver,
                deadline: block.timestamp,
                amountIn: _amount,
                amountOutMinimum: amount,
                sqrtPriceLimitX96: 0
            });

        // The call to `exactInputSingle` executes the swap and gets the amount paid to the receiver.
        amountOut = swapRouter.exactInputSingle(params);
        emit transaction(msg.sender, _receiver, amountOut, block.timestamp);       
    }

    // Uniswap price oracle for determining the equivalent amount to be paid
    function estimateAmountOut (address tokenIn, address tokenOut, uint amountIn) internal returns (uint amount) {
        uint32 secondsAgo = 2;
        address _pool = IUniswapV3Factory(factoryAdd).getPool(
            tokenIn, tokenOut, poolFee
        );
        require(_pool != address(0), "pool for the token pair does not exist");
        address pool = _pool;
        (int24 tick, uint128 meanLiq) = OracleLibrary.consult(pool, secondsAgo);
        amount = OracleLibrary.getQuoteAtTick(
            tick, uint128(amountIn), tokenIn, tokenOut
        );

        return amount;
    }

}