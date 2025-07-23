(define-constant contract-owner tx-sender)
(define-constant err-owner-only (err u100))
(define-constant err-not-found (err u101))
(define-constant err-already-exists (err u102))
(define-constant err-invalid-license (err u103))
(define-constant err-incompatible-license (err u104))
(define-constant err-unauthorized (err u105))

(define-map licenses
  { license-id: (string-ascii 50) }
  {
    name: (string-ascii 100),
    description: (string-ascii 500),
    copyleft: bool,
    commercial-use: bool,
    modification: bool,
    distribution: bool,
    patent-use: bool,
    private-use: bool,
    disclose-source: bool,
    same-license: bool,
    creator: principal,
    created-at: uint
  }
)

(define-map projects
  { project-id: (string-ascii 100) }
  {
    name: (string-ascii 200),
    description: (string-ascii 1000),
    license-id: (string-ascii 50),
    owner: principal,
    verified: bool,
    verification-date: uint,
    verifier: (optional principal),
    repository-url: (string-ascii 500),
    created-at: uint
  }
)

(define-map project-dependencies
  { project-id: (string-ascii 100), dependency-id: (string-ascii 100) }
  {
    dependency-license: (string-ascii 50),
    compatible: bool,
    verified-by: principal,
    verified-at: uint
  }
)

(define-map license-compatibility
  { license-a: (string-ascii 50), license-b: (string-ascii 50) }
  {
    compatible: bool,
    reason: (string-ascii 500),
    added-by: principal,
    added-at: uint
  }
)

(define-map verifiers
  { verifier: principal }
  {
    name: (string-ascii 100),
    reputation: uint,
    verifications-count: uint,
    approved-by: principal,
    approved-at: uint,
    active: bool
  }
)

(define-data-var next-license-id uint u1)
(define-data-var next-project-id uint u1)
(define-data-var total-licenses uint u0)
(define-data-var total-projects uint u0)
(define-data-var total-verifications uint u0)

(define-public (add-license 
    (license-id (string-ascii 50))
    (name (string-ascii 100))
    (description (string-ascii 500))
    (copyleft bool)
    (commercial-use bool)
    (modification bool)
    (distribution bool)
    (patent-use bool)
    (private-use bool)
    (disclose-source bool)
    (same-license bool))
  (begin
    (asserts! (is-eq tx-sender contract-owner) err-owner-only)
    (asserts! (is-none (map-get? licenses { license-id: license-id })) err-already-exists)
    (map-set licenses
      { license-id: license-id }
      {
        name: name,
        description: description,
        copyleft: copyleft,
        commercial-use: commercial-use,
        modification: modification,
        distribution: distribution,
        patent-use: patent-use,
        private-use: private-use,
        disclose-source: disclose-source,
        same-license: same-license,
        creator: tx-sender,
        created-at: stacks-block-height
      }
    )
    (var-set total-licenses (+ (var-get total-licenses) u1))
    (ok true)
  )
)

(define-public (register-project
    (project-id (string-ascii 100))
    (name (string-ascii 200))
    (description (string-ascii 1000))
    (license-id (string-ascii 50))
    (repository-url (string-ascii 500)))
  (begin
    (asserts! (is-some (map-get? licenses { license-id: license-id })) err-invalid-license)
    (asserts! (is-none (map-get? projects { project-id: project-id })) err-already-exists)
    (map-set projects
      { project-id: project-id }
      {
        name: name,
        description: description,
        license-id: license-id,
        owner: tx-sender,
        verified: false,
        verification-date: u0,
        verifier: none,
        repository-url: repository-url,
        created-at: stacks-block-height
      }
    )
    (var-set total-projects (+ (var-get total-projects) u1))
    (ok true)
  )
)

(define-public (add-verifier
    (verifier principal)
    (name (string-ascii 100)))
  (begin
    (asserts! (is-eq tx-sender contract-owner) err-owner-only)
    (asserts! (is-none (map-get? verifiers { verifier: verifier })) err-already-exists)
    (map-set verifiers
      { verifier: verifier }
      {
        name: name,
        reputation: u100,
        verifications-count: u0,
        approved-by: tx-sender,
        approved-at: stacks-block-height,
        active: true
      }
    )
    (ok true)
  )
)

(define-public (verify-project
    (project-id (string-ascii 100))
    (compliant bool))
  (let (
    (project (unwrap! (map-get? projects { project-id: project-id }) err-not-found))
    (verifier-info (unwrap! (map-get? verifiers { verifier: tx-sender }) err-unauthorized))
  )
    (asserts! (get active verifier-info) err-unauthorized)
    (map-set projects
      { project-id: project-id }
      (merge project {
        verified: compliant,
        verification-date: stacks-block-height,
        verifier: (some tx-sender)
      })
    )
    (map-set verifiers
      { verifier: tx-sender }
      (merge verifier-info {
        verifications-count: (+ (get verifications-count verifier-info) u1),
        reputation: (if compliant 
          (+ (get reputation verifier-info) u1)
          (if (> (get reputation verifier-info) u0)
            (- (get reputation verifier-info) u1)
            u0))
      })
    )
    (var-set total-verifications (+ (var-get total-verifications) u1))
    (ok true)
  )
)

(define-public (add-dependency
    (project-id (string-ascii 100))
    (dependency-id (string-ascii 100)))
  (let (
    (project (unwrap! (map-get? projects { project-id: project-id }) err-not-found))
    (dependency (unwrap! (map-get? projects { project-id: dependency-id }) err-not-found))
    (project-license (get license-id project))
    (dependency-license (get license-id dependency))
    (compatibility (get-license-compatibility project-license dependency-license))
  )
    (asserts! (is-eq tx-sender (get owner project)) err-unauthorized)
    (map-set project-dependencies
      { project-id: project-id, dependency-id: dependency-id }
      {
        dependency-license: dependency-license,
        compatible: compatibility,
        verified-by: tx-sender,
        verified-at: stacks-block-height
      }
    )
    (ok compatibility)
  )
)

(define-public (set-license-compatibility
    (license-a (string-ascii 50))
    (license-b (string-ascii 50))
    (compatible bool)
    (reason (string-ascii 500)))
  (begin
    (asserts! (is-eq tx-sender contract-owner) err-owner-only)
    (asserts! (is-some (map-get? licenses { license-id: license-a })) err-invalid-license)
    (asserts! (is-some (map-get? licenses { license-id: license-b })) err-invalid-license)
    (map-set license-compatibility
      { license-a: license-a, license-b: license-b }
      {
        compatible: compatible,
        reason: reason,
        added-by: tx-sender,
        added-at: stacks-block-height
      }
    )
    (map-set license-compatibility
      { license-a: license-b, license-b: license-a }
      {
        compatible: compatible,
        reason: reason,
        added-by: tx-sender,
        added-at: stacks-block-height
      }
    )
    (ok true)
  )
)

(define-read-only (get-license (license-id (string-ascii 50)))
  (map-get? licenses { license-id: license-id })
)

(define-read-only (get-project (project-id (string-ascii 100)))
  (map-get? projects { project-id: project-id })
)

(define-read-only (get-verifier (verifier principal))
  (map-get? verifiers { verifier: verifier })
)

(define-read-only (get-project-dependency 
    (project-id (string-ascii 100))
    (dependency-id (string-ascii 100)))
  (map-get? project-dependencies { project-id: project-id, dependency-id: dependency-id })
)

(define-read-only (get-license-compatibility-info
    (license-a (string-ascii 50))
    (license-b (string-ascii 50)))
  (map-get? license-compatibility { license-a: license-a, license-b: license-b })
)

(define-read-only (get-license-compatibility
    (license-a (string-ascii 50))
    (license-b (string-ascii 50)))
  (match (map-get? license-compatibility { license-a: license-a, license-b: license-b })
    compat-info (get compatible compat-info)
    (check-license-compatibility-rules license-a license-b)
  )
)

(define-read-only (check-license-compatibility-rules
    (license-a (string-ascii 50))
    (license-b (string-ascii 50)))
  (let (
    (license-a-info (unwrap! (map-get? licenses { license-id: license-a }) false))
    (license-b-info (unwrap! (map-get? licenses { license-id: license-b }) false))
  )
    (if (is-eq license-a license-b)
      true
      (and
        (or (not (get copyleft license-a-info)) (get copyleft license-b-info))
        (or (not (get disclose-source license-a-info)) (get disclose-source license-b-info))
        (or (not (get same-license license-a-info)) (is-eq license-a license-b))
      )
    )
  )
)

(define-read-only (is-project-compliant (project-id (string-ascii 100)))
  (match (map-get? projects { project-id: project-id })
    project-info (get verified project-info)
    false
  )
)

(define-read-only (get-contract-stats)
  {
    total-licenses: (var-get total-licenses),
    total-projects: (var-get total-projects),
    total-verifications: (var-get total-verifications),
    contract-owner: contract-owner
  }
)

(define-read-only (get-project-license-info (project-id (string-ascii 100)))
  (match (map-get? projects { project-id: project-id })
    project-info
      (match (map-get? licenses { license-id: (get license-id project-info) })
        license-info
          (some {
            project: project-info,
            license: license-info
          })
        none
      )
    none
  )
)
