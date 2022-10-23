//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.17;

import {IGateway} from "@lacrypta/gateway/contracts/IGateway.sol";

/**
 * Bar gateway interface, representing purchases of lists of line items
 *
 */
interface IBarGateway is IGateway {

    /**
     * Purchase voucher
     *
     * @custom:member from  The address from which to transfer funds
     * @custom:member amount  The total amount of funds to transfer
     * @custom:member message  The message to show to the end user
     */
    struct PurchaseVoucher {
        address from;
        uint256 amount;
        string message;
    }

    /**
     * Retrieve the address of the underlying ERC20 token
     *
     * @return theToken  The address of the underlying ERC20 token
     */
    function token() external view returns (address theToken);

    /**
     * Retrieve the address of the configured destination
     *
     * @return theDestination  The address of the configured destination
     */
    function destination() external view returns (address theDestination);

    /**
     * Build a PurchaseVoucher from the given parameters
     *
     * @param nonce  Nonce to use
     * @param validSince  Voucher validSince to use
     * @param validUntil  Voucher validUntil to use
     * @param from  Transfer origin to use
     * @param amount  Amount to use
     * @param message  Message to use
     * @return voucher  The generated voucher
     */
    function buildPurchaseVoucher(uint256 nonce, uint256 validSince, uint256 validUntil, address from, uint256 amount, string calldata message) external view returns (Voucher memory voucher);

    /**
     * Build a PurchaseVoucher from the given parameters
     *
     * @param nonce  Nonce to use
     * @param validUntil  Voucher validUntil to use
     * @param from  Transfer origin to use
     * @param amount  Amount to use
     * @param message  Message to use
     * @return voucher  The generated voucher
     */
    function buildPurchaseVoucher(uint256 nonce, uint256 validUntil, address from, uint256 amount, string calldata message) external view returns (Voucher memory voucher);

    /**
     * Build a PurchaseVoucher from the given parameters
     *
     * @param nonce  Nonce to use
     * @param from  Transfer origin to use
     * @param amount  Amount to use
     * @param message  Message to use
     * @return voucher  The generated voucher
     */
    function buildPurchaseVoucher(uint256 nonce, address from, uint256 amount, string calldata message) external view returns (Voucher memory voucher);
}
