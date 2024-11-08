async function main() {

    const [deployer] = await ethers.getSigners();

    console.log(
        "Starting Deployments from account:",
        deployer.address
    );

    console.log(
        "Deploying USDC Contract"
    );

    const gasPrice = await ethers.provider.getGasPrice();

    const adjustedGasPrice = gasPrice.mul(200).div(100);

    const Token = await ethers.getContractFactory("Token");

    const token = await Token.deploy(1000000000000); // 1 Trillion Supply

    console.log(
        "Deployed USDC Contract with address:",
        token.address
    );

    console.log(
        "Deploying Factory Contract:"
    );

    const Factory = await ethers.getContractFactory("Factory");

    const factory = await Factory.deploy(token.address);

    console.log(
        "Deployed Factory Contract with address:",
        factory.address
    );

}

main()
  .then(() => process.exit(0))
  .catch(error => {
    console.error(error);
    process.exit(1);
});