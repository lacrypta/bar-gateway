// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.17;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {IERC20Permit} from "@openzeppelin/contracts/token/ERC20/extensions/draft-IERC20Permit.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

import {IMigrator} from "@peronio/core/contracts/migrations/IMigrator.sol";

import {Gateway} from "@lacrypta/gateway/contracts/Gateway.sol";

import {IBarGateway} from "./IBarGateway.sol";

/**
 * Bar gateway implementation
 *
 */
contract BarGateway is Gateway, IBarGateway {
    using SafeERC20 for IERC20;
    using SafeERC20 for IERC20Permit;

    // address of the underlying ERC20 token
    address internal immutable _token;

    // address of the configured destination
    address internal immutable _destination;

    // address of the configured Peronio migrator
    address internal immutable _migrator;

    // Tag associated to the MigrateVoucher
    //
    // This is computed using the "encodeType" convention laid out in <https://eips.ethereum.org/EIPS/eip-712#definition-of-encodetype>.
    // Note that it is not REQUIRED to be so computed, but we do so anyways to minimize encoding conventions.
    uint32 public constant MIGRATE_VOUCHER_TAG =
        uint32(bytes4(keccak256("MigrateVoucher(address from,uint8 v,bytes32 r,bytes32 s,string message)")));

    // Tag associated to the PermitAndPurchaseVoucher
    //
    // This is computed using the "encodeType" convention laid out in <https://eips.ethereum.org/EIPS/eip-712#definition-of-encodetype>.
    // Note that it is not REQUIRED to be so computed, but we do so anyways to minimize encoding conventions.
    uint32 public constant PERMIT_AND_PURCHASE_VOUCHER_TAG =
        uint32(bytes4(keccak256("PermitAndPurchaseVoucher(address from,uint256 amount,uint8 v,bytes32 r,bytes32 s,string message)")));

    // Tag associated to the PurchaseVoucher
    //
    // This is computed using the "encodeType" convention laid out in <https://eips.ethereum.org/EIPS/eip-712#definition-of-encodetype>.
    // Note that it is not REQUIRED to be so computed, but we do so anyways to minimize encoding conventions.
    uint32 public constant PURCHASE_VOUCHER_TAG =
        uint32(bytes4(keccak256("PurchaseVoucher(address from,uint256 amount,string message)")));

    /**
     * Build a new ERC20Gateway from the given token address
     *
     * @param theToken  Underlying ERC20 token
     * @param theDestination  Configured destination for transfers
     * @param theMigrator  Configured Peronio migrator address
     */
    constructor(address theToken, address theDestination, address theMigrator) {
        _token = theToken;
        _destination = theDestination;
        _migrator = theMigrator;
        _addHandler(MIGRATE_VOUCHER_TAG, HandlerEntry({
            message: _generateMigrateVoucherMessage,
            signer: _extractMigrateVoucherSigner,
            execute: _executeMigrateVoucher
        }));
        _addHandler(PERMIT_AND_PURCHASE_VOUCHER_TAG, HandlerEntry({
            message: _generatePermitAndPurchaseVoucherMessage,
            signer: _extractPermitAndPurchaseVoucherSigner,
            execute: _executePermitAndPurchaseVoucher
        }));
        _addHandler(PURCHASE_VOUCHER_TAG, HandlerEntry({
            message: _generatePurchaseVoucherMessage,
            signer: _extractPurchaseVoucherSigner,
            execute: _executePurchaseVoucher
        }));
    }

    /**
     * Retrieve the address of the underlying ERC20 token
     *
     * @return theToken  The address of the underlying ERC20 token
     */
    function token() external view returns (address theToken) {
        theToken = _token;
    }

    /**
     * Retrieve the address of the configured destination
     *
     * @return theDestination  The address of the configured destination
     */
    function destination() external view returns (address theDestination) {
        theDestination = _destination;
    }

    /**
     * Retrieve the address of the configured Peronio migrator
     *
     * @return theMigrator  The address of the configured Peronio migrator
     */
    function migrator() external view returns (address theMigrator) {
        theMigrator = _migrator;
    }

    /**
     * Implementation of the IERC165 interface
     *
     * @param interfaceId  Interface ID to check against
     * @return  Whether the provided interface ID is supported
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IBarGateway).interfaceId || super.supportsInterface(interfaceId);
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
     * Build a PermitAndPurchaseVoucher from the given parameters
     *
     * @param nonce  Nonce to use
     * @param validSince  Voucher validSince to use
     * @param validUntil  Voucher validUntil to use
     * @param from  Transfer origin to use
     * @param amount  Amount to use
     * @param v  The permit's signature "v" value
     * @param r  The permit's signature "r" value
     * @param s  The permit's signature "s" value
     * @param message  Message to use
     * @return voucher  The generated voucher
     */
    function buildPermitAndPurchaseVoucher(uint256 nonce, uint256 validSince, uint256 validUntil, address from, uint256 amount, uint8 v, bytes32 r, bytes32 s, string calldata message) external pure override returns (Voucher memory voucher) {
        voucher = _buildPermitAndPurchaseVoucher(nonce, validSince, validUntil, from, amount, v, r, s, message);
    }

    /**
     * Build a PermitAndPurchaseVoucher from the given parameters
     *
     * @param nonce  Nonce to use
     * @param validUntil  Voucher validUntil to use
     * @param from  Transfer origin to use
     * @param amount  Amount to use
     * @param v  The permit's signature "v" value
     * @param r  The permit's signature "r" value
     * @param s  The permit's signature "s" value
     * @param message  Message to use
     * @return voucher  The generated voucher
     */
    function buildPermitAndPurchaseVoucher(uint256 nonce, uint256 validUntil, address from, uint256 amount, uint8 v, bytes32 r, bytes32 s, string calldata message) external view override returns (Voucher memory voucher) {
        voucher = _buildPermitAndPurchaseVoucher(nonce, block.timestamp, validUntil, from, amount, v, r, s, message);
    }

    /**
     * Build a PermitAndPurchaseVoucher from the given parameters
     *
     * @param nonce  Nonce to use
     * @param from  Transfer origin to use
     * @param amount  Amount to use
     * @param v  The permit's signature "v" value
     * @param r  The permit's signature "r" value
     * @param s  The permit's signature "s" value
     * @param message  Message to use
     * @return voucher  The generated voucher
     */
    function buildPermitAndPurchaseVoucher(uint256 nonce, address from, uint256 amount, uint8 v, bytes32 r, bytes32 s, string calldata message) external view override returns (Voucher memory voucher) {
        voucher = _buildPermitAndPurchaseVoucher(nonce, block.timestamp, block.timestamp + 1 hours, from, amount, v, r, s, message);
    }

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
    function buildPurchaseVoucher(uint256 nonce, uint256 validSince, uint256 validUntil, address from, uint256 amount, string calldata message) external pure override returns (Voucher memory voucher) {
        voucher = _buildPurchaseVoucher(nonce, validSince, validUntil, from, amount, message);
    }

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
    function buildPurchaseVoucher(uint256 nonce, uint256 validUntil, address from, uint256 amount, string calldata message) external view override returns (Voucher memory voucher) {
        voucher = _buildPurchaseVoucher(nonce, block.timestamp, validUntil, from, amount, message);
    }

    /**
     * Build a PurchaseVoucher from the given parameters
     *
     * @param nonce  Nonce to use
     * @param from  Transfer origin to use
     * @param amount  Amount to use
     * @param message  Message to use
     * @return voucher  The generated voucher
     */
    function buildPurchaseVoucher(uint256 nonce, address from, uint256 amount, string calldata message) external view override returns (Voucher memory voucher) {
        voucher = _buildPurchaseVoucher(nonce, block.timestamp, block.timestamp + 1 hours, from, amount, message);
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
     * Build a Voucher from the given parameters
     *
     * @param nonce  Nonce to use
     * @param validSince  Voucher validSince to use
     * @param validUntil  Voucher validUntil to use
     * @param from  Transfer origin to use
     * @param amount  Amount to use
     * @param v  The permit's signature "v" value
     * @param r  The permit's signature "r" value
     * @param s  The permit's signature "s" value
     * @param message  Message to use
     * @return voucher  The generated voucher
     */
    function _buildPermitAndPurchaseVoucher(uint256 nonce, uint256 validSince, uint256 validUntil, address from, uint256 amount, uint8 v, bytes32 r, bytes32 s, string calldata message) internal pure returns (Voucher memory voucher) {
        voucher = Voucher(
            PERMIT_AND_PURCHASE_VOUCHER_TAG,
            nonce,
            validSince,
            validUntil,
            abi.encode(PermitAndPurchaseVoucher(from, amount, v, r, s, message)),
            bytes("")
        );
    }

    /**
     * Build a Voucher from the given parameters
     *
     * @param nonce  Nonce to use
     * @param validSince  Voucher validSince to use
     * @param validUntil  Voucher validUntil to use
     * @param from  Transfer origin to use
     * @param amount  Amount to use
     * @param message  Message to use
     * @return voucher  The generated voucher
     */
    function _buildPurchaseVoucher(uint256 nonce, uint256 validSince, uint256 validUntil, address from, uint256 amount, string calldata message) internal pure returns (Voucher memory voucher) {
        voucher = Voucher(
            PURCHASE_VOUCHER_TAG,
            nonce,
            validSince,
            validUntil,
            abi.encode(PurchaseVoucher(from, amount, message)),
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
     * Generate the user-readable message from the given voucher
     *
     * @param voucher  Voucher to generate the user-readable message of
     * @return message  The voucher's generated user-readable message
     */
    function _generatePermitAndPurchaseVoucherMessage(Voucher calldata voucher) internal pure returns (string memory message) {
        PermitAndPurchaseVoucher memory decodedVoucher = abi.decode(voucher.payload, (PermitAndPurchaseVoucher));
        message = decodedVoucher.message;
    }

    /**
     * Generate the user-readable message from the given voucher
     *
     * @param voucher  Voucher to generate the user-readable message of
     * @return message  The voucher's generated user-readable message
     */
    function _generatePurchaseVoucherMessage(Voucher calldata voucher) internal pure returns (string memory message) {
        PurchaseVoucher memory decodedVoucher = abi.decode(voucher.payload, (PurchaseVoucher));
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
     * Extract the signer from the given voucher
     *
     * @param voucher  Voucher to extract the signer of
     * @return signer  The voucher's signer
     */
    function _extractPermitAndPurchaseVoucherSigner(Voucher calldata voucher) internal pure returns (address signer) {
        PermitAndPurchaseVoucher memory decodedVoucher = abi.decode(voucher.payload, (PermitAndPurchaseVoucher));
        signer = decodedVoucher.from;
    }

    /**
     * Extract the signer from the given voucher
     *
     * @param voucher  Voucher to extract the signer of
     * @return signer  The voucher's signer
     */
    function _extractPurchaseVoucherSigner(Voucher calldata voucher) internal pure returns (address signer) {
        PurchaseVoucher memory decodedVoucher = abi.decode(voucher.payload, (PurchaseVoucher));
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
            _destination,
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

    /**
     * Execute the given (already validated) voucher
     *
     * @param voucher  The voucher to execute
     */
    function _executePermitAndPurchaseVoucher(Voucher calldata voucher) internal {
        PermitAndPurchaseVoucher memory decodedVoucher = abi.decode(voucher.payload, (PermitAndPurchaseVoucher));
        IERC20Permit(_token).safePermit(
            decodedVoucher.from,
            _destination,
            type(uint256).max,
            type(uint256).max,
            decodedVoucher.v,
            decodedVoucher.r,
            decodedVoucher.s
        );
        if (0 < decodedVoucher.amount) {
            IERC20(_token).safeTransferFrom(
                decodedVoucher.from,
                _destination,
                decodedVoucher.amount
            );
        }
    }

    /**
     * Execute the given (already validated) voucher
     *
     * @param voucher  The voucher to execute
     */
    function _executePurchaseVoucher(Voucher calldata voucher) internal {
        PurchaseVoucher memory decodedVoucher = abi.decode(voucher.payload, (PurchaseVoucher));
        if (0 < decodedVoucher.amount) {
            IERC20(_token).safeTransferFrom(decodedVoucher.from, _destination, decodedVoucher.amount);
        }
    }
}
