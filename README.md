# Daleks -  Decentralized File Storage with Centralized Users

This project is about splitting users and files into separate services. 

Users live in one place, with OAuth authentication, and decide which files server to use based on region.  
Files services may run in multiple regions like DE, FR, US and connect to local or cloud storage. 
For this case I will add Minio in the as S3 server.

You can add new regions easily just by adding credentials and deploying the files service there — no code changes.

## Main flows

### User Login (Authentication)
- The user sends login credentials to the **Users Service**.
- Users Service verifies credentials and generates an OAuth token (access + refresh).
- Client stores the token for future requests.

---

### Accessing Files (Authorization + File Handling)
- Client sends file requests (upload/download) to **API Gateway** or directly to **Files Service**.
- Files Service validates the OAuth token (usually a JWT) with the Users Service or locally.
- If token is valid, Files Service processes the request and connects to regional storage (S3 or local).
- Files Service only allows access based on the user’s permissions encoded in the token.

---

### Token Refresh
- When the access token expires, the client uses the refresh token to get a new access token from Users Service.
- This happens independently of file fetch or login.

---

This way, login and file fetching are separate, but both rely on token-based security.

As I mentioned, the token can be validated locally, which might be confusing — but I’m referring to a server-to-server 
trust mechanism that you can choose to use. The Users service owns the private key, and the Files service holds the 
corresponding public key, allowing it to validate the token. This is a simple and fast way to handle authorization. 
However, such tokens cannot be revoked or tracked, so they are typically short-lived.

## Simple Diagram
```yaml
                      [ Central Users DB ]
                                |
                     +----------+-----------+
                     |                      |
              [Users Service]      (decides which region to use)
                     |
                     v
      [API Gateway] or client app
                     |
         +-----------+------------+-------------+
         |           |            |             |
      [Files-DE]  [Files-FR]   [Files-PL]   [Files-IT]
         |           |            |             |
      [S3-DE]     [S3-FR]      [Local]       [S3-IT]

```

## Upload & Download Features

### Upload
- Users can upload files as **full files** or in **chunks** (useful for large files).
- On upload, they can set the file as `private`, `shared` (multiple file owner), or `public`.
- Files don’t directly know about users — they just store **user IDs** (global IDs from Users Service) for ownership and access control.
- Metadata like `owners`, `size`, `region`, and `visibility` are stored with the file.

### Download
- **Private** files: only owners (via user verification) can access.
- **Shared** files: multiple user IDs can be listed, users can have different permissions to files or to folders.
- **Public** files: anyone can view/download without a token.
- Users can also generate **temporary URLs** (signed links) that allow non-owners to view/download files for a short time.


### Access
If you own a file or an entire folder, you automatically have full permissions on it.
There are typically four types of permissions:
- read: view or download
- write: add a new file
- delete: remove the file or folder
- update: add new files to a folder or replace existing ones
You can assign another user as a co-owner, granting them the same or selective permissions based on your choice.

Public and temporary URLs are always read-only, regardless of permissions or ownership.

---

Access control is enforced in the **Files Service** using user IDs and token validation — no need to talk directly to Users Service unless needed (e.g. verifying token or refreshing user data).

### Project Structure
```yaml
root/
│
├── docker/
│   ├── users/
│   │   └── Dockerfile
│   ├── files/
│   │   └── Dockerfile
│   └── compose/
│       ├── users.yml              # Compose config for Users Service
│       └── files.yml              # Will have different variables on git for different regions, will choose&copy them while deploy
│
├── envs/
│   ├── users.env
│   └── files.env
│
├── deploy/
│   ├── deploy.sh                  # Deployment helper script
│   ├── key-rotate.sh              # Generates a new key every day for jwk
│   └── generate-env.sh            # Env scaffolding
│
├── services/
│   ├── users/
│   │   ├── cmd/
│   │   │   └── server/main.go
│   │   ├── go.mod
│   │   ├── go.sum
│   │   ├── internal/
│   │   │   ├── handler/           # login, register, token refresh, region routing
│   │   │   ├── contracts/         # IUser, IRegion, etc.
│   │   │   ├── service/           # OAuth core logic, region resolver
│   │   │   ├── repository/        # DB access for users, regions
│   │   │   ├── model/             # request, response, DB structs
│   │   │   ├── oauth/             # token generation, signer, JWKS server
│   │   │   └── config/            # Config loader
│   │   ├── keystore/
│   │   │   ├── private/
│   │   │   │   ├── 2025-08-05.pem     # current key
│   │   │   │   └── 2025-08-04.pem     # old key (still valid)
│   │   │   └── public/
│   │   │       ├── 2025-08-05.pem.pub
│   │   │       └── 2025-08-04.pem.pub
│   │   └── migrations/
│   │       └── *.sql              # Users DB schema
│   │
│   └── files/
│       ├── cmd/server/main.go
│       ├── go.mod
│       ├── go.sum
│       ├── internal/
│       │   ├── handler/           # upload, download, share, generate temp URL
│       │   ├── service/           # file visibility, chunk handling
│       │   ├── storage/           # S3/Minio/local storage adapter
│       │   ├── auth/
│       │   │   ├── validator.go   # token validator (uses JWKS)
│       │   │   ├── jwks.go        # JWKS fetcher/cache
│       │   │   └── permissions.go # access control logic
│       │   ├── metadata/          # metadata in DB or S3 tags
│       │   ├── model/             # file info, upload chunks, etc.
│       │   ├── config/            # reads env vars: region, storage creds
│       │   └── utils/             # file type, presigned URLs, hashing
│       └── migrations/
│           └── *.sql              # Files DB schema
│
├── libs/
│   ├── auth/
│   │   ├── jwt.go                 # shared claims/validation logic
│   │   ├── keys.go                # parse/load PEM/JWK keys
│   │   └── tokens.go              # sign, verify, parse helpers
│   ├── jwksutil/                  # shared between users and files
│   │   ├── builder.go             # builds JWKS from keys
│   │   ├── loader.go              # fetches + parses JWKS
│   │   └── signer.go              # rotates + loads current private key
│   ├── logger/                    # zap/logrus wrapper
│   ├── config/                    # generic config parser
│   ├── httpclient/                # shared internal HTTP requester
│   └── envloader/                 # loads .env into structs
│
├── cmd/
│   └── cli/
│       └── main.go                # admin CLI: test users/files/token validity
│
├── docs/
│   ├── README.md
│   ├── ARCHITECTURE.md
│   ├── REGION-SETUP.md
│   └── TRUSTED-AUTH.md            # explains JWKS, key rotation, token flows
│
├── .gitignore
└── go.work                        # (optional) Go workspaces
```
