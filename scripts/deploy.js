const hre = require("hardhat");

async function main() {
  const basePrice = hre.ethers.utils.parseEther("0.001");
  const slope = hre.ethers.utils.parseEther("0.0001");

  const Project = await hre.ethers.getContractFactory("Project");
  const project = await Project.deploy(basePrice, slope);

  await project.deployed();

  console.log("Dynamic Bonding Curve Token Sale contract deployed to:", project.address);
}

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
