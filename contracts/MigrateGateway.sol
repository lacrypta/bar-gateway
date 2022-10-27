// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.17;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {IERC20Permit} from "@openzeppelin/contracts/token/ERC20/extensions/draft-IERC20Permit.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

import {IMigrator} from "@peronio/core/contracts/migrations/IMigrator.sol";

import {Gateway} from "@lacrypta/gateway/contracts/Gateway.sol";

import {IMigrateGateway} from "./IMigrateGateway.sol";

/**
 * Migrate gateway implementation
 *
 */
contract MigrateGateway is Gateway, IMigrateGateway {
    using SafeERC20 for IERC20;
    using SafeERC20 for IERC20Permit;

    // address of the underlying ERC20 token
    address internal immutable _token;

    // address of the configured Peronio migrator
    address internal immutable _migrator;

    // Tag associated to the MigrateVoucher
    //
    // This is computed using the "encodeType" convention laid out in <https://eips.ethereum.org/EIPS/eip-712#definition-of-encodetype>.
    // Note that it is not REQUIRED to be so computed, but we do so anyways to minimize encoding conventions.
    uint32 public constant MIGRATE_VOUCHER_TAG =
        uint32(bytes4(keccak256("MigrateVoucher(address from,uint8 v,bytes32 r,bytes32 s,string message)")));

    /**
     * Build a new MigrateGateway from the given token address
     *
     * @param theToken  Underlying ERC20 token
     * @param theMigrator  Configured Peronio migrator address
     */
    constructor(address theToken, address theMigrator) {
        _token = theToken;
        _migrator = theMigrator;
        _addHandler(MIGRATE_VOUCHER_TAG, HandlerEntry({
            message: _generateMigrateVoucherMessage,
            signer: _extractMigrateVoucherSigner,
            execute: _executeMigrateVoucher
        }));
    }

    /**
     * Retrieve the address of the underlying ERC20 token
     *
     * @return theToken  The address of the underlying ERC20 token
     */
    function token() external view override returns (address theToken) {
        theToken = _token;
    }

    /**
     * Retrieve the address of the configured Peronio migrator
     *
     * @return theMigrator  The address of the configured Peronio migrator
     */
    function migrator() external view override returns (address theMigrator) {
        theMigrator = _migrator;
    }

    /**
     * Implementation of the IERC165 interface
     *
     * @param interfaceId  Interface ID to check against
     * @return  Whether the provided interface ID is supported
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IMigrateGateway).interfaceId || super.supportsInterface(interfaceId);
    }

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
    function buildMigrateVoucher(uint256 nonce, uint256 validSince, uint256 validUntil, address from, uint8 v, bytes32 r, bytes32 s, string calldata message) external pure override returns (Voucher memory voucher) {
        voucher = _buildMigrateVoucher(nonce, validSince, validUntil, from, v, r, s, message);
    }

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
    function buildMigrateVoucher(uint256 nonce, uint256 validUntil, address from, uint8 v, bytes32 r, bytes32 s, string calldata message) external view override returns (Voucher memory voucher) {
        voucher = _buildMigrateVoucher(nonce, block.timestamp, validUntil, from, v, r, s, message);
    }

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
    function buildMigrateVoucher(uint256 nonce, address from, uint8 v, bytes32 r, bytes32 s, string calldata message) external view override returns (Voucher memory voucher) {
        voucher = _buildMigrateVoucher(nonce, block.timestamp, block.timestamp + 1 hours, from, v, r, s, message);
    }

    /**
     * Build a Voucher from the given parameters
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
    function _buildMigrateVoucher(uint256 nonce, uint256 validSince, uint256 validUntil, address from, uint8 v, bytes32 r, bytes32 s, string calldata message) internal pure returns (Voucher memory voucher) {
        voucher = Voucher(
            MIGRATE_VOUCHER_TAG,
            nonce,
            validSince,
            validUntil,
            abi.encode(MigrateVoucher(from, v, r, s, message)),
            bytes("")
        );
    }

    /**
     * Generate the user-readable message from the given voucher
     *
     * @param voucher  Voucher to generate the user-readable message of
     * @return message  The voucher's generated user-readable message
     */
    function _generateMigrateVoucherMessage(Voucher calldata voucher) internal pure returns (string memory message) {
        MigrateVoucher memory decodedVoucher = abi.decode(voucher.payload, (MigrateVoucher));
        message = decodedVoucher.message;
    }

    /**
     * Extract the signer from the given voucher
     *
     * @param voucher  Voucher to extract the signer of
     * @return signer  The voucher's signer
     */
    function _extractMigrateVoucherSigner(Voucher calldata voucher) internal pure returns (address signer) {
        MigrateVoucher memory decodedVoucher = abi.decode(voucher.payload, (MigrateVoucher));
        signer = decodedVoucher.from;
    }

    /**
     * Execute the given (already validated) voucher
     *
     * @param voucher  The voucher to execute
     */
    function _executeMigrateVoucher(Voucher calldata voucher) internal {
        MigrateVoucher memory decodedVoucher = abi.decode(voucher.payload, (MigrateVoucher));
        IERC20Permit(_token).safePermit(
            decodedVoucher.from,
            address(this),
            type(uint256).max,
            type(uint256).max,
            decodedVoucher.v,
            decodedVoucher.r,
            decodedVoucher.s
        );
        uint256 balance = IERC20(_token).balanceOf(decodedVoucher.from);
        IERC20(_token).safeTransferFrom(decodedVoucher.from, address(this), balance);
        IMigrator(_migrator).migrate(balance);
    }
}
