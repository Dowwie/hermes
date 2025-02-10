WITH sender AS (
  INSERT INTO parties (email, phone_e164, inserted_at, updated_at)
  VALUES ($1, $2, now(), now())
  ON CONFLICT (phone_e164) DO UPDATE SET updated_at = now()
  RETURNING id
),
recipient AS (
  INSERT INTO parties (email, phone_e164, inserted_at, updated_at)
  VALUES ($3, $4, now(), now())
  ON CONFLICT (phone_e164) DO UPDATE SET updated_at = now()
  RETURNING id
),
ordered_parties AS (
  SELECT 
    CASE WHEN s.id < r.id THEN s.id ELSE r.id END AS party_a_id,
    CASE WHEN s.id < r.id THEN r.id ELSE s.id END AS party_b_id
  FROM sender s, recipient r
),
conversation AS (
  INSERT INTO conversations (party_a_id, party_b_id, inserted_at, updated_at)
  SELECT party_a_id, party_b_id, now(), now()
  FROM ordered_parties
  ON CONFLICT (party_a_id, party_b_id) DO UPDATE SET updated_at = now()
  RETURNING id
)
INSERT INTO messages (body, sent_at, conversation_id, channel_id, sender_id, recipient_id, inserted_at, updated_at)
VALUES ($5, $6, (SELECT id FROM conversation), $7, (SELECT id FROM sender), (SELECT id FROM recipient), now(), now())
RETURNING id, body, sent_at;

/*
Trade-Offs and Considerations

    Validation and Changesets:
    When you use raw SQL, you’re bypassing some of Ecto’s changeset validations. Ensure that any necessary validations are either performed earlier in your application or incorporated into the SQL logic or database constraints.

    Error Handling:
    With a single roundtrip, error handling might be a bit more complex, as a failure in any sub-operation will cause the whole statement to fail. Make sure you handle and log errors appropriately.

    Complexity:
    Combining multiple steps into one SQL statement can make your queries more complex and harder to maintain. Weigh the performance benefits against maintainability for your application.
*/
