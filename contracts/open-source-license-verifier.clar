(define-constant contract-owner tx-sender)
(define-constant err-owner-only (err u100))
(define-constant err-not-found (err u101))
(define-constant err-already-exists (err u102))
(define-constant err-invalid-license (err u103))
(define-constant err-incompatible-license (err u104))
(define-constant err-unauthorized (err u105))
(define-constant err-invalid-status (err u106))
(define-constant err-already-voted (err u107))
(define-constant err-dispute-closed (err u108))
(define-constant err-insufficient-evidence (err u109))
(define-constant err-certificate-expired (err u110))
(define-constant err-insufficient-score (err u111))
(define-constant err-invalid-threshold (err u112))

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

(define-map violation-reports
  { report-id: uint }
  {
    project-id: (string-ascii 100),
    reporter: principal,
    accused-project: (string-ascii 100),
    violation-type: (string-ascii 50),
    description: (string-ascii 1000),
    evidence-url: (string-ascii 500),
    status: (string-ascii 20),
    created-at: uint,
    resolved-at: uint,
    resolution: (string-ascii 500)
  }
)

(define-map dispute-votes
  { report-id: uint, voter: principal }
  {
    vote: bool,
    weight: uint,
    voted-at: uint,
    reasoning: (string-ascii 300)
  }
)

(define-map dispute-evidence
  { report-id: uint, evidence-id: uint }
  {
    submitter: principal,
    evidence-type: (string-ascii 50),
    evidence-url: (string-ascii 500),
    description: (string-ascii 500),
    submitted-at: uint
  }
)

(define-map project-violation-history
  { project-id: (string-ascii 100) }
  {
    total-reports: uint,
    confirmed-violations: uint,
    false-reports: uint,
    reputation-score: uint,
    last-violation: uint
  }
)

(define-map compliance-certificates
  { project-id: (string-ascii 100) }
  {
    certificate-id: (string-ascii 100),
    compliance-score: uint,
    security-score: uint,
    dependency-score: uint,
    reputation-score: uint,
    overall-grade: (string-ascii 2),
    issued-at: uint,
    expires-at: uint,
    issuer: principal,
    certificate-hash: (string-ascii 64),
    valid: bool
  }
)

(define-map compliance-metrics
  { project-id: (string-ascii 100) }
  {
    license-clarity-score: uint,
    dependency-health-score: uint,
    verification-status-score: uint,
    violation-penalty-score: uint,
    community-trust-score: uint,
    last-updated: uint,
    trending-direction: (string-ascii 10)
  }
)

(define-map compliance-thresholds
  { threshold-type: (string-ascii 50) }
  {
    minimum-score: uint,
    warning-threshold: uint,
    excellent-threshold: uint,
    certificate-validity-period: uint,
    auto-renewal-enabled: bool
  }
)

(define-map compliance-audit-logs
  { project-id: (string-ascii 100), audit-id: uint }
  {
    audit-type: (string-ascii 50),
    previous-score: uint,
    new-score: uint,
    score-change: int,
    audit-reason: (string-ascii 200),
    audited-at: uint,
    audited-by: principal
  }
)

(define-data-var next-license-id uint u1)
(define-data-var next-project-id uint u1)
(define-data-var next-report-id uint u1)
(define-data-var next-certificate-id uint u1)
(define-data-var next-audit-id uint u1)
(define-data-var total-licenses uint u0)
(define-data-var total-projects uint u0)
(define-data-var total-verifications uint u0)
(define-data-var total-violation-reports uint u0)
(define-data-var total-resolved-disputes uint u0)
(define-data-var total-certificates-issued uint u0)
(define-data-var certificate-validity-blocks uint u52560)

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

(define-public (report-violation
    (accused-project (string-ascii 100))
    (violation-type (string-ascii 50))
    (description (string-ascii 1000))
    (evidence-url (string-ascii 500)))
  (let (
    (report-id (var-get next-report-id))
    (project (unwrap! (map-get? projects { project-id: accused-project }) err-not-found))
  )
    (map-set violation-reports
      { report-id: report-id }
      {
        project-id: accused-project,
        reporter: tx-sender,
        accused-project: accused-project,
        violation-type: violation-type,
        description: description,
        evidence-url: evidence-url,
        status: "pending",
        created-at: stacks-block-height,
        resolved-at: u0,
        resolution: ""
      }
    )
    (match (map-get? project-violation-history { project-id: accused-project })
      existing-history
        (map-set project-violation-history
          { project-id: accused-project }
          (merge existing-history {
            total-reports: (+ (get total-reports existing-history) u1)
          })
        )
      (map-set project-violation-history
        { project-id: accused-project }
        {
          total-reports: u1,
          confirmed-violations: u0,
          false-reports: u0,
          reputation-score: u100,
          last-violation: u0
        }
      )
    )
    (var-set next-report-id (+ report-id u1))
    (var-set total-violation-reports (+ (var-get total-violation-reports) u1))
    (ok report-id)
  )
)

(define-public (vote-on-dispute
    (report-id uint)
    (vote bool)
    (reasoning (string-ascii 300)))
  (let (
    (report (unwrap! (map-get? violation-reports { report-id: report-id }) err-not-found))
    (verifier-info (unwrap! (map-get? verifiers { verifier: tx-sender }) err-unauthorized))
    (vote-weight (get reputation verifier-info))
  )
    (asserts! (get active verifier-info) err-unauthorized)
    (asserts! (is-eq (get status report) "pending") err-dispute-closed)
    (asserts! (is-none (map-get? dispute-votes { report-id: report-id, voter: tx-sender })) err-already-voted)
    (map-set dispute-votes
      { report-id: report-id, voter: tx-sender }
      {
        vote: vote,
        weight: vote-weight,
        voted-at: stacks-block-height,
        reasoning: reasoning
      }
    )
    (ok true)
  )
)

(define-public (submit-dispute-evidence
    (report-id uint)
    (evidence-type (string-ascii 50))
    (evidence-url (string-ascii 500))
    (description (string-ascii 500)))
  (let (
    (report (unwrap! (map-get? violation-reports { report-id: report-id }) err-not-found))
    (evidence-id (+ (fold count-evidence (list u1 u2 u3 u4 u5 u6 u7 u8 u9 u10) u0) u1))
  )
    (asserts! (is-eq (get status report) "pending") err-dispute-closed)
    (asserts! (or (is-eq tx-sender (get reporter report)) 
                  (is-eq tx-sender (get owner (unwrap! (map-get? projects { project-id: (get accused-project report) }) err-not-found))))
              err-unauthorized)
    (map-set dispute-evidence
      { report-id: report-id, evidence-id: evidence-id }
      {
        submitter: tx-sender,
        evidence-type: evidence-type,
        evidence-url: evidence-url,
        description: description,
        submitted-at: stacks-block-height
      }
    )
    (ok evidence-id)
  )
)

(define-public (resolve-dispute
    (report-id uint)
    (violation-confirmed bool)
    (resolution (string-ascii 500)))
  (let (
    (report (unwrap! (map-get? violation-reports { report-id: report-id }) err-not-found))
    (vote-result (calculate-vote-result report-id))
    (project-history (default-to 
      { total-reports: u0, confirmed-violations: u0, false-reports: u0, reputation-score: u100, last-violation: u0 }
      (map-get? project-violation-history { project-id: (get accused-project report) })))
  )
    (asserts! (is-eq tx-sender contract-owner) err-owner-only)
    (asserts! (is-eq (get status report) "pending") err-dispute-closed)
    (map-set violation-reports
      { report-id: report-id }
      (merge report {
        status: (if violation-confirmed "confirmed" "dismissed"),
        resolved-at: stacks-block-height,
        resolution: resolution
      })
    )
    (map-set project-violation-history
      { project-id: (get accused-project report) }
      (merge project-history {
        confirmed-violations: (if violation-confirmed 
          (+ (get confirmed-violations project-history) u1)
          (get confirmed-violations project-history)),
        false-reports: (if violation-confirmed 
          (get false-reports project-history)
          (+ (get false-reports project-history) u1)),
        reputation-score: (if violation-confirmed
          (if (> (get reputation-score project-history) u10)
            (- (get reputation-score project-history) u10)
            u0)
          (+ (get reputation-score project-history) u5)),
        last-violation: (if violation-confirmed stacks-block-height (get last-violation project-history))
      })
    )
    (var-set total-resolved-disputes (+ (var-get total-resolved-disputes) u1))
    (ok true)
  )
)

(define-private (count-evidence (item uint) (acc uint))
  (+ acc u1)
)

(define-private (calculate-vote-result (report-id uint))
  (fold sum-votes (list u1 u2 u3 u4 u5 u6 u7 u8 u9 u10) { positive: u0, negative: u0 })
)

(define-private (sum-votes (voter-id uint) (acc { positive: uint, negative: uint }))
  acc
)

(define-public (generate-compliance-certificate 
    (project-id (string-ascii 100)))
  (let (
    (project (unwrap! (map-get? projects { project-id: project-id }) err-not-found))
    (metrics (calculate-compliance-metrics project-id))
    (certificate-id-string (uint-to-ascii (var-get next-certificate-id)))
    (validity-period (var-get certificate-validity-blocks))
    (expires-at (+ stacks-block-height validity-period))
    (overall-score (get overall-score metrics))
  )
    (asserts! (>= overall-score u70) err-insufficient-score)
    (map-set compliance-certificates
      { project-id: project-id }
      {
        certificate-id: certificate-id-string,
        compliance-score: (get compliance-score metrics),
        security-score: (get security-score metrics),
        dependency-score: (get dependency-score metrics),
        reputation-score: (get reputation-score metrics),
        overall-grade: (calculate-grade overall-score),
        issued-at: stacks-block-height,
        expires-at: expires-at,
        issuer: tx-sender,
        certificate-hash: (generate-certificate-hash project-id overall-score),
        valid: true
      }
    )
    (log-compliance-audit project-id "certificate-issued" u0 overall-score tx-sender)
    (var-set next-certificate-id (+ (var-get next-certificate-id) u1))
    (var-set total-certificates-issued (+ (var-get total-certificates-issued) u1))
    (ok certificate-id-string)
  )
)

(define-public (update-compliance-metrics 
    (project-id (string-ascii 100)))
  (let (
    (project (unwrap! (map-get? projects { project-id: project-id }) err-not-found))
    (current-metrics (get-compliance-metrics project-id))
    (new-metrics (calculate-compliance-metrics project-id))
  )
    (map-set compliance-metrics
      { project-id: project-id }
      {
        license-clarity-score: (get compliance-score new-metrics),
        dependency-health-score: (get dependency-score new-metrics),
        verification-status-score: (get security-score new-metrics),
        violation-penalty-score: (get reputation-score new-metrics),
        community-trust-score: (get overall-score new-metrics),
        last-updated: stacks-block-height,
        trending-direction: (calculate-trend-direction current-metrics new-metrics)
      }
    )
    (match (map-get? compliance-certificates { project-id: project-id })
      certificate
        (if (and (get valid certificate) 
                 (< (get overall-score new-metrics) u70))
          (begin
            (map-set compliance-certificates
              { project-id: project-id }
              (merge certificate { valid: false })
            )
            (log-compliance-audit project-id "certificate-revoked" u0 (get overall-score new-metrics) tx-sender)
            (ok false)
          )
          (ok true)
        )
      (ok true)
    )
  )
)

(define-public (set-compliance-threshold
    (threshold-type (string-ascii 50))
    (minimum-score uint)
    (warning-threshold uint)
    (excellent-threshold uint)
    (validity-period uint)
    (auto-renewal bool))
  (begin
    (asserts! (is-eq tx-sender contract-owner) err-owner-only)
    (asserts! (and (<= minimum-score warning-threshold) 
                   (<= warning-threshold excellent-threshold) 
                   (<= excellent-threshold u100)) err-invalid-threshold)
    (map-set compliance-thresholds
      { threshold-type: threshold-type }
      {
        minimum-score: minimum-score,
        warning-threshold: warning-threshold,
        excellent-threshold: excellent-threshold,
        certificate-validity-period: validity-period,
        auto-renewal-enabled: auto-renewal
      }
    )
    (ok true)
  )
)

(define-public (renew-compliance-certificate 
    (project-id (string-ascii 100)))
  (let (
    (certificate (unwrap! (map-get? compliance-certificates { project-id: project-id }) err-not-found))
    (current-metrics (calculate-compliance-metrics project-id))
    (overall-score (get overall-score current-metrics))
  )
    (asserts! (>= overall-score u70) err-insufficient-score)
    (asserts! (get valid certificate) err-certificate-expired)
    (map-set compliance-certificates
      { project-id: project-id }
      (merge certificate {
        compliance-score: (get compliance-score current-metrics),
        security-score: (get security-score current-metrics),
        dependency-score: (get dependency-score current-metrics),
        reputation-score: (get reputation-score current-metrics),
        overall-grade: (calculate-grade overall-score),
        issued-at: stacks-block-height,
        expires-at: (+ stacks-block-height (var-get certificate-validity-blocks)),
        certificate-hash: (generate-certificate-hash project-id overall-score)
      })
    )
    (log-compliance-audit project-id "certificate-renewed" u0 overall-score tx-sender)
    (ok true)
  )
)

(define-private (calculate-compliance-metrics (project-id (string-ascii 100)))
  (let (
    (project (unwrap! (map-get? projects { project-id: project-id }) 
             { compliance-score: u0, security-score: u0, dependency-score: u0, 
               reputation-score: u0, overall-score: u0 }))
    (verification-score (if (get verified project) u100 u50))
    (reputation-info (default-to 
      { reputation-score: u100, confirmed-violations: u0, total-reports: u0 }
      (map-get? project-violation-history { project-id: project-id })))
    (license-score u85)
    (dependency-score (calculate-dependency-health project-id))
    (reputation-score (get reputation-score reputation-info))
  )
    {
      compliance-score: (/ (+ license-score verification-score reputation-score) u3),
      security-score: (calculate-security-score project-id),
      dependency-score: dependency-score,
      reputation-score: reputation-score,
      overall-score: (/ (+ license-score verification-score dependency-score reputation-score) u4)
    }
  )
)

(define-private (calculate-dependency-health (project-id (string-ascii 100)))
  (let (
    (dependency-count (fold count-dependencies (list u1 u2 u3 u4 u5 u6 u7 u8 u9 u10) u0))
    (compatible-count (fold count-compatible-dependencies (list u1 u2 u3 u4 u5 u6 u7 u8 u9 u10) u0))
  )
    (if (is-eq dependency-count u0)
      u100
      (/ (* compatible-count u100) dependency-count)
    )
  )
)

(define-private (calculate-security-score (project-id (string-ascii 100)))
  (match (map-get? projects { project-id: project-id })
    project
      (let (
        (age-score (if (> (- stacks-block-height (get created-at project)) u1000) u90 u70))
        (verification-score (if (get verified project) u100 u60))
      )
        (/ (+ age-score verification-score) u2)
      )
    u50
  )
)

(define-private (calculate-grade (score uint))
  (if (>= score u90) "A"
    (if (>= score u80) "B"
      (if (>= score u70) "C"
        (if (>= score u60) "D"
          "F"
        )
      )
    )
  )
)

(define-private (calculate-trend-direction 
    (old-metrics (optional { license-clarity-score: uint, dependency-health-score: uint, 
                           verification-status-score: uint, violation-penalty-score: uint, 
                           community-trust-score: uint, last-updated: uint, 
                           trending-direction: (string-ascii 10) }))
    (new-metrics { compliance-score: uint, security-score: uint, dependency-score: uint, 
                  reputation-score: uint, overall-score: uint }))
  (match old-metrics
    old-data "stable"
    "up"
  )
)

(define-private (generate-certificate-hash (project-id (string-ascii 100)) (score uint))
  (uint-to-ascii score)
)

(define-private (log-compliance-audit 
    (project-id (string-ascii 100))
    (audit-type (string-ascii 50))
    (previous-score uint)
    (new-score uint)
    (auditor principal))
  (let (
    (audit-id (var-get next-audit-id))
  )
    (map-set compliance-audit-logs
      { project-id: project-id, audit-id: audit-id }
      {
        audit-type: audit-type,
        previous-score: previous-score,
        new-score: new-score,
        score-change: (- (to-int new-score) (to-int previous-score)),
        audit-reason: audit-type,
        audited-at: stacks-block-height,
        audited-by: auditor
      }
    )
    (var-set next-audit-id (+ audit-id u1))
    true
  )
)

(define-private (count-dependencies (item uint) (acc uint))
  (+ acc u1)
)

(define-private (count-compatible-dependencies (item uint) (acc uint))
  (+ acc u1)
)

(define-private (uint-to-ascii (value uint))
  (if (is-eq value u0) "0"
    (if (is-eq value u1) "1"
      (if (is-eq value u2) "2"
        (if (is-eq value u3) "3"
          (if (is-eq value u4) "4"
            (if (is-eq value u5) "5"
              (if (is-eq value u6) "6"
                (if (is-eq value u7) "7"
                  (if (is-eq value u8) "8"
                    (if (is-eq value u9) "9"
                      "N"
                    )
                  )
                )
              )
            )
          )
        )
      )
    )
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

(define-read-only (get-violation-report (report-id uint))
  (map-get? violation-reports { report-id: report-id })
)

(define-read-only (get-dispute-vote (report-id uint) (voter principal))
  (map-get? dispute-votes { report-id: report-id, voter: voter })
)

(define-read-only (get-dispute-evidence (report-id uint) (evidence-id uint))
  (map-get? dispute-evidence { report-id: report-id, evidence-id: evidence-id })
)

(define-read-only (get-project-violation-history (project-id (string-ascii 100)))
  (map-get? project-violation-history { project-id: project-id })
)

(define-read-only (get-project-reputation-score (project-id (string-ascii 100)))
  (match (map-get? project-violation-history { project-id: project-id })
    history (get reputation-score history)
    u100
  )
)

(define-read-only (is-project-under-dispute (project-id (string-ascii 100)))
  (match (map-get? project-violation-history { project-id: project-id })
    history (> (get total-reports history) (+ (get confirmed-violations history) (get false-reports history)))
    false
  )
)

(define-read-only (get-compliance-certificate (project-id (string-ascii 100)))
  (map-get? compliance-certificates { project-id: project-id })
)

(define-read-only (get-compliance-metrics (project-id (string-ascii 100)))
  (map-get? compliance-metrics { project-id: project-id })
)

(define-read-only (get-compliance-threshold (threshold-type (string-ascii 50)))
  (map-get? compliance-thresholds { threshold-type: threshold-type })
)

(define-read-only (get-compliance-audit-log (project-id (string-ascii 100)) (audit-id uint))
  (map-get? compliance-audit-logs { project-id: project-id, audit-id: audit-id })
)

(define-read-only (is-certificate-valid (project-id (string-ascii 100)))
  (match (map-get? compliance-certificates { project-id: project-id })
    certificate (and (get valid certificate) (< stacks-block-height (get expires-at certificate)))
    false
  )
)

(define-read-only (get-project-compliance-score (project-id (string-ascii 100)))
  (let (
    (metrics (calculate-compliance-metrics project-id))
  )
    (get overall-score metrics)
  )
)

(define-read-only (get-projects-by-compliance-grade (grade (string-ascii 2)))
  (list 
    { project-id: "sample-project-a", score: u95, grade: "A" }
    { project-id: "sample-project-b", score: u82, grade: "B" }
  )
)

(define-read-only (get-compliance-summary (project-id (string-ascii 100)))
  (let (
    (certificate (map-get? compliance-certificates { project-id: project-id }))
    (metrics (calculate-compliance-metrics project-id))
  )
    {
      project-id: project-id,
      current-score: (get overall-score metrics),
      grade: (calculate-grade (get overall-score metrics)),
      has-certificate: (is-some certificate),
      certificate-valid: (is-certificate-valid project-id),
      last-updated: stacks-block-height
    }
  )
)

(define-read-only (get-contract-stats)
  {
    total-licenses: (var-get total-licenses),
    total-projects: (var-get total-projects),
    total-verifications: (var-get total-verifications),
    total-violation-reports: (var-get total-violation-reports),
    total-resolved-disputes: (var-get total-resolved-disputes),
    total-certificates-issued: (var-get total-certificates-issued),
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
