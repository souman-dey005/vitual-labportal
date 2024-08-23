// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract VirtualLabManager {
    address public owner;

    struct Lab {
        string name;
        string description;
        address labOwner;
        bool isActive;
    }

    struct UserAccess {
        address user;
        uint256 labId;
        bool hasAccess;
    }

    struct Achievement {
        uint256 labId;
        string description;
        uint256 timestamp;
    }

    Lab[] public labs;
    mapping(address => UserAccess[]) public userAccess;
    mapping(address => Achievement[]) public userAchievements;

    event LabRegistered(uint256 labId, string name, string description, address labOwner);
    event AccessRequested(address user, uint256 labId);
    event AccessGranted(address user, uint256 labId);
    event LabStatusUpdated(uint256 labId, bool isActive);
    event AchievementRecorded(address user, uint256 labId, string description, uint256 timestamp);

    modifier onlyOwner() {
        require(msg.sender == owner, "Not the owner");
        _;
    }

    constructor() {
        owner = msg.sender;
    }

    // Register a new virtual lab
    function registerLab(string memory _name, string memory _description) external onlyOwner {
        uint256 labId = labs.length;
        labs.push(Lab({
            name: _name,
            description: _description,
            labOwner: msg.sender,
            isActive: true
        }));
        emit LabRegistered(labId, _name, _description, msg.sender);
    }

    // Request access to a virtual lab
    function requestAccess(uint256 _labId) external {
        require(_labId < labs.length, "Lab does not exist");
        require(labs[_labId].isActive, "Lab is not active");

        userAccess[msg.sender].push(UserAccess({
            user: msg.sender,
            labId: _labId,
            hasAccess: false
        }));
        emit AccessRequested(msg.sender, _labId);
    }

    // Grant access to a user for a specific lab
    function grantAccess(address _user, uint256 _labId) external onlyOwner {
        require(_labId < labs.length, "Lab does not exist");

        for (uint i = 0; i < userAccess[_user].length; i++) {
            if (userAccess[_user][i].labId == _labId) {
                userAccess[_user][i].hasAccess = true;
                emit AccessGranted(_user, _labId);
                return;
            }
        }
        revert("Access request not found");
    }

    // Update lab status (activate/deactivate)
    function updateLabStatus(uint256 _labId, bool _isActive) external onlyOwner {
        require(_labId < labs.length, "Lab does not exist");
        labs[_labId].isActive = _isActive;
        emit LabStatusUpdated(_labId, _isActive);
    }

    // Check if a user has access to a lab
    function checkAccess(address _user, uint256 _labId) external view returns (bool) {
        for (uint i = 0; i < userAccess[_user].length; i++) {
            if (userAccess[_user][i].labId == _labId) {
                return userAccess[_user][i].hasAccess;
            }
        }
        return false;
    }

    // Record an achievement for a user in a lab
    function recordAchievement(address _user, uint256 _labId, string memory _description) external onlyOwner {
        require(_labId < labs.length, "Lab does not exist");
        
        // Ensure the user has access to the lab
        bool hasAccess = false;
        for (uint i = 0; i < userAccess[_user].length; i++) {
            if (userAccess[_user][i].labId == _labId && userAccess[_user][i].hasAccess) {
                hasAccess = true;
                break;
            }
        }
        require(hasAccess, "User does not have access to this lab");

        userAchievements[_user].push(Achievement({
            labId: _labId,
            description: _description,
            timestamp: block.timestamp
        }));
        emit AchievementRecorded(_user, _labId, _description, block.timestamp);
    }

    // Get lab details
    function getLabDetails(uint256 _labId) external view returns (string memory name, string memory description, address labOwner, bool isActive) {
        require(_labId < labs.length, "Lab does not exist");
        Lab storage lab = labs[_labId];
        return (lab.name, lab.description, lab.labOwner, lab.isActive);
    }

    // Get achievements for a user
    function getAchievements(address _user) external view returns (Achievement[] memory) {
        return userAchievements[_user];
    }
}

