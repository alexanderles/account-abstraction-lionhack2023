async function main() {
  const contractAddress = "0xe76420d76D9A6F979165073Bc1388532d1470e58";
  const myContract = await hre.ethers.getContractAt(
    "CustomAccount",
    contractAddress
  );

  const addDepositTx = await myContract.addDeposit({
    value: ethers.utils.parseEther("0.3"),
  });

  const transactionReceipt = await addDepositTx.wait(1);
  console.log("RECEIPT", transactionReceipt.events[0]);
  console.log("Deposit Done:", addDepositTx);

  // const getDepositTx = await myContract.getDeposit();
  // await getDepositTx.wait(1);
  // console.log("Deposit Is:", addDepositTx);

  // You can also pull in your JSON ABI; I'm not sure of the structure inside artifacts
  // let abi = ["event Deposit(address indexed sender, uint amount)"];
  // let iface = new ethers.utils.Interface(abi);

  // var logPromise = await ethers.provider.getLogs();
  // console.log("logPromise:", logPromise);
  // logPromise
  //   .then(function (logs) {
  //     console.log("Printing array of events:");
  //     let events = logs.map((log) => iface.parseLog(log));
  //     console.log(events);
  //   })
  //   .catch(function (err) {
  //     console.log(err);
  //   });

  // if (hre.getChainId() == 1337 || hre.getChainId() == 31337) {
  //   await moveBlocks(1, 1000);
  // }
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
