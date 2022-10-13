//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.17;

import {ERC20PermitGateway} from "@lacrypta/gateway/contracts/ERC20PermitGateway.sol";


contract BarGateway is ERC20PermitGateway {

    constructor(address _peronio) ERC20PermitGateway(_peronio) {}

    // To obtain message to be signed from voucher: stringifyVoucher(voucher)
    //   The signing procedure _should_ sign the _hash_ of this message
    //
    // To serve a voucher (1): serveVoucher(voucher, r, s, v)
    // To serve a voucher (2): serveVoucher(voucher, sig)
    //
    //
    // Vouchers:
    //   PermitVoucher:
    //
    //     Voucher permitVoucher = Voucher(
    //       0x77ed603f,       // tag --- constant (see: ERC20PermitGateway.PERMIT_VOUCHER_TAG)
    //       nonce,            // nonce --- random
    //       deadline,         // voucher deadline
    //       abi.encode(       // payload
    //         PermitVoucher(
    //             owner,      // funds owner
    //             spender,    // funds spender
    //             value,      // funds being permitted
    //             deadline,   // permit deadline
    //             v,          // signature "v"
    //             r,          // signature "r"
    //             s           // signature "s"
    //         )
    //       ),
    //       bytes()           // metadata --- empty
    //     );
    //
    //   TransferFromVoucher:
    //
    //     Voucher transferFromVoucher = Voucher(
    //       0xf7d48c1c,             // tag -- constant (see: ERC20Gateway.TRANSFER_FROM_VOUCHER_TAG)
    //       nonce,                  // nonce --- random
    //       deadline,               // voucher deadline
    //       abi.encode(             // payload
    //         TransferFromVoucher(
    //           from,               // transfer source
    //           to,                 // transfer destination
    //           amount              // transfer amount
    //         )
    //       ),
    //       bytes()                 // metadata --- empty
    //     );
    //
}
