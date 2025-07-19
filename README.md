# Digital Witness Protection Program

A blockchain-based witness protection system built on Stacks using Clarity smart contracts. This system provides secure identity management, location security, communication monitoring, threat assessment, and program completion tracking for protected witnesses.

## System Overview

The Digital Witness Protection Program consists of five interconnected smart contracts:

1. **Identity Creation Contract** (`identity-creation.clar`)
    - Generates secure new identities for protected witnesses
    - Manages identity verification and authentication
    - Tracks identity status and validity periods

2. **Location Security Contract** (`location-security.clar`)
    - Manages safe house assignments and relocations
    - Tracks location security levels and access permissions
    - Handles emergency relocation procedures

3. **Communication Monitoring Contract** (`communication-monitoring.clar`)
    - Secures contact with law enforcement handlers
    - Manages encrypted communication channels
    - Logs all authorized communications

4. **Threat Assessment Contract** (`threat-assessment.clar`)
    - Evaluates ongoing risks to witness safety
    - Tracks threat levels and security incidents
    - Manages risk mitigation strategies

5. **Program Completion Contract** (`program-completion.clar`)
    - Manages transition back to normal life
    - Handles identity restoration processes
    - Tracks program graduation and success metrics

## Features

- Secure identity generation and management
- Location-based security protocols
- Encrypted communication channels
- Real-time threat assessment
- Program completion tracking
- Emergency response procedures
- Audit trail for all operations

## Security Considerations

- All sensitive data is encrypted on-chain
- Access control through multi-signature requirements
- Time-locked operations for critical functions
- Emergency override capabilities for law enforcement
- Complete audit trail for accountability

## Contract Deployment

Deploy contracts in the following order:
1. identity-creation.clar
2. location-security.clar
3. communication-monitoring.clar
4. threat-assessment.clar
5. program-completion.clar

## Testing

Run the test suite using Vitest:

\`\`\`bash
npm test
\`\`\`

## Usage

Each contract provides specific functions for managing different aspects of the witness protection program. Refer to individual contract documentation for detailed API information.
