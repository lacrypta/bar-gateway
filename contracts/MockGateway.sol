// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/draft-IERC20Permit.sol)

pragma solidity ^0.8.0;

import "hardhat/console.sol";

struct Voucher {
  string tag;
  string nonce;
  string deadline;
  bytes payload;
  bytes metadata;
}

struct SimpleStruct1 {
  string hola;
  string chau;
}

struct SimpleStruct2 {
  string hola;
  bytes chau;
}

contract GatewayMock {
  uint256 log = 0;

  function nothing(string memory _simple)
    external
    pure
    returns (string memory message)
  {
    message = _simple;
  }

  function test1(SimpleStruct1 memory _simple)
    external
    pure
    returns (string memory message)
  {
    _simple = _simple;
    message = "holaa";
  }

  function test2(SimpleStruct2 memory _simple)
    external
    pure
    returns (string memory message)
  {
    _simple = _simple;
    message = "holaa";
  }

  function getMessage(Voucher memory _voucher)
    external
    pure
    returns (string memory message)
  {
    message = "-  AUTORIZO EL PAGO  -\n";

    message = string(abi.encodePacked(message, "Monto: 23423\n"));
    message = string(abi.encodePacked(message, "Order: #123\n"));
    message = string(abi.encodePacked(message, "Destino: 0x2343243242\n"));
    message = string(abi.encodePacked(message, "\n\n"));
    message = string(abi.encodePacked(message, "\n\n----- RAW ------\n\n"));
    message = string(abi.encodePacked(message, "Los datos:\n"));
    message = string(abi.encodePacked(message, _voucher.tag));
  }

  function serve(Voucher memory _voucher) external {
    console.log("--- Voucher ---");
    console.log("tag: ", _voucher.tag);
    log++;
  }
}
