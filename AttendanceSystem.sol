// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "./StudentRegistry.sol";
import "./AttendanceLedger.sol";

/**
 * @title AttendanceSystem
 * @dev Main smart contract orchestrating student registration,
 *      session management, and SRN-based attendance marking.
 *      Supports manual SRN entry (typed / scanned) as the identifier.
 */
contract AttendanceSystem {

    // ─── State ─────────────────────────────────────────────────────────────────

    address public admin;
    StudentRegistry public registry;
    AttendanceLedger public ledger;

    // Role: instructors can open/close sessions and mark attendance
    mapping(address => bool) public isInstructor;

    // ─── Events ────────────────────────────────────────────────────────────────

    event InstructorAdded(address indexed instructor);
    event InstructorRevoked(address indexed instructor);
    event AttendanceMarkedViaSRN(uint256 indexed sessionId, string srn, uint256 timestamp);

    // ─── Modifiers ─────────────────────────────────────────────────────────────

    modifier onlyAdmin() {
        require(msg.sender == admin, "System: Not admin");
        _;
    }

    modifier onlyInstructor() {
        require(isInstructor[msg.sender] || msg.sender == admin, "System: Not instructor");
        _;
    }

    // ─── Constructor ───────────────────────────────────────────────────────────

    constructor() {
        admin    = msg.sender;
        registry = new StudentRegistry();
        ledger   = new AttendanceLedger(address(this));
    }

    // ─── Admin: Role Management ────────────────────────────────────────────────

    function addInstructor(address _instructor) external onlyAdmin {
        isInstructor[_instructor] = true;
        emit InstructorAdded(_instructor);
    }

    function revokeInstructor(address _instructor) external onlyAdmin {
        isInstructor[_instructor] = false;
        emit InstructorRevoked(_instructor);
    }

    // ─── Admin: Student Management (delegates to registry) ────────────────────

    function registerStudent(
        string memory _name,
        string memory _srn,
        string memory _department
    ) external onlyAdmin {
        registry.registerStudent(_name, _srn, _department);
    }

    function updateStudent(
        string memory _srn,
        string memory _name,
        string memory _department
    ) external onlyAdmin {
        registry.updateStudent(_srn, _name, _department);
    }

    function deactivateStudent(string memory _srn) external onlyAdmin {
        registry.deactivateStudent(_srn);
    }

    // ─── Instructor: Session Management ───────────────────────────────────────

    /**
     * @notice Open a new class session for a subject
     * @return sessionId  The ID of the newly created session
     */
    function openSession(string memory _subjectCode, string memory _subjectName)
        external
        onlyInstructor
        returns (uint256 sessionId)
    {
        sessionId = ledger.createSession(_subjectCode, _subjectName, msg.sender);
    }

    /**
     * @notice Close an open session — no more attendance after this
     */
    function closeSession(uint256 _sessionId) external onlyInstructor {
        // Verify instructor owns this session
        AttendanceLedger.Session memory s = ledger.getSession(_sessionId);
        require(
            s.instructor == msg.sender || msg.sender == admin,
            "System: Not session owner"
        );
        ledger.closeSession(_sessionId);
    }

    // ─── Core: Mark Attendance via SRN ────────────────────────────────────────

    /**
     * @notice Mark attendance for a student identified by their SRN.
     *         This function is triggered when a student manually enters
     *         their SRN (or it is scanned via QR / RFID off-chain and
     *         submitted here).
     * @param _sessionId  Active session ID
     * @param _srn        Student Registration Number
     */
    function markAttendanceBySRN(uint256 _sessionId, string memory _srn)
        external
        onlyInstructor
    {
        require(registry.isStudentRegistered(_srn), "System: Student SRN not registered");

        ledger.markAttendance(_sessionId, _srn);

        emit AttendanceMarkedViaSRN(_sessionId, _srn, block.timestamp);
    }

    /**
     * @notice Bulk mark attendance for multiple SRNs (e.g., from RFID batch scan)
     */
    function markBulkAttendance(uint256 _sessionId, string[] calldata _srns)
        external
        onlyInstructor
    {
        for (uint256 i = 0; i < _srns.length; i++) {
            if (registry.isStudentRegistered(_srns[i])) {
                // Skip already-marked or invalid without reverting
                if (!ledger.isPresent(_sessionId, _srns[i])) {
                    ledger.markAttendance(_sessionId, _srns[i]);
                    emit AttendanceMarkedViaSRN(_sessionId, _srns[i], block.timestamp);
                }
            }
        }
    }

    // ─── View: Query Attendance ────────────────────────────────────────────────

    function isStudentPresent(uint256 _sessionId, string memory _srn)
        external
        view
        returns (bool)
    {
        return ledger.isPresent(_sessionId, _srn);
    }

    function getStudentAttendanceHistory(string memory _srn)
        external
        view
        returns (uint256[] memory sessionIds)
    {
        return ledger.getStudentSessions(_srn);
    }

    function getSessionReport(uint256 _sessionId)
        external
        view
        returns (
            AttendanceLedger.Session memory session,
            string[] memory attendees
        )
    {
        session   = ledger.getSession(_sessionId);
        attendees = ledger.getSessionAttendees(_sessionId);
    }

    function getAttendancePercentage(string memory _srn, string memory _subjectCode)
        external
        view
        returns (uint256 attended, uint256 total, uint256 percentage)
    {
        return ledger.getAttendancePercentage(_srn, _subjectCode);
    }

    function getStudentInfo(string memory _srn)
        external
        view
        returns (StudentRegistry.Student memory)
    {
        return registry.getStudent(_srn);
    }

    function getTotalSessions() external view returns (uint256) {
        return ledger.getTotalSessions();
    }

    function getTotalStudents() external view returns (uint256) {
        return registry.getTotalStudents();
    }
}