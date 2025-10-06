-- Seed de base : rôles principaux

insert into roles (code, description) values
  ('admin', 'Administrateur établissement'),
  ('manager', 'Manager établissement'),
  ('staff', 'Employé opérationnel'),
  ('guest', 'Voyageur invité')
on conflict (code) do nothing;
