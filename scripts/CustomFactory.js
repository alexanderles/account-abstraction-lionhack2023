async function main() {
  const contractAddress = "0xd3f39d2127E4221859a852DF8Adb15EF2f017929";
  const myContract = await hre.ethers.getContractAt(
    "CustomAccountFactory",
    contractAddress
  );

  const createAccountTx = await myContract.createAccount(
    [
      "0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266",
      "0x70997970C51812dc3A010C7d01b50e0d17dc79C8",
      "0x3C44CdDdB6a900fa2b585dd299e03d12FA4293BC",
    ],
    2,
    0
  );

  const result = await createAccountTx.wait();
  console.log(result);
  console.log("Account created:", createAccountTx);
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
