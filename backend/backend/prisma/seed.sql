CREATE TABLE IF NOT EXISTS role_change_audits (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  target_user_id UUID NOT NULL REFERENCES users(id),
  admin_user_id UUID NOT NULL REFERENCES users(id),
  old_role VARCHAR(20) NOT NULL,
  new_role VARCHAR(20) NOT NULL,
  changed_at TIMESTAMP DEFAULT now()
);
