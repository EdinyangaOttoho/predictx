import { ethers } from "hardhat";

async function main() {
  const [deployer] = await ethers.getSigners();
  console.log("Deploying contracts with the account:", deployer.address);

  const predictionMarket = await ethers.deployContract("PredictionMarket");
  await predictionMarket.waitForDeployment();

  console.log("PredictionMarket deployed to:", await predictionMarket.getAddress());
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });