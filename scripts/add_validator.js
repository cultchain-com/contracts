require("dotenv").config();
const Web3 = require("web3");
const HDWalletProvider = require("@truffle/hdwallet-provider");

process.on("unhandledRejection", (reason, promise) => {
  console.error("Unhandled Rejection at:", promise, "reason:", reason);
  // Application specific logging, throwing an error, or other logic here
});

const EventCategory = {
  Health: 0,
  Education: 1,
  Environment: 2,
  DisasterRelief: 3,
  AnimalWelfare: 4,
  Others: 5,
};

const randomizedCommitteeArtifacts = require("../artifacts/contracts/RandomizedCommittee.sol/RandomizedCommittee.json");
const charityEventsArtifacts = require("../artifacts/contracts/CharityEvent.sol/CharityEvent.json");

const randomizedCommitteeABI = randomizedCommitteeArtifacts.abi;
const charityEventsABI = charityEventsArtifacts.abi;

const randomizedCommitteeAddress = "0x3dDEdded14c2Bf429EA0cf9F31764F9aa14a6AFc";
const charityEventsAddress = "0x1C2622cb0b50A33b1d866065340EB7091EC6954b";

const provider = new HDWalletProvider(
  "8eb2e13f92e850fb487aa6ff5aa786818d440395115ba91baf34e33d6722ac24",
  "https://rpc-mumbai.maticvigil.com/"
);
const web3 = new Web3(provider);

let validators = [
  "0x13DC81736DdE2c2b788c7634610e549d5fd0C294",
  "0x056D87A67455C9E4400FE3945c739E5f50Ec7f1E",
  "0xD05f036B42e10771Ff35F184E4A4C68B9100C836",
  "0x3da2581ad70D98a45ebE7D3A51D821ddDe640432",
  "0xa25994d6F8404aFFD42Ae5918d9e2D704e06E20A",
];

const addValidator = async (validatorAddress) => {
  const accounts = await web3.eth.getAccounts();
  const ownerAccount = accounts[0];

  const randomizedCommitteeContract = new web3.eth.Contract(
    randomizedCommitteeABI,
    randomizedCommitteeAddress
  );

  try {
    const tx = await randomizedCommitteeContract.methods
      .addValidator(validatorAddress)
      .send({ from: ownerAccount });
    console.log(
      "Validator added successfully. Transaction hash:",
      tx.transactionHash
    );
  } catch (error) {
    console.error("Error adding validator:", error);
  }
};

const getUserOngoingDecisions = async (address) => {};

const assignValidatorRole = async (address) => {
  const accounts = await web3.eth.getAccounts();
  const ownerAccount = accounts[0];

  const randomizedCommitteeContract = new web3.eth.Contract(
    randomizedCommitteeABI,
    randomizedCommitteeAddress
  );

  try {
    const tx = await randomizedCommitteeContract.methods
      .grantValidatorRole(address)
      .send({ from: ownerAccount });
    console.log(
      "Validator Access Granted successfully. Transaction hash:",
      tx.transactionHash
    );
  } catch (error) {
    console.error("Error creating event:", error);
  }
};

const createEvent = async (
  eventName,
  eventDescription,
  targetAmount,
  endDate,
  categoryString
) => {
  const accounts = await web3.eth.getAccounts();
  const ownerAccount = accounts[0];

  const charityEventsContract = new web3.eth.Contract(
    charityEventsABI,
    charityEventsAddress
  );

  const category = EventCategory[categoryString];
  if (category === undefined) {
    console.error("Invalid category:", categoryString);
    return;
  }

  try {
    const tx = await charityEventsContract.methods
      .createEvent(eventName, eventDescription, targetAmount, endDate, category)
      .send({ from: ownerAccount });
    console.log(
      "Event created successfully. Transaction hash:",
      tx.transactionHash
    );
  } catch (error) {
    console.error("Error creating event:", error);
  }
};

// // Add Validators - It's admin priviledge
// (async () => {
//   for (const validatorAddress of validators) {
//     await addValidator(validatorAddress);
//   }
// })();

// // Create Event
// (async () => {
//   const eventName = "Clean Water Drive";
//   const eventDescription = "A charity event for providing clean water.";
//   const targetAmount = web3.utils.toWei("10", "ether");
//   const endDate = Math.floor(Date.now() / 1000 + 86400 * 7); // 7 days from now
//   const categoryString = "Environment";

//   await assignValidatorRole(charityEventsAddress);

//   await createEvent(
//     eventName,
//     eventDescription,
//     targetAmount,
//     endDate,
//     categoryString
//   );
// })();

// // Get My UpComing Committees
