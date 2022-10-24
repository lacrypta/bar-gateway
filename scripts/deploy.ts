// We require the Hardhat Runtime Environment explicitly here. This is optional
// but useful for running the script in a standalone fashion through `node <script>`.
//
// When running the script with `npx hardhat run <script>` you'll find the Hardhat
// Runtime Environment's members available in the global scope.
import hre from "hardhat";
import "console";

async function main() {
  // Hardhat always runs the compile task when running scripts with its command
  // line interface.
  //
  // If this script is run directly using `node` you may want to call compile
  // manually to make sure everything is compiled
  // await hre.run('compile');

  const { deployer } = await hre.getNamedAccounts();

  const peronioAddress = "0x78a486306D15E7111cca541F2f1307a1cFCaF5C4";

  await hre.deployments.deploy("ToString", {
    contract: "ToString",
    from: deployer,
    log: true,
    args: [],
  });
  const toStringAddress = (await hre.deployments.get("ToString")).address;
  console.log("ToString library deployed to:", toStringAddress);

  await hre.deployments.deploy("BarGateway", {
    contract: "BarGateway",
    from: deployer,
    log: true,
    args: [peronioAddress, "0xdeadbeefdeadbeefdeadbeefdeadbeefdeadbeef"],
    libraries: { ToString: toStringAddress },
  });
  const barGatewayAddress = (await hre.deployments.get("BarGateway")).address;
  console.log("Bar Gateway deployed to:", barGatewayAddress);

  if (hre.network.name == "matic") {
    await hre.run("verify:verify", { address: toStringAddress });
    await hre.run("verify:verify", {
      address: barGatewayAddress,
      constructorArguments: [peronioAddress, "0xdeadbeefdeadbeefdeadbeefdeadbeefdeadbeef"],
    });
  }
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
