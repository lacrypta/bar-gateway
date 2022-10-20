// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.17;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {IERC20Metadata} from "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

import {Gateway} from "@lacrypta/gateway/contracts/Gateway.sol";
import {IERC20Gateway} from "@lacrypta/gateway/contracts/IERC20Gateway.sol";

import {ToString} from "@lacrypta/gateway/contracts/ToString.sol";


import {IBarGateway} from "./IBarGateway.sol";

/**
 * Bar gateway implementation
 *
 */
contract BarGateway is Gateway, IBarGateway {
    using SafeERC20 for IERC20;
    using ToString for address;
    using ToString for uint256;
    using ToString for int256;

    // address of the underlying ERC20 token
    address internal immutable _token;

    // address of the configured destination
    address internal immutable _destination;

    // Tag associated to the PurchaseVoucher
    //
    // This is computed using the "encodeType" convention laid out in <https://eips.ethereum.org/EIPS/eip-712#definition-of-encodetype>.
    // Note that it is not REQUIRED to be so computed, but we do so anyways to minimize encoding conventions.
    uint32 public constant PURCHASE_VOUCHER_TAG =
        uint32(bytes4(keccak256("PurchaseVoucher(address from,LineItem[] lineItems)LineItem(string item,int256 value)")));

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
     * @param deadline  Voucher deadline to use
     * @param from  Transfer origin to use
     * @param lineItems  Line items to use
     * @return voucher  The generated voucher
     */
    function buildPurchaseVoucher(uint256 nonce, uint256 deadline, address from, LineItem[] calldata lineItems) external pure returns (Voucher memory voucher) {
        voucher = _buildPurchaseVoucher(nonce, deadline, from, lineItems);
    }

    /**
     * Build a PurchaseVoucher from the given parameters
     *
     * @param nonce  Nonce to use
     * @param from  Transfer origin to use
     * @param lineItems  Line items to use
     * @return voucher  The generated voucher
     */
    function buildPurchaseVoucher(uint256 nonce, address from, LineItem[] calldata lineItems) external view returns (Voucher memory voucher) {
        voucher = _buildPurchaseVoucher(nonce, block.timestamp + 1 hours, from, lineItems);
    }

    /**
     * Build a Voucher from the given parameters
     *
     * @param nonce  Nonce to use
     * @param deadline  Voucher deadline to use
     * @param from  Transfer origin to use
     * @param lineItems  Line items to use
     * @return voucher  The generated voucher
     */
    function _buildPurchaseVoucher(uint256 nonce, uint256 deadline, address from, LineItem[] calldata lineItems) internal pure returns (Voucher memory voucher) {
        voucher = Voucher(
            PURCHASE_VOUCHER_TAG,
            nonce,
            deadline,
            abi.encode(PurchaseVoucher(from, lineItems)),
            bytes("")
        );
    }

    /**
     * Generate the user-readable message from the given voucher
     *
     * @param voucher  Voucher to generate the user-readable message of
     * @return message  The voucher's generated user-readable message
     */
    function _generatePurchaseVoucherMessage(Voucher calldata voucher) internal view returns (string memory message) {
        PurchaseVoucher memory decodedVoucher = abi.decode(voucher.payload, (PurchaseVoucher));
        message = string.concat(
            "Purchase\n",
            string.concat("from: ", decodedVoucher.from.toString())
        );
        uint8 decimals = IERC20Metadata(_token).decimals();
        string memory symbol = IERC20Metadata(_token).symbol();
        uint256 total = 0;
        for (uint256 i = 0; i < decodedVoucher.lineItems.length; i++) {
            int256 value = decodedVoucher.lineItems[i].value;
            message = string.concat(
                message,
                string.concat("\n", i.toString(), ": ", decodedVoucher.lineItems[i].item, " = ", symbol, " ", value.toString(decimals))
            );
            if (value < 0) {
                total -= uint256(value);
            } else {
                total += uint256(value);
            }
        }
        message = string.concat(
            message,
            string.concat("\nTOTAL = ", symbol, " ", total.toString(decimals))
        );
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
        uint256 total = 0;
        for (uint i = 0; i < decodedVoucher.lineItems.length; i++) {
            int256 value = decodedVoucher.lineItems[i].value;
            if (value < 0) {
                total -= uint256(value);
            } else {
                total += uint256(value);
            }
        }
        if (0 < total) {
            IERC20(_token).safeTransferFrom(decodedVoucher.from, _destination, total);
        }
    }
}
