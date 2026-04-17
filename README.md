# Blockchain Attendance System

## Overview

This project is a simple blockchain-based attendance management system built using Solidity. It ensures secure, tamper-proof, and transparent tracking of student attendance.

The system is divided into three smart contracts:

* StudentRegistry → Manages student information
* AttendanceLedger → Stores attendance records
* AttendanceSystem → Acts as the controller that connects everything

---

## Project Structure

```
contracts/

├── StudentRegistry.sol
├── AttendanceLedger.sol
└── AttendanceSystem.sol
```

---

## Features

* Register students with unique SRN
* Create attendance sessions
* Mark student attendance
* Prevent duplicate attendance marking
* Close sessions after completion
* View attendance records and statistics
* Compute attendance percentage per subject

---

## Access Control

* Admin → Manages student registration
* Controller (AttendanceSystem) → Handles attendance operations
* Users → Can only view data

---

## How It Works

1. Admin registers students in StudentRegistry
2. AttendanceSystem creates a session in AttendanceLedger
3. Attendance is marked for students
4. Session is closed after completion
5. Data can be queried anytime

---

## Deployment Steps

1. Compile contracts using Solidity (version ^0.8.20)
2. Deploy StudentRegistry
3. Deploy AttendanceLedger with controller address
4. Deploy AttendanceSystem and link both contracts

---

## Example Functions

* registerStudent() → Add a new student
* createSession() → Start attendance session
* markAttendance() → Mark student present
* closeSession() → End session
* getAttendancePercentage() → View attendance stats

---

## Notes

* Strings are compared using keccak256 hashing
* Only authorized roles can modify data
* Blockchain transactions cost gas

---

## Future Improvements

* Add role-based access (multiple instructors)
* Improve gas efficiency
* Add frontend UI (React/Web3)
* Store data off-chain for scalability

---

## License

MIT License
