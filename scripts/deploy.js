const main = async () => {
  const gameContractFactory = await hre.ethers.getContractFactory('MyEpicGame');
  const gameContract = await gameContractFactory.deploy(
    ["Dan", "Josh", "Sam", "Glantz"],    // Names
    ["QmeZEBgKDsbGuKt6wZ2qBpiCv7hQbFRUEXmQm2i4UHYFSW", // Images (IPFS CID's)
    "QmXTqh4dpmGsHZFDKz2bWZi5qp1rMnRs6GsjtsU2HSgBPk", 
    "Qme5hPthMd2jAwpMxhNZ3YWrFiQUnB6NJqYHSUJQD4udax",
    "QmWAmzZL3V55bSVKvoMNvKAabmMcgynhoaBBuXW4tmY7xZ"],
    [100, 200, 50, 150],   // HP values
    [150, 50, 200, 100],   // Attack damage values
    ["Pump", "Bush", "AK-47", "Tac"], // Weapons
    "The Beached Whale", // Boss Name
    "QmV5dqQwE4AKxtZMaQhHs6krdHwZy5PnfWygm73VPSJuFS", // Boss Image URI
    10000, // Boss HP
    10, // Boss Attack Damage
  );
  await gameContract.deployed();
  console.log("Contract deployed to:", gameContract.address);
};

const runMain = async () => {
  try {
    await main();
    process.exit(0);
  } catch (error) {
    console.log(error);
    process.exit(1);
  }
};

runMain();