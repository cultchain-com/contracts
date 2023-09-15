// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "./RandomizedCommittee.sol";


contract CharityEvent is ERC721Enumerable, ERC721URIStorage {
    using Counters for Counters.Counter;

    uint256 public constant PROPOSAL_CONFIRMATION_COMMITTEE_SIZE = 3;
    uint256 public constant MILESTONE_COMPLETION_COMMITTEE_SIZE = 3;
    RandomizedCommittee private committeeContract;

    Counters.Counter private _eventIdCounter;
    Counters.Counter private _milestoneIdCounter;

    uint256[] public allEventIds;
    address[] public _creatorsArray;
    enum EventMilestoneStatus { Pending, Approved, Rejected, NotStartedYet }

    struct CreatorLeaderboard {
        address creator;
        uint256 totalRaised;
        uint256 numberOfEvents;
    }

    struct Milestone {
        address creator;
        string name;
        string description;
        uint256 spendedAmount;
        uint256 targetAmount;
        uint256 endDate;
        uint256 ratingSum;
        uint256 ratingCount;
        uint256 committeeId;
        bool completed;
        bool isFoundReleased; // Keep your eyes on this new variable;
        EventMilestoneStatus status;
    }

    struct Report {
        address reporter;
        string text;
        uint256 timestamp;
    }

    struct CharityEventData {
        address creator;
        string name;
        string description;
        uint256 targetAmount;
        uint256 endDate;
        uint256 collectedAmount;
        Milestone[] milestones;
        uint256 ratingSum;
        uint256 ratingCount;
        string[] tags;
        Report[] reports;
        EventCategory category;
        EventMilestoneStatus status;
        uint256 committeeId;
        bool isFundraisingOver;
    }

    enum EventCategory { Health, Education, Environment, DisasterRelief, AnimalWelfare, Others }

    mapping(uint256 => CharityEventData) public _events;
    mapping(uint256 => CharityEventData) public _eventsMilestones;
    mapping(address => uint256[]) public _creatorsList;


    constructor(address _committeeAddress) ERC721("CharityEvent", "CEVT") {
        committeeContract = RandomizedCommittee(_committeeAddress);
    }

    struct EventFeedback {
        address feedbackProvider;
        string feedbackText;
        uint256 timestamp;
    }

    mapping(uint256 => EventFeedback[]) private _eventFeedbacks;

    function provideEventFeedback(uint256 eventId, string memory feedbackText) external {
        EventFeedback memory eventFeedback = EventFeedback({
            feedbackProvider: msg.sender,
            feedbackText: feedbackText,
            timestamp: block.timestamp
        });

        _eventFeedbacks[eventId].push(eventFeedback);
    }

    function getEventFeedbacks(uint256 eventId) external view returns (EventFeedback[] memory) {
        return _eventFeedbacks[eventId];
    }

    function markMilestoneAsCompleted(uint256 eventId, uint256 milestoneIndex, uint256 spendedAmount) external {
        require(msg.sender == _events[eventId].creator, "Only the event creator or validators can mark milestones as completed");
        require(milestoneIndex < _events[eventId].milestones.length, "Invalid milestone index");

        _events[eventId].milestones[milestoneIndex].completed = true;
        _events[eventId].milestones[milestoneIndex].spendedAmount = spendedAmount;
        uint256 committeeId = committeeContract.formCommittee(MILESTONE_COMPLETION_COMMITTEE_SIZE, eventId, milestoneIndex, RandomizedCommittee.CommitteeType.Milestone);

        _events[eventId].milestones[milestoneIndex].committeeId = committeeId;
        _events[eventId].milestones[milestoneIndex].status = EventMilestoneStatus.Pending;
    }

    function createEvent(string memory tokenUri, string memory name, string memory description, uint256 targetAmount, uint256 endDate, EventCategory category) external returns (uint256) {
        // require(hasRole(PROPOSAL_CREATOR_ROLE, msg.sender), "Must have creator role to create an event");

        _eventIdCounter.increment();
        uint256 newEventId = _eventIdCounter.current();

        uint256 committeeId = committeeContract.formCommittee(PROPOSAL_CONFIRMATION_COMMITTEE_SIZE, newEventId, 0, RandomizedCommittee.CommitteeType.Event);

        _mint(msg.sender, newEventId);
        _setTokenURI(newEventId, tokenUri);

        _events[newEventId].creator = msg.sender;
        _events[newEventId].name = name;
        _events[newEventId].description = description;
        _events[newEventId].targetAmount = targetAmount;
        _events[newEventId].endDate = endDate;
        _events[newEventId].collectedAmount = 0;
        _events[newEventId].ratingSum = 0;
        _events[newEventId].ratingCount = 0;
        _events[newEventId].category = category;
        _events[newEventId].status = EventMilestoneStatus.Pending;
        _events[newEventId].committeeId = committeeId;
        _events[newEventId].isFundraisingOver = false;
        allEventIds.push(newEventId);

        if (_creatorsList[msg.sender].length != 0) {
            _creatorsArray.push(msg.sender);
            _creatorsList[msg.sender].push(newEventId);
        } else{
            _creatorsList[msg.sender].push(newEventId);
        }

        return newEventId;
    }

    function updateEventCommitteeStatus(uint256 _eventId, bool decision) external {
        if (decision == true) {
            _events[_eventId].status = EventMilestoneStatus.Approved;
        } else {
            _events[_eventId].status = EventMilestoneStatus.Rejected;
        }
    }

    function updateMilestoneCommitteeStatus(uint256 _eventId, uint256 milestoneIndex, bool decision, bool _isComplited) external {
        if (_isComplited == true) {
            if (decision == true) {
                _events[_eventId].milestones[milestoneIndex].status = EventMilestoneStatus.Approved;
            } else {
                _events[_eventId].milestones[milestoneIndex].status = EventMilestoneStatus.Rejected;
            }
        } else {
            _events[_eventId].milestones[milestoneIndex].status = EventMilestoneStatus.Pending;
        }
    }

    function isEventApproved(uint256 eventId) external view returns(bool){
        if (_events[eventId].status == EventMilestoneStatus.Approved && _events[eventId].isFundraisingOver == false) {
            return true;
        } else {
            return false;
        }
    }

    function isEventFundraisingOver(uint256 eventId) external view returns(bool){
        return _events[eventId].isFundraisingOver;
    }

    function possibleMilestoneAmount(uint256 eventId) external view returns(uint256 milestoneIndex, uint256 amount) {
        require(_events[eventId].status == EventMilestoneStatus.Approved, "Event not approved.");
        uint256 milestoneLenght = _events[eventId].milestones.length;


        for (milestoneIndex=0; milestoneIndex < milestoneLenght; milestoneIndex++){
            if (_events[eventId].milestones[milestoneIndex].isFoundReleased == false) {
                if (milestoneIndex == 0) {
                    amount = _events[eventId].milestones[milestoneIndex].targetAmount;
                    return (milestoneIndex, amount);
                } else {
                    if (_events[eventId].milestones[milestoneIndex-1].completed == true && _events[eventId].milestones[milestoneIndex-1].status == EventMilestoneStatus.Approved) {
                        amount = _events[eventId].milestones[milestoneIndex].targetAmount;
                        return (milestoneIndex, amount);
                    }
                }
            }
        }
    }

    function retrieveEventCreator(uint256 eventId) external view returns(address) {
        return _events[eventId].creator;
    }

    function updateCollectedAmount(uint256 eventId, uint256 collectedAmount) external {
        _events[eventId].collectedAmount += collectedAmount;
        if (_events[eventId].collectedAmount > _events[eventId].targetAmount) {
            _events[eventId].isFundraisingOver = true;
        }
    }

    // Method to get details of a specific event
    function getEventDetails(uint256 eventId) external view returns (
        address creator,
        string memory name,
        string memory description,
        uint256 targetAmount,
        uint256 endDate,
        uint256 collectedAmount,
        uint256 ratingSum,
        uint256 ratingCount,
        EventCategory category,
        EventMilestoneStatus status,
        uint256 committeeId
    ) {
        CharityEventData storage eventData = _events[eventId];
        return (
            eventData.creator,
            eventData.name,
            eventData.description,
            eventData.targetAmount,
            eventData.endDate,
            eventData.collectedAmount,
            eventData.ratingSum,
            eventData.ratingCount,
            eventData.category,
            eventData.status,
            eventData.committeeId
        );
    }

    function getMilestonesForEvent(uint256 eventId) external view returns (Milestone[] memory) {
        return _events[eventId].milestones;
    }

    // Method to list all created events
    function listAllEvents() external view returns (uint256[] memory) {
        return allEventIds;
    }

    function isEventActive(uint256 eventId) external view returns (bool) {
        return block.timestamp <= _events[eventId].endDate;
    }

    function addMilestone(uint256 eventId, string memory milestoneName, string memory description, uint256 targetAmount, uint256 endDate) external {
        require(msg.sender == _events[eventId].creator, "Only the event creator can add milestones");
    
        Milestone memory newMilestone = Milestone({
            creator: msg.sender,
            name: milestoneName,
            description: description,
            spendedAmount: 0,
            targetAmount: targetAmount,
            endDate: endDate,
            ratingSum: 0,
            ratingCount: 0,
            committeeId: 0,
            completed: false,
            isFoundReleased: false,
            status: EventMilestoneStatus.NotStartedYet
        });
    
        _events[eventId].milestones.push(newMilestone);
    }

    // function addReport(uint256 eventId, string memory reportText) external {
    //     Report memory newReport = Report({
    //         reporter: msg.sender,
    //         text: reportText,
    //         timestamp: block.timestamp
    //     });
    //     _events[eventId].reports.push(newReport);
    // }

    // function addTag(uint256 eventId, string memory tag) external {
    //     require(msg.sender == _events[eventId].creator, "Only the event creator can add tags");
    //     _events[eventId].tags.push(tag);
    // }

    function rateEvent(uint256 eventId, uint256 rating) external {
        require(rating >= 1 && rating <= 5, "Rating should be between 1 and 5");
        _events[eventId].ratingSum += rating;
        _events[eventId].ratingCount++;
    }

    function getEventAverageRating(uint256 eventId) external view returns (uint256) {
        if (_events[eventId].ratingCount == 0) return 0;
        return _events[eventId].ratingSum / _events[eventId].ratingCount;
    }

    function getTopCreators(uint n) public view returns (CreatorLeaderboard[] memory) {
        
        CreatorLeaderboard[] memory creatorDetailsArray = new CreatorLeaderboard[](_creatorsArray.length);

        for (uint256 i = 0; i < _creatorsArray.length; i++) {
            uint256 raisedAmount = 0;
            uint256[] memory _creatorEvents = _creatorsList[_creatorsArray[i]];
            for(uint256 j=0; j < _creatorEvents.length; j++) {
                raisedAmount += _events[_creatorEvents[j]].collectedAmount;
            }
            creatorDetailsArray[i] = CreatorLeaderboard({
                creator: _creatorsArray[i],
                totalRaised: raisedAmount,
                numberOfEvents: _creatorEvents.length
            });
        }
        return creatorDetailsArray;
    }

    function _beforeTokenTransfer(address from, address to, uint256 tokenId, uint256 batchSize)
        internal
        override(ERC721, ERC721Enumerable)
    {
        super._beforeTokenTransfer(from, to, tokenId, batchSize);
    }

    function _burn(uint256 tokenId) internal override(ERC721, ERC721URIStorage) {
        super._burn(tokenId);
    }

    function tokenURI(uint256 tokenId)
        public
        view
        override(ERC721, ERC721URIStorage)
        returns (string memory)
    {
        return super.tokenURI(tokenId);
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC721Enumerable, ERC721URIStorage)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }
}
