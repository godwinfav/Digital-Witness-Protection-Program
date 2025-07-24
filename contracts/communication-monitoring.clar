;; Digital Witness Protection Program - Communication Monitoring Contract
;; Secures contact with law enforcement handlers and manages encrypted communications

;; Constants
(define-constant CONTRACT-OWNER tx-sender)
(define-constant ERR-NOT-AUTHORIZED (err u300))
(define-constant ERR-COMMUNICATION-NOT-FOUND (err u301))
(define-constant ERR-INVALID-INPUT (err u302))
(define-constant ERR-CHANNEL-COMPROMISED (err u303))
(define-constant ERR-WITNESS-NOT-FOUND (err u304))

;; Data Variables
(define-data-var communication-counter uint u0)
(define-data-var channel-counter uint u0)

;; Data Maps
(define-map communication-channels
  { channel-id: uint }
  {
    witness-id: uint,
    handler-principal: principal,
    channel-type: (string-ascii 20),
    encryption-key-hash: (buff 32),
    created-at: uint,
    expires-at: uint,
    status: (string-ascii 20),
    security-level: uint
  }
)

(define-map communication-logs
  { communication-id: uint }
  {
    channel-id: uint,
    sender: principal,
    recipient: principal,
    message-hash: (buff 32),
    timestamp: uint,
    communication-type: (string-ascii 20),
    priority-level: uint,
    verified: bool
  }
)

(define-map emergency-contacts
  { witness-id: uint }
  {
    primary-handler: principal,
    backup-handler: principal,
    emergency-protocol: (string-ascii 50),
    last-contact: uint,
    contact-frequency: uint
  }
)

(define-map handler-permissions
  { handler: principal }
  {
    authorized: bool,
    clearance-level: uint,
    can-create-channels: bool,
    can-monitor: bool
  }
)

(define-map channel-security
  { channel-id: uint }
  {
    compromise-attempts: uint,
    last-security-check: uint,
    security-incidents: uint,
    monitoring-enabled: bool
  }
)

;; Authorization Functions
(define-private (is-authorized-handler (handler principal))
  (default-to false (get authorized (map-get? handler-permissions { handler: handler })))
)

(define-private (can-create-channels (handler principal))
  (default-to false (get can-create-channels (map-get? handler-permissions { handler: handler })))
)

(define-private (can-monitor (handler principal))
  (default-to false (get can-monitor (map-get? handler-permissions { handler: handler })))
)

(define-private (get-handler-clearance (handler principal))
  (default-to u0 (get clearance-level (map-get? handler-permissions { handler: handler })))
)

;; Public Functions

;; Add authorized handler
(define-public (add-authorized-handler
  (handler principal)
  (clearance-level uint)
  (can-create bool)
  (can-monitor-comms bool)
)
  (begin
    (asserts! (is-eq tx-sender CONTRACT-OWNER) ERR-NOT-AUTHORIZED)
    (asserts! (< clearance-level u6) ERR-INVALID-INPUT)
    (ok (map-set handler-permissions
      { handler: handler }
      {
        authorized: true,
        clearance-level: clearance-level,
        can-create-channels: can-create,
        can-monitor: can-monitor-comms
      }
    ))
  )
)

;; Create secure communication channel
(define-public (create-communication-channel
  (witness-id uint)
  (channel-type (string-ascii 20))
  (encryption-key-hash (buff 32))
  (duration-blocks uint)
  (security-level uint)
)
  (let
    (
      (channel-id (+ (var-get channel-counter) u1))
      (expiry-block (+ block-height duration-blocks))
    )
    (asserts! (is-authorized-handler tx-sender) ERR-NOT-AUTHORIZED)
    (asserts! (can-create-channels tx-sender) ERR-NOT-AUTHORIZED)
    (asserts! (>= (get-handler-clearance tx-sender) security-level) ERR-NOT-AUTHORIZED)
    (asserts! (< security-level u6) ERR-INVALID-INPUT)
    (asserts! (> duration-blocks u0) ERR-INVALID-INPUT)

    (map-set communication-channels
      { channel-id: channel-id }
      {
        witness-id: witness-id,
        handler-principal: tx-sender,
        channel-type: channel-type,
        encryption-key-hash: encryption-key-hash,
        created-at: block-height,
        expires-at: expiry-block,
        status: "active",
        security-level: security-level
      }
    )

    (map-set channel-security
      { channel-id: channel-id }
      {
        compromise-attempts: u0,
        last-security-check: block-height,
        security-incidents: u0,
        monitoring-enabled: true
      }
    )

    (var-set channel-counter channel-id)
    (ok channel-id)
  )
)

;; Log communication
(define-public (log-communication
  (channel-id uint)
  (recipient principal)
  (message-hash (buff 32))
  (communication-type (string-ascii 20))
  (priority-level uint)
)
  (let
    (
      (communication-id (+ (var-get communication-counter) u1))
      (channel-data (unwrap! (map-get? communication-channels { channel-id: channel-id }) ERR-COMMUNICATION-NOT-FOUND))
    )
    (asserts! (is-authorized-handler tx-sender) ERR-NOT-AUTHORIZED)
    (asserts! (< block-height (get expires-at channel-data)) ERR-COMMUNICATION-NOT-FOUND)
    (asserts! (is-eq (get status channel-data) "active") ERR-CHANNEL-COMPROMISED)
    (asserts! (< priority-level u6) ERR-INVALID-INPUT)

    (map-set communication-logs
      { communication-id: communication-id }
      {
        channel-id: channel-id,
        sender: tx-sender,
        recipient: recipient,
        message-hash: message-hash,
        timestamp: block-height,
        communication-type: communication-type,
        priority-level: priority-level,
        verified: true
      }
    )

    (var-set communication-counter communication-id)
    (ok communication-id)
  )
)

;; Set emergency contact
(define-public (set-emergency-contact
  (witness-id uint)
  (primary-handler principal)
  (backup-handler principal)
  (emergency-protocol (string-ascii 50))
  (contact-frequency uint)
)
  (begin
    (asserts! (is-authorized-handler tx-sender) ERR-NOT-AUTHORIZED)
    (asserts! (> contact-frequency u0) ERR-INVALID-INPUT)

    (ok (map-set emergency-contacts
      { witness-id: witness-id }
      {
        primary-handler: primary-handler,
        backup-handler: backup-handler,
        emergency-protocol: emergency-protocol,
        last-contact: block-height,
        contact-frequency: contact-frequency
      }
    ))
  )
)

;; Report security incident
(define-public (report-security-incident (channel-id uint) (incident-type (string-ascii 50)))
  (let
    (
      (channel-data (unwrap! (map-get? communication-channels { channel-id: channel-id }) ERR-COMMUNICATION-NOT-FOUND))
      (security-data (unwrap! (map-get? channel-security { channel-id: channel-id }) ERR-COMMUNICATION-NOT-FOUND))
    )
    (asserts! (is-authorized-handler tx-sender) ERR-NOT-AUTHORIZED)
    (asserts! (can-monitor tx-sender) ERR-NOT-AUTHORIZED)
    (asserts! (>= (get-handler-clearance tx-sender) (get security-level channel-data)) ERR-NOT-AUTHORIZED)

    (map-set channel-security
      { channel-id: channel-id }
      (merge security-data
        {
          security-incidents: (+ (get security-incidents security-data) u1),
          last-security-check: block-height
        }
      )
    )

    ;; If too many incidents, compromise the channel
    (if (> (get security-incidents security-data) u2)
      (map-set communication-channels
        { channel-id: channel-id }
        (merge channel-data { status: "compromised" })
      )
      true
    )

    (ok true)
  )
)

;; Update channel status
(define-public (update-channel-status (channel-id uint) (new-status (string-ascii 20)))
  (let
    (
      (channel-data (unwrap! (map-get? communication-channels { channel-id: channel-id }) ERR-COMMUNICATION-NOT-FOUND))
    )
    (asserts! (is-authorized-handler tx-sender) ERR-NOT-AUTHORIZED)
    (asserts! (>= (get-handler-clearance tx-sender) (get security-level channel-data)) ERR-NOT-AUTHORIZED)

    (ok (map-set communication-channels
      { channel-id: channel-id }
      (merge channel-data { status: new-status })
    ))
  )
)

;; Read-only Functions

;; Get communication channel details
(define-read-only (get-communication-channel (channel-id uint))
  (map-get? communication-channels { channel-id: channel-id })
)

;; Get communication log
(define-read-only (get-communication-log (communication-id uint))
  (map-get? communication-logs { communication-id: communication-id })
)

;; Get emergency contacts
(define-read-only (get-emergency-contacts (witness-id uint))
  (map-get? emergency-contacts { witness-id: witness-id })
)

;; Check channel security status
(define-read-only (get-channel-security (channel-id uint))
  (map-get? channel-security { channel-id: channel-id })
)

;; Check if channel is secure
(define-read-only (is-channel-secure (channel-id uint))
  (match (map-get? communication-channels { channel-id: channel-id })
    channel-data (and
      (< block-height (get expires-at channel-data))
      (is-eq (get status channel-data) "active")
    )
    false
  )
)
