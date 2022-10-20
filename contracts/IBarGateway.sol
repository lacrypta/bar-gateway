//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.17;

import {IERC20Gateway} from "@lacrypta/gateway/contracts/IERC20Gateway.sol";

interface IBarGateway is IERC20Gateway {
    /**
     * Metadata to use for bar purchases
     *
     * @custom:member message  Message to use instead of normal transferFromVoucher message
     */
    struct BarMetadata {
        string message;
    }

    /**
     * Build a Bar TransferFromVoucher from the given parameters
     *
     * @param nonce  Nonce to use
     * @param deadline  Voucher deadline to use
     * @param from  Transfer origin to use
     * @param to  Transfer destination to use
     * @param amount  Transfer amount to use
     * @param message  Bar message to use
     * @return voucher  The generated voucher
     */
    function buildBarTransferFromVoucher(uint256 nonce, uint256 deadline, address from, address to, uint256 amount, string calldata message) external view returns (Voucher memory voucher);

    /**
     * Build a Bar TransferFromVoucher from the given parameters
     *
     * @param nonce  Nonce to use
     * @param from  Transfer origin to use
     * @param to  Transfer destination to use
     * @param amount  Transfer amount to use
     * @param message  Bar message to use
     * @return voucher  The generated voucher
     */
    function buildBarTransferFromVoucher(uint256 nonce, address from, address to, uint256 amount, string calldata message) external view returns (Voucher memory voucher);
}
