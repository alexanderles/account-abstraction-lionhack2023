import { HardhatRuntimeEnvironment } from "hardhat/types";
import { DeployFunction } from "hardhat-deploy/types";
import { ethers } from "hardhat";

const deploySimpleAccountFactory: DeployFunction = async function (
  hre: HardhatRuntimeEnvironment
) {
  const provider = ethers.provider;
  const from = await provider.getSigner().getAddress();

  const entrypoint = await hre.deployments.get("EntryPoint");
  const ret = await hre.deployments.deploy("CustomAccount", {
    from,
    args: [
      entrypoint.address,
      [
        "0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266",
        "0x70997970C51812dc3A010C7d01b50e0d17dc79C8",
        "0x3C44CdDdB6a900fa2b585dd299e03d12FA4293BC",
      ],
      2,
    ],
    log: true,
    deterministicDeployment: true,
  });
  console.log("==SimpleAccountFactory addr=", ret.address);
};

export default deploySimpleAccountFactory;
module.exports.tags = ["all", "customAccount"];
