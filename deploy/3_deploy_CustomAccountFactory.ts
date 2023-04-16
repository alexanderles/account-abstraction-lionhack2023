import { HardhatRuntimeEnvironment } from "hardhat/types";
import { DeployFunction } from "hardhat-deploy/types";
import { ethers } from "hardhat";

const deploySimpleAccountFactory: DeployFunction = async function (
  hre: HardhatRuntimeEnvironment
) {
  const provider = ethers.provider;
  const from = await provider.getSigner().getAddress();

  const entrypoint = await hre.deployments.get("EntryPoint");
  const ret = await hre.deployments.deploy("CustomAccountFactory", {
    from,
    args: [entrypoint.address],
    gasLimit: 6e5,
    log: true,
    deterministicDeployment: true,
  });
  console.log("==CustomAccountFactory addr=", ret.address);
};

export default deploySimpleAccountFactory;
module.exports.tags = ["all", "customAccount"];
