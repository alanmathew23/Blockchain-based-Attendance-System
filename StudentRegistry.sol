// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/**
 * @title StudentRegistry
 * @dev Manages student registration and unique SRN-based identity on-chain
 */
contract StudentRegistry {

    // ─── Structs ───────────────────────────────────────────────────────────────

    struct Student {
        string  name;
        string  srn;           // Student Registration Number (unique ID)
        string  department;
        bool    isRegistered;
        uint256 registeredAt;
    }

    // ─── State ─────────────────────────────────────────────────────────────────

    address public admin;

    // srn => Student
    mapping(string => Student) private students;

    // list of all SRNs
    string[] public allSRNs;

    // ─── Events ────────────────────────────────────────────────────────────────

    event StudentRegistered(string indexed srn, string name, string department, uint256 timestamp);
    event StudentUpdated(string indexed srn, string name, string department);
    event StudentDeactivated(string indexed srn);

    // ─── Modifiers ─────────────────────────────────────────────────────────────

    modifier onlyAdmin() {
        require(msg.sender == admin, "StudentRegistry: Caller is not admin");
        _;
    }

    modifier studentExists(string memory srn) {
        require(students[srn].isRegistered, "StudentRegistry: Student not found");
        _;
    }

    // ─── Constructor ───────────────────────────────────────────────────────────

    constructor() {
        admin = msg.sender;
    }

    // ─── Admin Functions ───────────────────────────────────────────────────────

    /**
     * @notice Register a new student using their SRN
     * @param _name        Full name of the student
     * @param _srn         Unique Student Registration Number
     * @param _department  Department name
     */
    function registerStudent(
        string memory _name,
        string memory _srn,
        string memory _department
    ) external onlyAdmin {
        require(bytes(_srn).length > 0,  "StudentRegistry: SRN cannot be empty");
        require(bytes(_name).length > 0, "StudentRegistry: Name cannot be empty");
        require(!students[_srn].isRegistered, "StudentRegistry: SRN already registered");

        students[_srn] = Student({
            name:         _name,
            srn:          _srn,
            department:   _department,
            isRegistered: true,
            registeredAt: block.timestamp
        });

        allSRNs.push(_srn);

        emit StudentRegistered(_srn, _name, _department, block.timestamp);
    }

    /**
     * @notice Update student details
     */
    function updateStudent(
        string memory _srn,
        string memory _name,
        string memory _department
    ) external onlyAdmin studentExists(_srn) {
        students[_srn].name       = _name;
        students[_srn].department = _department;
        emit StudentUpdated(_srn, _name, _department);
    }

    /**
     * @notice Deactivate (soft-delete) a student
     */
    function deactivateStudent(string memory _srn) external onlyAdmin studentExists(_srn)
    {
        students[_srn].isRegistered = false;
        emit StudentDeactivated(_srn);
    }

    // ─── View Functions ────────────────────────────────────────────────────────

    function getStudent(string memory _srn)external view returns (Student memory)
    {
        return students[_srn];
    }

    function isStudentRegistered(string memory _srn)external view returns (bool)
    {
        return students[_srn].isRegistered;
    }

    function getTotalStudents() external view returns (uint256) {
        return allSRNs.length;
    }

    function getAllSRNs() external view returns (string[] memory) {
        return allSRNs;
    }
}