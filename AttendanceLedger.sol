// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/**
 * @title AttendanceLedger
 * @dev Immutable, append-only ledger for storing attendance records per session
 */
contract AttendanceLedger {

    // ─── Structs ───────────────────────────────────────────────────────────────

    struct AttendanceRecord {
        string  srn;
        string  subjectCode;
        uint256 sessionId;
        uint256 timestamp;
        bool    present;
    }

    struct Session {
        uint256 sessionId;
        string  subjectCode;
        string  subjectName;
        address instructor;
        uint256 startTime;
        uint256 endTime;      // 0 if still open
        bool    isOpen;
    }

    // ─── State ─────────────────────────────────────────────────────────────────

    address public controller;   // only AttendanceSystem can write

    uint256 private sessionCounter;

    // sessionId => Session
    mapping(uint256 => Session) public sessions;

    // sessionId => srn => AttendanceRecord
    mapping(uint256 => mapping(string => AttendanceRecord)) private records;

    // sessionId => list of SRNs marked present
    mapping(uint256 => string[]) private sessionAttendees;

    // srn => list of sessionIds attended
    mapping(string => uint256[]) private studentSessions;

    // ─── Events ────────────────────────────────────────────────────────────────

    event SessionCreated(uint256 indexed sessionId, string subjectCode, address instructor, uint256 startTime);
    event SessionClosed(uint256 indexed sessionId, uint256 endTime, uint256 totalPresent);
    event AttendanceMarked(uint256 indexed sessionId, string indexed srn, uint256 timestamp);

    // ─── Modifiers ─────────────────────────────────────────────────────────────

    modifier onlyController() {
        require(msg.sender == controller, "Ledger: Caller is not controller");
        _;
    }

    modifier sessionOpen(uint256 _sessionId) {
        require(sessions[_sessionId].isOpen, "Ledger: Session is not open");
        _;
    }

    // ─── Constructor ───────────────────────────────────────────────────────────

    constructor(address _controller) {
        controller = _controller;
    }

    // ─── Write Functions (controller only) ────────────────────────────────────

    /**
     * @notice Create a new attendance session
     */
    function createSession(
        string memory _subjectCode,
        string memory _subjectName,
        address       _instructor
    ) external onlyController returns (uint256 sessionId) {
        sessionCounter++;
        sessionId = sessionCounter;

        sessions[sessionId] = Session({
            sessionId:   sessionId,
            subjectCode: _subjectCode,
            subjectName: _subjectName,
            instructor:  _instructor,
            startTime:   block.timestamp,
            endTime:     0,
            isOpen:      true
        });

        emit SessionCreated(sessionId, _subjectCode, _instructor, block.timestamp);
    }

    /**
     * @notice Mark a student present in an open session (idempotent)
     */
    function markAttendance(uint256 _sessionId, string memory _srn)
        external
        onlyController
        sessionOpen(_sessionId)
    {
        // Prevent duplicate marking
        require(
            !records[_sessionId][_srn].present,
            "Ledger: Attendance already marked for this session"
        );

        records[_sessionId][_srn] = AttendanceRecord({
            srn:         _srn,
            subjectCode: sessions[_sessionId].subjectCode,
            sessionId:   _sessionId,
            timestamp:   block.timestamp,
            present:     true
        });

        sessionAttendees[_sessionId].push(_srn);
        studentSessions[_srn].push(_sessionId);

        emit AttendanceMarked(_sessionId, _srn, block.timestamp);
    }

    /**
     * @notice Close a session; no more attendance can be marked after this
     */
    function closeSession(uint256 _sessionId)
        external
        onlyController
        sessionOpen(_sessionId)
    {
        sessions[_sessionId].isOpen  = false;
        sessions[_sessionId].endTime = block.timestamp;

        emit SessionClosed(_sessionId, block.timestamp, sessionAttendees[_sessionId].length);
    }

    // ─── View Functions ────────────────────────────────────────────────────────

    function getSession(uint256 _sessionId)
        external
        view
        returns (Session memory)
    {
        return sessions[_sessionId];
    }

    function getAttendanceRecord(uint256 _sessionId, string memory _srn)
        external
        view
        returns (AttendanceRecord memory)
    {
        return records[_sessionId][_srn];
    }

    function isPresent(uint256 _sessionId, string memory _srn)
        external
        view
        returns (bool)
    {
        return records[_sessionId][_srn].present;
    }

    function getSessionAttendees(uint256 _sessionId)
        external
        view
        returns (string[] memory)
    {
        return sessionAttendees[_sessionId];
    }

    function getStudentSessions(string memory _srn)
        external
        view
        returns (uint256[] memory)
    {
        return studentSessions[_srn];
    }

    function getTotalSessions() external view returns (uint256) {
        return sessionCounter;
    }

    /**
     * @notice Compute attendance percentage of a student for a given subject
     */
    function getAttendancePercentage(string memory _srn, string memory _subjectCode)
        external
        view
        returns (uint256 attended, uint256 total, uint256 percentage)
    {
        uint256[] memory sessIds = studentSessions[_srn];

        for (uint256 i = 0; i < sessionCounter; i++) {
            uint256 sid = i + 1;
            if (
                keccak256(bytes(sessions[sid].subjectCode)) ==
                keccak256(bytes(_subjectCode))
            ) {
                total++;
                if (records[sid][_srn].present) {
                    attended++;
                }
            }
        }

        // suppress unused variable warning
        sessIds;

        percentage = total > 0 ? (attended * 100) / total : 0;
    }
}