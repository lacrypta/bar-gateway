// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.17;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

import {Gateway} from "@lacrypta/gateway/contracts/Gateway.sol";

import {IBarGateway} from "./IBarGateway.sol";

/**
 * Bar gateway implementation
 *
 */
contract BarGateway is Gateway, IBarGateway {
    using SafeERC20 for IERC20;

    // address of the underlying ERC20 token
    address internal immutable _token;

    // address of the configured destination
    address internal immutable _destination;

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
     */
    constructor(address theToken, address theDestination) {
        _token = theToken;
        _destination = theDestination;
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
     * Implementation of the IERC165 interface
     *
     * @param interfaceId  Interface ID to check against
     * @return  Whether the provided interface ID is supported
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IBarGateway).interfaceId || super.supportsInterface(interfaceId);
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
    function _extractPurchaseVoucherSigner(Voucher calldata voucher) internal pure returns (address signer) {
        PurchaseVoucher memory decodedVoucher = abi.decode(voucher.payload, (PurchaseVoucher));
        signer = decodedVoucher.from;
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
