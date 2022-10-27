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

  const peronioAddress = process.env.PERONIO_ADDRESS;
  const destinationAddress = process.env.DESTINATION_ADDRESS;
  const migratorAddress = process.env.MIGRATOR_ADDRESS;

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
    args: [peronioAddress, destinationAddress],
    libraries: { ToString: toStringAddress },
  });
  const barGatewayAddress = (await hre.deployments.get("BarGateway")).address;
  console.log("Bar Gateway deployed to:", barGatewayAddress);

  await hre.deployments.deploy("MigrateGateway", {
    contract: "MigrateGateway",
    from: deployer,
    log: true,
    args: [peronioAddress, migratorAddress],
    libraries: { ToString: toStringAddress },
  });
  const migrateGatewayAddress = (await hre.deployments.get("MigrateGateway")).address;
  console.log("Migrate Gateway deployed to:", migrateGatewayAddress);

  if (hre.network.name == "matic") {
    await hre.run("verify:verify", { address: toStringAddress });
    await hre.run("verify:verify", {
      address: barGatewayAddress,
      constructorArguments: [peronioAddress, destinationAddress],
    });
    await hre.run("verify:verify", {
      address: migrateGatewayAddress,
      constructorArguments: [peronioAddress, migratorAddress],
    });
  }
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
