// We require the Hardhat Runtime Environment explicitly here. This is optional
// but useful for running the script in a standalone fashion through `node <script>`.
//
// When running the script with `npx hardhat run <script>` you'll find the Hardhat
// Runtime Environment's members available in the global scope.
import { ethers } from "hardhat";

async function main() {
  // Hardhat always runs the compile task when running scripts with its command
  // line interface.
  //
  // If this script is run directly using `node` you may want to call compile
  // manually to make sure everything is compiled
  // await hre.run('compile');

  // We get the contract to deploy
  const ToString = await ethers.getContractFactory("ToString");
  const toString = await ToString.deploy();
  const Gateway = await ethers.getContractFactory("BarGateway", {
    libraries: { ToString: toString.address },
  });
  const gateway = await Gateway.deploy(
    "0x78a486306D15E7111cca541F2f1307a1cFCaF5C4"
  );

  await gateway.deployed();

  console.log("Gateway deployed to:", gateway.address);
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
