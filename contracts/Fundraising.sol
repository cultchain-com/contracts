// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/utils/Counters.sol";
import "./CharityEvent.sol";
import "./RandomizedCommittee.sol";

contract Fundraising {
    using Counters for Counters.Counter;

    CharityEvent private charityEventContract;
    RandomizedCommittee private randomizedCommitteeContract;

    address payable public platformAddress;

    struct Donor {
        address donorAddress;
        uint256 totalDonated;
    }

     struct ValidatorDetails {
        address validator;
        uint256 totalEarnings;
        uint256 numberOfEvents;
    }

    struct Donation {
        address donor;
        uint256 amount;
        uint256 eventId;
        uint256 timestamp;
        string message;
    }

    struct WithdrawRequestHistory {
        uint256 eventId;
        uint256 timestamp;
        uint256 requestedAmount;
        string description;
        string committeeAccept;
        address[] validators;
        bool isConfirmedByCommittee;
    }

    mapping(address => uint256[]) private _validatorsEarnings;
    mapping(uint256 => uint256) private _eventBalance;
    mapping(uint256 => Donation[]) private _eventDonations;
    mapping(address => Donation[]) private _donors;
    mapping(uint256 => WithdrawRequestHistory[]) private _eventwithdrawHistory;

    Donor[] public leaderboard;

    constructor(address _charityEventAddress, address _randomizedCommitteeContract, address payable _platformAddress) {
        charityEventContract = CharityEvent(_charityEventAddress);
        randomizedCommitteeContract = RandomizedCommittee(_randomizedCommitteeContract);
        platformAddress = _platformAddress;
    }

    function getTopDonors(uint256 topN) external view returns (Donor[] memory) {
        uint256 length = topN < leaderboard.length ? topN : leaderboard.length;
        Donor[] memory topDonors = new Donor[](length);

        for (uint256 i = 0; i < length; i++) {
            topDonors[i] = leaderboard[i];
        }

        return topDonors;
    }

    function getTotalEarnings(address validator) private view returns (uint256) {
        uint256 total = 0;
        for (uint256 i = 0; i < _validatorsEarnings[validator].length; i++) {
            total += _validatorsEarnings[validator][i];
        }
        return total;
    }

    function getValidatorsLeaderBoard(uint256 n) external view returns(ValidatorDetails[] memory) {
        address[] memory validators = randomizedCommitteeContract.getAllValidatorsAddress();
        ValidatorDetails[] memory validatorDetailsArray = new ValidatorDetails[](validators.length);

        for (uint256 i = 0; i < validators.length; i++) {
            validatorDetailsArray[i] = ValidatorDetails({
                validator: validators[i],
                totalEarnings: getTotalEarnings(validators[i]),
                numberOfEvents: _validatorsEarnings[validators[i]].length
            });
        }

        // Sort using insertion sort
        for (uint256 i = 0; i < validatorDetailsArray.length; i++) {
            uint256 j = i;
            while (j > 0 && validatorDetailsArray[j].totalEarnings > validatorDetailsArray[j - 1].totalEarnings) {
                // Swap
                (validatorDetailsArray[j], validatorDetailsArray[j - 1]) = (validatorDetailsArray[j - 1], validatorDetailsArray[j]);
                j--;
            }
        }

        // Extract the top N validators
        ValidatorDetails[] memory topNValidators = new ValidatorDetails[](n);
        for (uint256 i = 0; i < n; i++) {
            topNValidators[i] = validatorDetailsArray[i];
        }

        return topNValidators;
    }

    function donateToEvent(uint256 eventId, string memory message) external payable {
        require(charityEventContract.isEventApproved(eventId), "The event is not confirmed by the committee or Fundaraising is over.");
        require(msg.value > 0, "Donation amount must be greater than 0");

        Donation memory newDonation = Donation({
            donor: msg.sender,
            amount: msg.value,
            eventId: eventId,
            timestamp: block.timestamp,
            message: message
        });
        _eventBalance[eventId] += msg.value;
        charityEventContract.updateCollectedAmount(eventId, msg.value);
        _eventDonations[eventId].push(newDonation);
        _donors[msg.sender].push(newDonation);
        updateLeaderboard(msg.sender, msg.value);
    }

    function updateLeaderboard(address donorAddress, uint256 amount) private {
        uint256 donorIndex = 0;
        bool isExistingDonor = false;

        // Check if donor exists in the leaderboard
        for (uint256 i = 0; i < leaderboard.length; i++) {
            if (leaderboard[i].donorAddress == donorAddress) {
                donorIndex = i;
                isExistingDonor = true;
                break;
            }
        }

        // If new donor, add to the leaderboard
        if (!isExistingDonor) {
            leaderboard.push(Donor({
                donorAddress: donorAddress,
                totalDonated: amount
            }));
        } else {
            // Update existing donor's total donated amount
            leaderboard[donorIndex].totalDonated += amount;

            // Adjust position in the leaderboard (simple bubble sort logic for demonstration)
            while (donorIndex > 0 && leaderboard[donorIndex].totalDonated > leaderboard[donorIndex - 1].totalDonated) {
                // Swap with the previous donor
                Donor memory temp = leaderboard[donorIndex];
                leaderboard[donorIndex] = leaderboard[donorIndex - 1];
                leaderboard[donorIndex - 1] = temp;

                donorIndex--;
            }
        }
    }

    function getValidators(uint256 committeeId) public view returns(address[] memory){
        RandomizedCommittee.CommitteeDecisionDetails memory committee = randomizedCommitteeContract.getCommitteeDecision(committeeId);
        return committee.validatorAddresses;
    }

    function requestWithdraw(uint256 eventId, uint256 _amount) external {
        require(msg.sender == charityEventContract.retrieveEventCreator(eventId), "You are not the creator of the event.");
        require(charityEventContract.isEventFundraisingOver(eventId), "Fundraising is not over yet.");
        uint256 milestonesIndex;
        uint256 amount;
        (milestonesIndex, amount) = charityEventContract.possibleMilestoneAmount(eventId);
        require(_amount == amount, "Your requested amount should be the same as milestone amount");
        require(_amount <= _eventBalance[eventId], "Your requested amount is higher than the event balancce");

        // Calculate distribution amounts
        uint256 platformAmount = (_amount * 5) / 100; // 5% for the platform
        uint256 validatorsTotalAmount = (_amount * 3) / 100; // 3% for validators
        uint256 creatorAmount = _amount - platformAmount - validatorsTotalAmount; // 92% for the event creator

        address[] memory validators;
        if (milestonesIndex == 0) {
            validators = getValidators(eventId); // This must be committeeId not the eventId
        } else {
            validators = getValidators(milestonesIndex - 1); // Must be the CommitteeId not the milestoneindex;
        }

        uint256 amountPerValidator = validatorsTotalAmount / validators.length;
        for (uint256 i = 0; i < validators.length; i++) {
            payable(validators[i]).transfer(amountPerValidator);
            _validatorsEarnings[validators[i]].push(amountPerValidator);
        }

        platformAddress.transfer(platformAmount);
        payable(msg.sender).transfer(creatorAmount);

        WithdrawRequestHistory memory newWithdraw;
        newWithdraw.eventId = eventId;
        newWithdraw.timestamp = block.timestamp;
        newWithdraw.requestedAmount = _amount;
        newWithdraw.committeeAccept = "No comment";
        newWithdraw.validators = validators;
        newWithdraw.isConfirmedByCommittee = true;
    }

    // function refundToDonors(eventId) external {}

    function getEventDonations(uint256 eventId) external view returns (Donation[] memory) {
        return _eventDonations[eventId];
    }

    function getDonorDonations(address _address) external view returns (Donation[] memory){
        return _donors[_address];
    }

}