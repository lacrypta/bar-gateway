//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.17;

import {IGateway} from "@lacrypta/gateway/contracts/IGateway.sol";

/**
 * Migrate gateway interface, for Peronio migration
 *
 */
interface IMigrateGateway is IGateway {

    /**
     * (infinite-in-time-and-amount) Migration voucher
     *
     * @custom:member from  The address from which to transfer funds
     * @custom:member v  The permit's signature "v" value
     * @custom:member r  The permit's signature "r" value
     * @custom:member s  The permit's signature "s" value
     * @custom:member message  The message to show to the end user
     */
    struct MigrateVoucher {
        address from;
        uint8 v;
        bytes32 r;
        bytes32 s;
        string message;
    }

    /**
     * Retrieve the address of the underlying ERC20 token
     *
     * @return theToken  The address of the underlying ERC20 token
     */
    function token() external view returns (address theToken);

    /**
     * Retrieve the address of the configured Peronio migrator
     *
     * @return theMigrator  The address of the configured Peronio migrator
     */
    function migrator() external view returns (address theMigrator);

    /**
     * Build a MigrateVoucher from the given parameters
     *
     * @param nonce  Nonce to use
     * @param validSince  Voucher validSince to use
     * @param validUntil  Voucher validUntil to use
     * @param from  Transfer origin to use
     * @param v  The permit's signature "v" value
     * @param r  The permit's signature "r" value
     * @param s  The permit's signature "s" value
     * @param message  Message to use
     * @return voucher  The generated voucher
     */
    function buildMigrateVoucher(uint256 nonce, uint256 validSince, uint256 validUntil, address from, uint8 v, bytes32 r, bytes32 s, string calldata message) external view returns (Voucher memory voucher);

    /**
     * Build a MigrateVoucher from the given parameters
     *
     * @param nonce  Nonce to use
     * @param validUntil  Voucher validUntil to use
     * @param from  Transfer origin to use
     * @param v  The permit's signature "v" value
     * @param r  The permit's signature "r" value
     * @param s  The permit's signature "s" value
     * @param message  Message to use
     * @return voucher  The generated voucher
     */
    function buildMigrateVoucher(uint256 nonce, uint256 validUntil, address from, uint8 v, bytes32 r, bytes32 s, string calldata message) external view returns (Voucher memory voucher);

    /**
     * Build a MigrateVoucher from the given parameters
     *
     * @param nonce  Nonce to use
     * @param from  Transfer origin to use
     * @param v  The permit's signature "v" value
     * @param r  The permit's signature "r" value
     * @param s  The permit's signature "s" value
     * @param message  Message to use
     * @return voucher  The generated voucher
     */
    function buildMigrateVoucher(uint256 nonce, address from, uint8 v, bytes32 r, bytes32 s, string calldata message) external view returns (Voucher memory voucher);
}
