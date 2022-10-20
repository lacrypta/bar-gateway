//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.17;

import {ERC20Gateway} from "@lacrypta/gateway/contracts/ERC20Gateway.sol";

import {IERC20Gateway} from "@lacrypta/gateway/contracts/IERC20Gateway.sol";

import {IBarGateway} from "./IBarGateway.sol";

contract BarGateway is ERC20Gateway, IBarGateway {

    constructor(address _peronio) ERC20Gateway(_peronio) {
        _addHandler(TRANSFER_FROM_VOUCHER_TAG, HandlerEntry({
            message: _generateBarStyleTransferFromVoucherMessage,
            signer: _extractTransferFromVoucherSigner,
            execute: _executeTransferFromVoucher
        }));
    }

    /**
     * Retrieve the address of the underlying ERC20 token
     *
     * @return _erc20Token  The address of the underlying ERC20 token
     */
    function token() external view override(ERC20Gateway, IERC20Gateway) returns (address _erc20Token) {
        _erc20Token = IERC20Gateway(this).token();
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
    function buildBarTransferFromVoucher(uint256 nonce, uint256 deadline, address from, address to, uint256 amount, string calldata message) external pure returns (Voucher memory voucher) {
        voucher = _buildBarTransferFromVoucher(nonce, deadline, from, to, amount, message);
    }

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
    function buildBarTransferFromVoucher(uint256 nonce, address from, address to, uint256 amount, string calldata message) external view returns (Voucher memory voucher) {
        voucher = _buildBarTransferFromVoucher(nonce, block.timestamp + 1 hours, from, to, amount, message);
    }

    /**
     * Build a Voucher from the given parameters
     *
     * @param nonce  Nonce to use
     * @param deadline  Voucher deadline to use
     * @param from  Transfer origin to use
     * @param to  Transfer destination to use
     * @param amount  Transfer amount to use
     * @param message  Bar message to use
     * @return voucher  The generated voucher
     */
    function _buildBarTransferFromVoucher(uint256 nonce, uint256 deadline, address from, address to, uint256 amount, string memory message) internal pure returns (Voucher memory voucher) {
        voucher = Voucher(
            TRANSFER_FROM_VOUCHER_TAG,
            nonce,
            deadline,
            abi.encode(TransferFromVoucher(from, to, amount)),
            abi.encode(BarMetadata(message))
        );
    }

    /**
     * Generate the user-readable message from the given voucher
     *
     * @param voucher  Voucher to generate the user-readable message of
     * @return message  The voucher's generated user-readable message
     */
    function _generateBarStyleTransferFromVoucherMessage(Voucher calldata voucher) internal pure returns (string memory message) {
        abi.decode(voucher.payload, (TransferFromVoucher));  // make sure we can decode the body
        message = abi.decode(voucher.metadata, (BarMetadata)).message;
    }
}
