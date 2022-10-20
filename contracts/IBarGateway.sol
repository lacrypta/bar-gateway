//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.17;

import {IGateway} from "@lacrypta/gateway/contracts/IGateway.sol";

/**
 * Bar gateway interface, representing purchases of lists of line items
 *
 */
interface IBarGateway is IGateway {

    /**
     * Lite item description
     *
     * @custom:member item  The item name
     * @custom:member value  The item's value (could be negative)
     */
    struct LineItem {
        string item;
        int256 value;
    }

    /**
     * Purchase voucher
     *
     * @custom:member from  The address from which to transfer funds
     * @custom:member lineItems  The line items in the purchase (the item's total must be non-negative)
     */
    struct PurchaseVoucher {
        address from;
        LineItem[] lineItems;
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
     * @param deadline  Voucher deadline to use
     * @param from  Transfer origin to use
     * @param lineItems  Line items to use
     * @return voucher  The generated voucher
     */
    function buildPurchaseVoucher(uint256 nonce, uint256 deadline, address from, LineItem[] calldata lineItems) external view returns (Voucher memory voucher);

    /**
     * Build a PurchaseVoucher from the given parameters
     *
     * @param nonce  Nonce to use
     * @param from  Transfer origin to use
     * @param lineItems  Line items to use
     * @return voucher  The generated voucher
     */
    function buildPurchaseVoucher(uint256 nonce, address from, LineItem[] calldata lineItems) external view returns (Voucher memory voucher);
}
