// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
 * @title SkillVerify
 * @dev Decentralized platform for issuing and verifying professional skills and credentials
 */
contract SkillVerify {
    
    struct Credential {
        uint256 id;
        address holder;
        address issuer;
        string skillName;
        string credentialURI; // IPFS hash or metadata URI
        uint256 issueDate;
        uint256 expiryDate;
        bool isValid;
    }
    
    struct Issuer {
        bool isAuthorized;
        string organizationName;
        uint256 credentialsIssued;
    }
    
    // State variables
    uint256 private credentialCounter;
    address public admin;
    
    mapping(uint256 => Credential) public credentials;
    mapping(address => Issuer) public issuers;
    mapping(address => uint256[]) public holderCredentials;
    
    // Events
    event IssuerAuthorized(address indexed issuer, string organizationName);
    event CredentialIssued(uint256 indexed credentialId, address indexed holder, address indexed issuer, string skillName);
    event CredentialRevoked(uint256 indexed credentialId);
    
    // Modifiers
    modifier onlyAdmin() {
        require(msg.sender == admin, "Only admin can perform this action");
        _;
    }
    
    modifier onlyAuthorizedIssuer() {
        require(issuers[msg.sender].isAuthorized, "Not an authorized issuer");
        _;
    }
    
    constructor() {
        admin = msg.sender;
    }
    
    /**
     * @dev Authorize an organization to issue credentials
     * @param _issuer Address of the issuing organization
     * @param _organizationName Name of the organization
     */
    function authorizeIssuer(address _issuer, string memory _organizationName) 
        external 
        onlyAdmin 
    {
        require(!issuers[_issuer].isAuthorized, "Issuer already authorized");
        
        issuers[_issuer] = Issuer({
            isAuthorized: true,
            organizationName: _organizationName,
            credentialsIssued: 0
        });
        
        emit IssuerAuthorized(_issuer, _organizationName);
    }
    
    /**
     * @dev Issue a new credential to a holder
     * @param _holder Address of the credential holder
     * @param _skillName Name of the skill being certified
     * @param _credentialURI URI containing credential metadata
     * @param _expiryDate Expiry timestamp (0 for non-expiring)
     */
    function issueCredential(
        address _holder,
        string memory _skillName,
        string memory _credentialURI,
        uint256 _expiryDate
    ) 
        external 
        onlyAuthorizedIssuer 
        returns (uint256)
    {
        require(_holder != address(0), "Invalid holder address");
        require(bytes(_skillName).length > 0, "Skill name required");
        
        credentialCounter++;
        
        credentials[credentialCounter] = Credential({
            id: credentialCounter,
            holder: _holder,
            issuer: msg.sender,
            skillName: _skillName,
            credentialURI: _credentialURI,
            issueDate: block.timestamp,
            expiryDate: _expiryDate,
            isValid: true
        });
        
        holderCredentials[_holder].push(credentialCounter);
        issuers[msg.sender].credentialsIssued++;
        
        emit CredentialIssued(credentialCounter, _holder, msg.sender, _skillName);
        
        return credentialCounter;
    }
    
    /**
     * @dev Verify if a credential is valid
     * @param _credentialId ID of the credential to verify
     * @return isValid Whether the credential is valid
     * @return holder Address of the credential holder
     * @return issuer Address of the issuer
     * @return skillName Name of the skill
     * @return issueDate When the credential was issued
     */
    function verifyCredential(uint256 _credentialId) 
        external 
        view 
        returns (
            bool isValid,
            address holder,
            address issuer,
            string memory skillName,
            uint256 issueDate
        )
    {
        Credential memory cred = credentials[_credentialId];
        
        bool valid = cred.isValid && 
                     (cred.expiryDate == 0 || cred.expiryDate > block.timestamp);
        
        return (
            valid,
            cred.holder,
            cred.issuer,
            cred.skillName,
            cred.issueDate
        );
    }
    
    /**
     * @dev Revoke a credential (only by issuer)
     * @param _credentialId ID of the credential to revoke
     */
    function revokeCredential(uint256 _credentialId) external {
        Credential storage cred = credentials[_credentialId];
        require(cred.issuer == msg.sender, "Only issuer can revoke");
        require(cred.isValid, "Credential already revoked");
        
        cred.isValid = false;
        
        emit CredentialRevoked(_credentialId);
    }
    
    /**
     * @dev Get all credentials for a holder
     * @param _holder Address of the holder
     * @return Array of credential IDs
     */
    function getHolderCredentials(address _holder) 
        external 
        view 
        returns (uint256[] memory) 
    {
        return holderCredentials[_holder];
    }
}

# Decentralized Skill Verification Platform (SkillVerify)

## Project Description

SkillVerify is a blockchain-based credential verification system that enables transparent, immutable, and decentralized verification of professional skills and certifications. The platform allows authorized organizations (universities, training institutes, employers) to issue verifiable credentials as NFTs, while professionals maintain complete ownership of their skill records. Employers and recruiters can instantly verify credentials without intermediaries, eliminating resume fraud and streamlining the hiring process.

## Project Vision

Our vision is to create a trustless global ecosystem where professional achievements and skills are universally verifiable, portable across borders, and permanently owned by individuals. We aim to eliminate credential fraud, reduce verification costs, and empower professionals with true ownership of their career achievements. By leveraging blockchain technology, we're building a future where "trust but verify" becomes simply "verify" – making the job market more efficient and merit-based.

## Key Features

### 1. **Issuer Authorization System**
- Admin-controlled authorization of credential-issuing organizations
- Reputation tracking through number of credentials issued
- Organization identity management on-chain

### 2. **Credential Issuance**
- Authorized issuers can mint skill credentials to professionals
- Support for expiring and non-expiring credentials
- IPFS integration for storing detailed credential metadata
- Immutable record of issuance date and issuer information

### 3. **Instant Verification**
- Public verification of any credential by ID
- Real-time validity checking (expiry and revocation status)
- Complete transparency of issuer, holder, and skill details
- No need for third-party verification services

### 4. **Credential Management**
- Issuers can revoke credentials if needed (fraud, policy violations)
- Holders can query all their credentials in one place
- Privacy-preserving design (only credential IDs are needed for verification)

### 5. **Decentralized & Trustless**
- No central authority controls credential validity
- Permanent record that survives organizational changes
- Cross-border credential portability

## Future Scope

### Phase 1: Enhanced Credential Features
- **Skill Endorsements**: Peer-to-peer endorsements with weighted reputation
- **Credential Packages**: Bundle multiple related skills into certifications
- **Achievement Levels**: Bronze/Silver/Gold tiers for skill proficiency
- **On-chain Assessments**: Integration with decentralized testing platforms

### Phase 2: Privacy & Interoperability
- **Zero-Knowledge Proofs**: Prove credential possession without revealing details
- **Selective Disclosure**: Share only specific credentials with verifiers
- **Cross-Chain Compatibility**: Bridge credentials across multiple blockchains
- **DID Integration**: Connect with Decentralized Identity standards (W3C)

### Phase 3: Ecosystem Expansion
- **Marketplace Integration**: Job boards that auto-verify credentials
- **Reputation Scoring**: AI-powered skill matching and career recommendations
- **Credential Staking**: Stake tokens on your skills to boost credibility
- **Learning Path NFTs**: Gamified learning journeys with progressive credentials

### Phase 4: Enterprise Features
- **Bulk Issuance API**: Enterprise tools for issuing credentials at scale
- **Custom Credential Templates**: Industry-specific credential standards
- **Analytics Dashboard**: Insights on skill trends and hiring patterns
- **Compliance Tools**: GDPR and regional regulation compliance features

### Phase 5: Social & Economic Layer
- **Credential Lending**: Temporary credential sharing for gig economy
- **Skill-based DAOs**: Communities organized around verified expertise
- **Micro-credentialing**: Granular skill verification for specific tasks
- **Token Incentives**: Reward holders for maintaining valid, updated credentials

---

## Technical Architecture

**Blockchain**: Ethereum / Polygon (for lower gas fees)  
**Smart Contract Language**: Solidity ^0.8.0  
**Storage**: IPFS for credential metadata  
**Frontend**: React + Web3.js / Ethers.js  
**Future Integration**: The Graph for indexing, Chainlink oracles for real-world data

---

## Getting Started

### Prerequisites
- Node.js v16+
- Hardhat or Truffle
- MetaMask wallet
- Infura/Alchemy account (for deployment)

### Installation
```bash
npm install
npx hardhat compile
npx hardhat test
npx hardhat run scripts/deploy.js --network sepolia
```

---
## Contributing

We welcome contributions! Please read our contributing guidelines and submit pull requests for any enhancements.

## License

MIT License - see LICENSE file for details

---

**Built with 🔗 by the SkillVerify Team**
contract addresses 0x25BEC4B52866CF79Ff6F1B2852adB89Bcf453B44   

